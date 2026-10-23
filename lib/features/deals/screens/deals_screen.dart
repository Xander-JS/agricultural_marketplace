import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import '../widgets/deal_crop_thumb.dart';
import '../widgets/negotiation_status_badge.dart';
import 'deal_detail_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/inputs/app_segmented_control.dart';
import '../../../core/widgets/loading/section_skeletons.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../../../core/widgets/misc/staggered_entrance.dart';

/// Sections of the deals list, from everything to what is already closed.
enum _DealsFilter { all, inProgress, agreed, history }

class DealsScreen extends StatefulWidget {
  final String? role;
  final List<NegotiationModel>? initialNegotiations;
  final NegotiationService? service;

  /// Action of the empty state (explore the market or the user's own
  /// harvests). Falls back to popping the route when not given.
  final VoidCallback? onEmptyAction;

  const DealsScreen({
    super.key,
    this.role,
    this.initialNegotiations,
    this.service,
    this.onEmptyAction,
  });

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  late final NegotiationService _service;
  bool _isLoading = true;
  String? _errorMessage;
  List<NegotiationModel> _negotiations = [];
  String? _userRole;
  _DealsFilter _filter = _DealsFilter.all;
  bool _entrancePlayed = false;

  bool get _isBuyer => UserRole.isBuyerRole(widget.role ?? _userRole);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NegotiationService();

    if (widget.initialNegotiations != null) {
      _negotiations = widget.initialNegotiations!;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialNegotiations != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Si el rol no fue inyectado, consultarlo en profiles
      if (widget.role == null) {
        try {
          final profileRes = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          if (profileRes != null && profileRes['role'] != null) {
            _userRole = profileRes['role'] as String;
          }
        } catch (_) {}
      }

      List<NegotiationModel> negotiations;
      if (_isBuyer) {
        negotiations = await _service.getBuyerNegotiations(user.id);
      } else {
        negotiations = await _service.getFarmerNegotiations(user.id);
      }

      if (mounted) {
        setState(() {
          _negotiations = negotiations;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isActive(NegotiationModel n) =>
      n.status == NegotiationStatus.propuesta ||
      n.status == NegotiationStatus.contraofertada;

  bool _isMyTurn(NegotiationModel n) =>
      _isActive(n) && n.isMyTurn(isBuyer: _isBuyer);

  bool _matches(NegotiationModel n, _DealsFilter filter) {
    return switch (filter) {
      _DealsFilter.all => true,
      _DealsFilter.inProgress => _isActive(n),
      _DealsFilter.agreed => n.status == NegotiationStatus.acordada,
      _DealsFilter.history =>
        n.status == NegotiationStatus.completada ||
            n.status == NegotiationStatus.rechazada ||
            n.status == NegotiationStatus.cancelada,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: AppDimensions.space16,
        title: const KusBrandLogo.compact(),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: context.appPrimary,
        backgroundColor: context.appSurface,
        strokeWidth: 2.5,
        child: CustomScrollView(
          physics: AppMotion.scrollPhysics,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(l10n)),
            if (_showsList) SliverToBoxAdapter(child: _buildFilterBar(l10n)),
            ..._buildContentSlivers(l10n),
          ],
        ),
      ),
    );
  }

  bool get _showsList =>
      !_isLoading && _errorMessage == null && _negotiations.isNotEmpty;

  /// Large title; the line beneath it answers the screen's question first:
  /// how many deals are waiting on this user.
  Widget _buildHeader(AppLocalizations l10n) {
    final awaiting = _negotiations.where(_isMyTurn).length;
    final String? subtitle = !_showsList
        ? null
        : awaiting > 0
        ? l10n.deals_awaiting_you(awaiting)
        : l10n.deals_total_count(_negotiations.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deals_title,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 30,
              color: context.appTextPrimary,
            ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.standard),
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            child: subtitle == null
                ? const SizedBox(
                    key: ValueKey('deals_subtitle_empty'),
                    width: double.infinity,
                  )
                : Padding(
                    key: ValueKey(subtitle),
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        if (awaiting > 0) ...[
                          const _TurnDot(),
                          const SizedBox(width: AppDimensions.space8),
                        ],
                        Flexible(
                          child: Text(
                            subtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: awaiting > 0
                                  ? context.appTextPrimary
                                  : context.appTextSecondary,
                              fontWeight: awaiting > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontFeatures: AppTextStyles.tabularFigures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    final hasTurnInProgress = _negotiations.any(_isMyTurn);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: AppSegmentedControl<_DealsFilter>(
          value: _filter,
          onChanged: (filter) => setState(() => _filter = filter),
          segments: {
            _DealsFilter.all: AppSegment(label: l10n.deals_tab_all),
            _DealsFilter.inProgress: AppSegment(
              label: l10n.deals_tab_in_progress,
              showDot: hasTurnInProgress,
            ),
            _DealsFilter.agreed: AppSegment(label: l10n.deals_tab_agreed),
            _DealsFilter.history: AppSegment(label: l10n.deals_tab_history),
          },
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(AppLocalizations l10n) {
    if (_isLoading && _negotiations.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: SectionSkeleton(
            kind: SectionSkeletonKind.rowCards,
            padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
          ),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: LucideIcons.cloudOff,
            title: l10n.deals_error_prefix(_errorMessage!),
            action: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.common_retry),
            ),
          ),
        ),
      ];
    }

    if (_negotiations.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(l10n),
        ),
      ];
    }

