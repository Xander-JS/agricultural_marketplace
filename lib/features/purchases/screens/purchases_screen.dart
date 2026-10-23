import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../deals/models/negotiation_model.dart';
import '../../deals/models/negotiation_status.dart';
import '../services/purchases_service.dart';
import '../widgets/purchase_card.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/app_empty_state.dart';
import '../../../../core/widgets/inputs/app_segmented_control.dart';
import '../../../../core/widgets/loading/section_skeletons.dart';
import '../../../../core/widgets/misc/staggered_entrance.dart';

/// Sections of the purchases list.
enum _PurchasesFilter { all, agreed, completed }

/// Pantalla principal del Módulo de Compras para el rol Comerciante/Comprador.
///
/// Permite consultar los acuerdos vigentes (`acordada`) y las compras cerradas
/// (`completada`) pactadas con productores agrícolas a partir de datos reales
/// de `negotiations`, `crops` y `negotiation_offers`.
class PurchasesScreen extends StatefulWidget {
  final List<NegotiationModel>? initialPurchases;
  final PurchasesService? service;
  final VoidCallback? onExploreMarket;

  const PurchasesScreen({
    super.key,
    this.initialPurchases,
    this.service,
    this.onExploreMarket,
  });

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  late final PurchasesService _service;

  bool _isLoading = true;
  String? _errorMessage;
  List<NegotiationModel> _purchases = [];
  _PurchasesFilter _filter = _PurchasesFilter.all;
  bool _entrancePlayed = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PurchasesService();

    if (widget.initialPurchases != null) {
      _purchases = widget.initialPurchases!;
      _isLoading = false;
    } else {
      _loadPurchases();
    }
  }

  Future<void> _loadPurchases() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? userId;
      try {
        userId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _purchases = [];
          });
        }
        return;
      }

      final data = await _service.getPurchases(userId);
      if (mounted) {
        setState(() {
          _purchases = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<NegotiationModel> _getFilteredPurchases(_PurchasesFilter filter) {
    switch (filter) {
      case _PurchasesFilter.agreed:
        return _purchases
            .where((p) => p.status == NegotiationStatus.acordada)
            .toList();
      case _PurchasesFilter.completed:
        return _purchases
            .where((p) => p.status == NegotiationStatus.completada)
            .toList();
      case _PurchasesFilter.all:
        return _purchases;
    }
  }

  int get _agreedCount =>
      _purchases.where((p) => p.status == NegotiationStatus.acordada).length;

  double get _totalInvested {
    double sum = 0.0;
    for (final p in _purchases) {
      final latestOffer = (p.offers != null && p.offers!.isNotEmpty)
          ? p.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          : null;
      if (latestOffer != null) {
        sum += (latestOffer.quantityKg * latestOffer.proposedPricePerKg);
      }
    }
    return sum;
  }

  double get _totalVolumeKg {
    double sum = 0.0;
    for (final p in _purchases) {
      final latestOffer = (p.offers != null && p.offers!.isNotEmpty)
          ? p.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
          : null;
      if (latestOffer != null) {
        sum += latestOffer.quantityKg;
      }
    }
    return sum;
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
        onRefresh: _loadPurchases,
        color: context.appPrimary,
        backgroundColor: context.appSurface,
        strokeWidth: 2.5,
        child: CustomScrollView(
          physics: AppMotion.scrollPhysics,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(l10n)),
            ..._buildContentSlivers(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.purchases_title,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 30,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.purchases_subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(AppLocalizations l10n) {
    if (_isLoading && _purchases.isEmpty) {
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
            title: l10n.purchases_error_prefix(_errorMessage!),
            action: ElevatedButton.icon(
              onPressed: _loadPurchases,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.common_retry),
            ),
          ),
        ),
      ];
    }

    if (_purchases.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(l10n),
        ),
      ];
    }

    final items = _getFilteredPurchases(_filter);

    final animateEntrance = !_entrancePlayed;
    if (animateEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entrancePlayed = true;
      });
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: _SummaryCard(
            totalInvested: _totalInvested,
            purchasesCount: _purchases.length,
            agreedCount: _agreedCount,
            totalVolumeKg: _totalVolumeKg,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: AppSegmentedControl<_PurchasesFilter>(
              value: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
              segments: {
                _PurchasesFilter.all: AppSegment(label: l10n.purchases_tab_all),
                _PurchasesFilter.agreed: AppSegment(
                  label: l10n.purchases_tab_agreed,
                ),
                _PurchasesFilter.completed: AppSegment(
                  label: l10n.purchases_tab_completed,
                ),
              },
            ),
          ),
        ),
      ),
      if (items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: LucideIcons.inbox,
            title: l10n.purchases_filter_empty,
          ),
        )
      else
        // Purchases are few and bounded, so the list is built eagerly:
        // every card exists for the staggered entrance and for tests.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(height: AppDimensions.space12),
                  StaggeredEntrance(
                    index: index,
                    enabled: animateEntrance,
                    child: PurchaseCard(
                      key: ValueKey('purchase_card_${items[index].id}'),
                      purchase: items[index],
                      onRefresh: _loadPurchases,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return AppEmptyState(
      icon: LucideIcons.shoppingBag,
      tone: AppEmptyStateTone.brand,
      title: l10n.purchases_empty_title,
      message: l10n.purchases_empty_desc,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onExploreMarket != null) ...[
            ElevatedButton.icon(
              onPressed: widget.onExploreMarket,
              icon: const Icon(LucideIcons.store, size: 18),
              label: Text(l10n.purchases_empty_action),
            ),
            const SizedBox(height: AppDimensions.space16),
          ],
          // Which module and role this space belongs to.
          // Row, not Wrap: SliverFillRemaining sizes this card from its
          // intrinsic height, which Wrap under-reports.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.purchases_placeholder_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: context.appInfoTriad.background,
                  borderRadius: AppDimensions.borderRadiusSM,
                  border: Border.all(color: context.appInfoTriad.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.briefcaseBusiness,
                      size: 12,
                      color: context.appInfoTriad.foreground,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      l10n.purchases_merchant_role,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.appInfoTriad.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wallet-style summary of the buyer's purchases. The agreed total answers
/// the screen's question and leads at display size; open agreements and
/// volume sit beneath it, split by a hairline.
class _SummaryCard extends StatelessWidget {
  final double totalInvested;
  final int purchasesCount;
  final int agreedCount;
  final double totalVolumeKg;

  const _SummaryCard({
    required this.totalInvested,
    required this.purchasesCount,
    required this.agreedCount,
    required this.totalVolumeKg,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InsetGroupCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KpiLabel(
                  icon: LucideIcons.wallet,
                  label: l10n.purchases_total_invested,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatters.formatCop(totalInvested),
                    style: AppTextStyles.figureLarge.copyWith(
                      fontSize: 32,
                      letterSpacing: -0.8,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.purchases_total_caption(purchasesCount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.appDivider),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _SecondaryKpi(
                    icon: LucideIcons.handshake,
                    label: l10n.purchases_total_agreed,
                    value: agreedCount.toString(),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: context.appDivider,
                ),
                Expanded(
                  child: _SecondaryKpi(
                    icon: LucideIcons.scale,
                    label: l10n.purchases_total_volume,
                    value: UnitFormatters.formatKg(totalVolumeKg),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _KpiLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: context.appTextSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 13,
              color: context.appTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryKpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SecondaryKpi({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KpiLabel(icon: icon, label: label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.figureMedium.copyWith(
                fontSize: 20,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