    final list = _negotiations.where((n) => _matches(n, _filter)).toList();
    if (list.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: LucideIcons.inbox,
            title: l10n.deals_filter_empty,
            message: l10n.deals_filter_empty_desc,
          ),
        ),
      ];
    }

    final animateEntrance = !_entrancePlayed;
    if (animateEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entrancePlayed = true;
      });
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppDimensions.space12),
          itemBuilder: (context, index) {
            final negotiation = list[index];
            return StaggeredEntrance(
              index: index,
              enabled: animateEntrance,
              child: _DealCard(
                key: ValueKey('deal_card_${negotiation.id}'),
                negotiation: negotiation,
                isBuyer: _isBuyer,
                isMyTurn: _isMyTurn(negotiation),
                isWaiting: _isActive(negotiation) && !_isMyTurn(negotiation),
                onTap: () => _navigateToDetail(negotiation),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final title = _isBuyer
        ? l10n.deals_empty_buyer_title
        : l10n.deals_empty_farmer_title;

    final desc = _isBuyer
        ? l10n.deals_empty_buyer_desc
        : l10n.deals_empty_farmer_desc;

    final buttonLabel = _isBuyer
        ? l10n.deals_explore_market
        : l10n.deals_view_crops;

    return AppEmptyState(
      icon: LucideIcons.handshake,
      tone: AppEmptyStateTone.brand,
      title: title,
      message: desc,
      action: ElevatedButton.icon(
        onPressed:
            widget.onEmptyAction ?? () => Navigator.of(context).maybePop(),
        icon: Icon(_isBuyer ? LucideIcons.store : LucideIcons.sprout, size: 18),
        label: Text(buttonLabel),
      ),
    );
  }

  void _navigateToDetail(NegotiationModel negotiation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DealDetailScreen(
          negotiationId: negotiation.id,
          role: widget.role,
          service: _service,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }
}

/// One negotiation in the list: the lot, the other party, the latest
/// figures on the table and whose move it is.
class _DealCard extends StatelessWidget {
  final NegotiationModel negotiation;
  final bool isBuyer;
  final bool isMyTurn;
  final bool isWaiting;
  final VoidCallback onTap;

  const _DealCard({
    super.key,
    required this.negotiation,
    required this.isBuyer,
    required this.isMyTurn,
    required this.isWaiting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offers = negotiation.offers;
    final NegotiationOfferModel? latestOffer =
        (offers != null && offers.isNotEmpty)
        ? offers.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final counterpartLabel = isBuyer
        ? l10n.deal_counterpart_farmer
        : l10n.deal_counterpart_buyer;

    final counterpartName = isBuyer
        ? (negotiation.farmerProfile?['full_name'] ??
              (negotiation.crop?.municipality != null
                  ? l10n.deals_producer_with_location(
                      negotiation.crop!.municipality,
                    )
                  : l10n.deals_producer))
        : (negotiation.buyerProfile?['full_name'] ?? l10n.deals_buyer);

    // A deal waiting on this user lifts its hairline to the brand tone.
    final borderColor = isMyTurn
        ? context.appBrandTriad.border
        : context.appBorder;

    return PressableScale(
      pressedScale: 0.985,
      child: Material(
        color: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DealCropThumb(crop: negotiation.crop, size: 48),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            negotiation.crop?.title ?? l10n.deals_unknown_crop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.deals_counterpart_name(
                              counterpartLabel,
                              counterpartName,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 13,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // The latest figures on the table, with the deal's status at
                // the end of the same line so the title keeps its full width.
                const SizedBox(height: AppDimensions.space16),
                Row(
                  children: [
                    Expanded(
                      child: latestOffer == null
                          ? const SizedBox.shrink()
                          : Row(
                              children: [
                                Flexible(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: CurrencyFormatters.formatCop(
                                            latestOffer.proposedPricePerKg,
                                          ),
                                          style: AppTextStyles.figureMedium
                                              .copyWith(
                                                fontSize: 20,
                                                color: context.appTextPrimary,
                                              ),
                                        ),
                                        TextSpan(
                                          text: ' /kg',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: context.appTextSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  UnitFormatters.formatKg(
                                    latestOffer.quantityKg,
                                  ),
                                  style: AppTextStyles.figureSmall.copyWith(
                                    color: context.appTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    NegotiationStatusBadge(status: negotiation.status),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                Divider(height: 1, thickness: 1, color: context.appDivider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (isMyTurn) ...[
                      const _TurnDot(),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        l10n.deals_your_turn,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.appPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else if (isWaiting) ...[
                      Icon(
                        LucideIcons.hourglass,
                        size: 13,
                        color: context.appTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.deals_waiting_response,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.appTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      DateFormatters.formatFullDateTime(negotiation.updatedAt),
                      style: AppTextStyles.caption.copyWith(
                        color: context.appTextSecondary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: context.appTextMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Your move" mark: a brand dot inside a soft halo of the same hue, the
/// way iOS flags an unread thread. Static on purpose: the list is opened
/// many times a day and a pulsing dot would only add noise.
class _TurnDot extends StatelessWidget {
  const _TurnDot();

  @override
  Widget build(BuildContext context) {
    final color = context.appPrimary;
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.appIsDark ? 0.22 : 0.14),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
