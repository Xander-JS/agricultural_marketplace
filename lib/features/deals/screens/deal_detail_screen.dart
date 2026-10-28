import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import '../widgets/deal_crop_thumb.dart';
import '../widgets/delivery_presentation.dart';
import '../widgets/negotiation_status_badge.dart';
import '../../review/services/review_service.dart';
import 'counter_offer_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../../../core/widgets/buttons/primary_action_button.dart';
import '../../../core/widgets/buttons/secondary_action_button.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/cards/inset_group_section.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../core/widgets/feedback/status_banner.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';
import '../../../core/widgets/loading/app_skeleton.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../../../core/widgets/sheets/app_sheet_frame.dart';
import '../../../core/constants/input_limits.dart';

class DealDetailScreen extends StatefulWidget {
  final String negotiationId;
  final String? role;
  final NegotiationModel? initialNegotiation;
  final NegotiationService? service;
  final ReviewService? reviewService;

  const DealDetailScreen({
    super.key,
    required this.negotiationId,
    this.role,
    this.initialNegotiation,
    this.service,
    this.reviewService,
  });

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  late final NegotiationService _service;
  late final ReviewService _reviewService;
  bool _isLoading = true;
  bool _isLoadingContact = false;
  bool _isActionInProgress = false;
  bool _isLoadingReviewStatus = false;
  bool _isSubmittingReview = false;
  bool? _hasReviewed;
  String? _reviewStatusError;
  String? _errorMessage;
  NegotiationModel? _negotiation;
  NegotiationContactInfo? _contactInfo;

  bool get _isBuyer {
    if (widget.role != null && widget.role!.trim().isNotEmpty) {
      return UserRole.isBuyerRole(widget.role);
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _negotiation != null) {
      return _negotiation!.buyerId == user.id;
    }
    if (user != null && widget.negotiationId.isNotEmpty) {
      // Fallback: try to infer from negotiation if loaded later; default to false if unknown
    }
    return false;
  }

  bool get _isMyTurn {
    if (_negotiation == null) return false;
    return _negotiation!.isMyTurn(isBuyer: _isBuyer);
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NegotiationService();
    _reviewService = widget.reviewService ?? ReviewService();

    if (widget.initialNegotiation != null) {
      _negotiation = widget.initialNegotiation;
      _isLoading = false;
    }
    _loadData();
  }

  Future<void> _loadData({bool reload = false}) async {
    if (!reload && _negotiation != null) {
      // El detalle ya se puede pintar con la negociación disponible; los datos
      // de contacto son opcionales y nunca deben bloquear la pantalla.
      final status = _negotiation!.status;
      if (status == NegotiationStatus.acordada ||
          status == NegotiationStatus.completada) {
        unawaited(_loadContactInfo());
      }
      _loadReviewStatusIfNeeded();
      return;
    }

    setState(() {
      _isLoading = _negotiation == null;
      _errorMessage = null;
    });

    try {
      final negotiation = await _service.getNegotiationById(
        widget.negotiationId,
      );

      if (!mounted) return;
      setState(() {
        _negotiation = negotiation;
        _isLoading = false;
      });

      if (negotiation.status == NegotiationStatus.acordada ||
          negotiation.status == NegotiationStatus.completada) {
        unawaited(_loadContactInfo());
      }
      _loadReviewStatusIfNeeded(force: reload);
    } catch (e) {
      if (mounted) {
        setState(() {
          // Si ya había datos visibles, se conserva el detalle y se evita
          // reemplazarlo por la pantalla de error.
          if (_negotiation == null) {
            _errorMessage = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  /// Consulta el estado de calificación únicamente cuando el trato está
  /// completado. Un fallo de esta consulta no oculta el detalle del trato.
  void _loadReviewStatusIfNeeded({bool force = false}) {
    final negotiation = _negotiation;
    if (negotiation == null ||
        negotiation.status != NegotiationStatus.completada) {
      return;
    }
    unawaited(_loadReviewStatus(force: force));
  }

  Future<void> _loadReviewStatus({bool force = false}) async {
    if (_isLoadingReviewStatus) return;
    if (!force && _hasReviewed != null) return;

    final negotiation = _negotiation;
    if (negotiation == null ||
        negotiation.status != NegotiationStatus.completada) {
      return;
    }

    setState(() {
      _isLoadingReviewStatus = true;
      _reviewStatusError = null;
    });

    try {
      final hasReviewed = await _reviewService.hasReviewedNegotiation(
        negotiation.id,
      );
      if (!mounted) return;
      setState(() {
        _hasReviewed = hasReviewed;
        _isLoadingReviewStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasReviewed = null;
        _reviewStatusError = _readableError(e);
        _isLoadingReviewStatus = false;
      });
    }
  }

  /// Carga los datos de contacto autorizados de forma independiente.
  /// Un fallo o una demora de esta RPC no impide ver el trato.
  Future<void> _loadContactInfo() async {
    if (_isLoadingContact) return;
    _isLoadingContact = true;
    try {
      final contactInfo = await _service.getCounterpartContact(
        widget.negotiationId,
      );
      if (mounted) {
        setState(() {
          _contactInfo = contactInfo;
        });
      }
    } catch (e) {
      debugPrint('Aviso: no se pudo consultar contacto de contraparte: $e');
    } finally {
      _isLoadingContact = false;
      // Retira el esqueleto de la tarjeta de contacto.
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = _negotiation;
    final showContent = !_isLoading && _errorMessage == null && n != null;

    return Scaffold(
      backgroundColor: context.appBackground,
      // The action bar is translucent: the timeline scrolls beneath it.
      extendBody: true,
      appBar: AppBar(title: Text(l10n.deal_detail_title)),
      body: Builder(builder: (context) => _buildBody(context, l10n)),
      bottomNavigationBar: showContent ? _buildActionBar(n, l10n) : null,
    );
  }

  List<NegotiationOfferModel> _sortedOffers(NegotiationModel n) {
    final offers = n.offers != null
        ? List<NegotiationOfferModel>.from(n.offers!)
        : <NegotiationOfferModel>[];
    offers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return offers;
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }

    if (_errorMessage != null) {
      return AppEmptyState(
        icon: LucideIcons.cloudOff,
        title: l10n.deals_error_prefix(_errorMessage!),
        action: ElevatedButton.icon(
          onPressed: () => _loadData(reload: true),
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(l10n.common_retry),
        ),
      );
    }

    if (_negotiation == null) {
      return AppEmptyState(
        icon: LucideIcons.searchX,
        title: l10n.deal_detail_not_found,
        action: ElevatedButton.icon(
          onPressed: () => _loadData(reload: true),
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(l10n.common_retry),
        ),
      );
    }

    final n = _negotiation!;
    final offers = _sortedOffers(n);
    final latestOffer = offers.isNotEmpty ? offers.last : null;
    final isClosedWithContact =
        n.status == NegotiationStatus.acordada ||
        n.status == NegotiationStatus.completada;
    final isActive =
        n.status == NegotiationStatus.propuesta ||
        n.status == NegotiationStatus.contraofertada;

    return RefreshIndicator(
      onRefresh: () => _loadData(reload: true),
      color: context.appPrimary,
      backgroundColor: context.appSurface,
      strokeWidth: 2.5,
      child: SingleChildScrollView(
        physics: AppMotion.scrollPhysics,
        padding: EdgeInsets.fromLTRB(
          AppDimensions.space16,
          AppDimensions.space8,
          AppDimensions.space16,
          AppDimensions.space32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(n, latestOffer, l10n),

            if (n.status == NegotiationStatus.acordada) ...[
              const SizedBox(height: AppDimensions.space12),
              StatusBanner(
                tone: StatusTone.success,
                icon: LucideIcons.handshake,
                message: l10n.deal_agreed_desc,
              ),
            ],

            // Contacto comercial liberado cuando el trato está acordado o
            // completado.
            if (isClosedWithContact) ...[
              const SizedBox(height: AppDimensions.space24),
              _buildContactAndConsentSection(n, l10n),
            ],

            if (offers.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space32),
              Padding(
                padding: const EdgeInsets.only(left: AppDimensions.space4),
                child: Text(
                  l10n.deal_history_title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              for (var i = 0; i < offers.length; i++)
                _OfferBubble(
                  offer: offers[i],
                  previous: i > 0 ? offers[i - 1] : null,
                  isMine: _isMine(offers[i], n),
                  sentByFarmer: offers[i].senderId != n.buyerId,
                  senderLabel: _isMine(offers[i], n)
                      ? l10n.deal_detail_you
                      : (_isBuyer
                            ? l10n.deal_counterpart_farmer
                            : l10n.deal_counterpart_buyer),
                ),
            ],

            // Turno de la contraparte: una burbuja en espera cierra la
            // conversación, como un "escribiendo…".
            if (isActive && !_isMyTurn) ...[
              _WaitingBubble(
                message: _isBuyer
                    ? l10n.deal_waiting_farmer
                    : l10n.deal_waiting_buyer,
              ),
              if (_isBuyer && n.status == NegotiationStatus.propuesta) ...[
                const SizedBox(height: AppDimensions.space16),
                SecondaryActionButton(
                  onPressed: _isActionInProgress ? null : () => _cancelOffer(n),
                  text: l10n.deal_cancel_deal,
                  icon: LucideIcons.ban,
                  tone: SecondaryActionTone.destructive,
                ),
              ],
            ],

            if (n.status == NegotiationStatus.completada) ...[
              const SizedBox(height: AppDimensions.space24),
              _buildRatingSection(n, l10n),
            ],
          ],
        ),
      ),
    );
  }

  /// Whether [offer] was sent by the signed-in user. Without a session the
  /// side is inferred from the role: the buyer sends from `buyerId`.
  bool _isMine(NegotiationOfferModel offer, NegotiationModel n) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) return offer.senderId == userId;
    final sentByBuyer = offer.senderId == n.buyerId;
    return _isBuyer ? sentByBuyer : !sentByBuyer;
  }

  /// Deal summary: the lot, the other party and the terms on the table.
  Widget _buildSummaryCard(
    NegotiationModel n,
    NegotiationOfferModel? latestOffer,
    AppLocalizations l10n,
  ) {
    final crop = n.crop;
    final counterpartLabel = _isBuyer
        ? l10n.deal_counterpart_farmer
        : l10n.deal_counterpart_buyer;

    final counterpartProfile = _isBuyer ? n.farmerProfile : n.buyerProfile;
    final counterpartName = _isBuyer
        ? (n.farmerProfile?['full_name'] ??
              l10n.deals_producer_with_location(n.crop?.municipality ?? ''))
        : (n.buyerProfile?['full_name'] ?? l10n.deals_buyer);

    final place = [
      crop?.municipality,
      crop?.department,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    final cropLine = [
      crop?.cropType,
      place,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');

    return InsetGroupCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DealCropThumb(crop: crop, size: 56),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop?.title ?? l10n.deals_unknown_crop,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                      if (cropLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cropLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 13,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space8),
                      NegotiationStatusBadge(status: n.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.appDivider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                UserAvatar(
                  key: const ValueKey('deal_detail_counterpart_avatar'),
                  imageUrl: counterpartProfile?['profile_path'] as String?,
                  radius: 18,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterpartLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      Text(
                        counterpartName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (latestOffer != null) ...[
            Divider(height: 1, thickness: 1, color: context.appDivider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _TermFigure(
                        label: l10n.deal_detail_price_per_kg,
                        value: CurrencyFormatters.formatCop(
                          latestOffer.proposedPricePerKg,
                        ),
                        emphasized: true,
                      ),
                    ),
                    VerticalDivider(width: 24, color: context.appDivider),
                    Expanded(
                      child: _TermFigure(
                        label: l10n.deal_detail_quantity,
                        value: UnitFormatters.formatKg(latestOffer.quantityKg),
                      ),
                    ),
                    VerticalDivider(width: 24, color: context.appDivider),
                    Expanded(
                      child: _TermFigure(
                        label: l10n.deal_detail_total,
                        value: CurrencyFormatters.formatCop(
                          latestOffer.quantityKg *
                              latestOffer.proposedPricePerKg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: context.appDivider),
            _buildDeliveryRow(latestOffer, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryRow(NegotiationOfferModel offer, AppLocalizations l10n) {
    final presentation = deliveryPresentation(l10n, offer.deliveryMethod);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            presentation.icon,
            size: AppDimensions.iconSM,
            color: context.appTextSecondary,
          ),
          const SizedBox(width: AppDimensions.space12),
          // Label and value share the line, so neither is squeezed into
          // breaking a word.
          Flexible(
            child: Text(
              l10n.deal_detail_delivery_method,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Flexible(
            child: Text(
              deliveryDisplayLabel(l10n, offer.deliveryMethod),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Frosted bottom bar with the moves available to this user right now:
  /// respond on their turn, or close an agreed deal.
  Widget? _buildActionBar(NegotiationModel n, AppLocalizations l10n) {
    final offers = _sortedOffers(n);
    final latestOffer = offers.isNotEmpty ? offers.last : null;
    final isActive =
        n.status == NegotiationStatus.propuesta ||
        n.status == NegotiationStatus.contraofertada;

    if (n.status == NegotiationStatus.acordada) {
      return _FrostedActionBar(
        children: [
          PrimaryActionButton(
            onPressed: _isActionInProgress
                ? null
                : () => _completeNegotiation(n),
            text: l10n.deal_complete_btn,
          ),
          const SizedBox(height: AppDimensions.space4),
          SizedBox(
            height: AppDimensions.minTouchTarget,
            child: TextButton(
              onPressed: _isActionInProgress ? null : () => _cancelOffer(n),
              style: TextButton.styleFrom(
                foregroundColor: context.appErrorText,
              ),
              child: Text(l10n.deal_cancel_agreed),
            ),
          ),
        ],
      );
    }

    if (!isActive || !_isMyTurn) return null;

    // Es mi turno: Aceptar, Contraofertar o Rechazar.
    return _FrostedActionBar(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: context.appPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Text(
              l10n.deal_detail_your_turn_bar,
              style: AppTextStyles.labelMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Accepting is the one decision the bar leads with; countering and
        // rejecting live one tap away so they never compete with it.
        Row(
          children: [
            Expanded(
              child: PrimaryActionButton(
                onPressed: _isActionInProgress
                    ? null
                    : () => _acceptOffer(n, latestOffer),
                text: l10n.deal_accept_offer,
              ),
            ),
            const SizedBox(width: 10),
            _DealMoreActionsButton(
              enabled: !_isActionInProgress,
              onCounterOffer: latestOffer == null
                  ? null
                  : () => _navigateToCounterOffer(n, latestOffer),
              onReject: () => _rejectOffer(n),
            ),
          ],
        ),
      ],
    );
  }

  /// Sección de calificación postventa. Solo se muestra para tratos
  /// completados y deshabilita el formulario cuando ya existe una reseña del
  /// usuario autenticado.
  Widget _buildRatingSection(NegotiationModel n, AppLocalizations l10n) {
    final rateLabel = _isBuyer
        ? l10n.deal_detail_rate_farmer
        : l10n.deal_detail_rate_buyer;

    final Widget state;
    if (_isLoadingReviewStatus) {
      state = Row(
        children: [
          const CupertinoActivityIndicator(radius: 8),
          const SizedBox(width: 10),
          Text(
            l10n.deal_detail_rate_loading,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      );
    } else if (_hasReviewed == true) {
      state = StatusBanner(
        tone: StatusTone.success,
        icon: LucideIcons.badgeCheck,
        title: l10n.deal_detail_rated,
        message: l10n.deal_detail_rated_desc,
      );
    } else if (_reviewStatusError != null) {
      state = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _reviewStatusError!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appErrorText,
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          SecondaryActionButton(
            onPressed: () => _loadReviewStatus(force: true),
            text: l10n.common_retry,
            icon: LucideIcons.refreshCw,
            height: AppDimensions.buttonHeightMedium,
          ),
        ],
      );
    } else {
      state = PrimaryActionButton(
        onPressed: _hasReviewed == false ? () => _openRatingSheet(n) : null,
        text: rateLabel,
      );
    }

    return InsetGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconSquircle(
                icon: _hasReviewed == true
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.star,
                triad: _hasReviewed == true
                    ? AppSemanticTriad(
                        background: context.appIconTriad.background,
                        border: AppColors.transparent,
                        foreground: context.appRatingGold,
                      )
                    : null,
                size: 40,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deal_detail_rate_title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.deal_detail_rate_subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          state,
        ],
      ),
    );
  }

  Future<void> _openRatingSheet(NegotiationModel n) async {
    if (_isSubmittingReview || _hasReviewed != false) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => _RatingSheet(
        counterpartLabel: _isBuyer
            ? AppLocalizations.of(context)!.deal_counterpart_farmer
            : AppLocalizations.of(context)!.deal_counterpart_buyer,
        onSubmit: (rating, comment) async {
          _isSubmittingReview = true;
          try {
            await _reviewService.submitReview(
              negotiationId: n.id,
              rating: rating,
              comment: comment,
            );
          } finally {
            _isSubmittingReview = false;
          }
        },
      ),
    );

    if (submitted != true || !mounted) return;

    setState(() {
      _hasReviewed = true;
      _reviewStatusError = null;
    });
    final l10n = AppLocalizations.of(context)!;
    showAppSnackBar(
      context,
      l10n.deal_detail_rate_success,
      tone: StatusTone.success,
    );
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty
        ? AppLocalizations.of(context)!.deal_detail_generic_error
        : message;
  }

  /// Tarjeta de contacto comercial liberado por la contraparte y acceso a los
  /// permisos propios del trato acordado.
  Widget _buildContactAndConsentSection(
    NegotiationModel n,
    AppLocalizations l10n,
  ) {
    final contact = _contactInfo;
    final isLoading = contact == null && _isLoadingContact;
    final hasPhone = contact != null && contact.hasCounterpartPhone;
    final hasLocation = contact != null && contact.hasCounterpartLocation;
    final released = hasPhone || hasLocation;
    final theCounterpart = _isBuyer
        ? l10n.deal_detail_the_farmer
        : l10n.deal_detail_the_buyer;

    final title = released
        ? l10n.deal_detail_contact_released
        : (_isBuyer
              ? l10n.deal_detail_contact_farmer
              : l10n.deal_detail_contact_buyer);

    final rows = <Widget>[];

    if (isLoading) {
      rows.add(const _ContactSkeleton());
    } else {
      // 1. Teléfono / WhatsApp
      if (hasPhone) {
        rows.add(_buildPhoneBlock(contact.counterpartPhone!, l10n));
      } else {
        rows.add(
          _LockedRow(
            icon: LucideIcons.phoneOff,
            text: l10n.deal_detail_contact_not_shared(theCounterpart),
          ),
        );
      }

      // 2. Ubicación física
      if (hasLocation) {
        final place = [
          contact.counterpartMunicipality,
          contact.counterpartDepartment,
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
        final hasCoordinates =
            contact.counterpartLatitude != null &&
            contact.counterpartLongitude != null;
        rows.add(
          InsetGroupRow(
            leading: IconSquircle(icon: LucideIcons.mapPin, size: 30),
            title: place.isEmpty ? l10n.deal_detail_view_location : place,
            subtitle: hasCoordinates
                ? l10n.deal_detail_coordinates(
                    contact.counterpartLatitude!.toStringAsFixed(6),
                    contact.counterpartLongitude!.toStringAsFixed(6),
                  )
                : null,
            onTap: () => _showLocationDialog(contact),
          ),
        );
      } else {
        rows.add(
          _LockedRow(
            icon: LucideIcons.mapPinOff,
            text: l10n.deal_detail_location_not_shared(theCounterpart),
          ),
        );
      }
    }

    // 3. Mis permisos configurados
    final phoneStatus = contact?.mySharePhone == true
        ? l10n.deal_detail_authorized
        : l10n.deal_detail_private;
    final locationStatus = contact?.myShareLocation == true
        ? l10n.deal_detail_location_authorized_status
        : l10n.deal_detail_location_private_status;
    rows.add(
      InsetGroupRow(
        leading: IconSquircle(icon: LucideIcons.shieldCheck, size: 30),
        title: l10n.deal_detail_my_permissions_title,
        subtitle:
            '${l10n.deal_detail_phone_permission(phoneStatus)} · '
            '${l10n.deal_detail_location_permission(locationStatus)}',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.deal_detail_modify,
              style: AppTextStyles.labelMedium.copyWith(
                color: context.appPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.appTextMuted,
            ),
          ],
        ),
        onTap: () => _showConsentBottomSheet(n),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.space4,
            bottom: AppDimensions.space12,
          ),
          child: Row(
            children: [
              Icon(
                released ? LucideIcons.shieldCheck : LucideIcons.lockKeyhole,
                size: 18,
                color: released ? context.appSuccess : context.appTextSecondary,
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        InsetGroupSection(children: rows),
      ],
    );
  }

  /// Authorized phone in large tabular figures with Contacts-style actions
  /// beneath it.
  Widget _buildPhoneBlock(String phone, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deal_detail_phone_whatsapp.replaceAll(':', ''),
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            phone,
            style: AppTextStyles.figureLarge.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: _ContactAction(
                  icon: LucideIcons.phone,
                  label: l10n.deal_detail_call,
                  onTap: () => _handleCall(phone),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: _ContactAction(
                  icon: LucideIcons.messageCircle,
                  label: l10n.deal_detail_whatsapp,
                  onTap: () => _handleWhatsApp(phone),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: _ContactAction(
                  icon: LucideIcons.copy,
                  label: l10n.deal_detail_copy,
                  onTap: () => _copyToClipboard(phone, l10n.deal_detail_phone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.deal_detail_copied(label, text),
      tone: StatusTone.success,
    );
  }

  void _handleCall(String phone) {
    _copyToClipboard(phone, AppLocalizations.of(context)!.deal_detail_phone);
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.deal_detail_phone_copied(phone),
      tone: StatusTone.success,
    );
  }

  void _handleWhatsApp(String phone) {
    _copyToClipboard(phone, AppLocalizations.of(context)!.deal_detail_whatsapp);
    showAppSnackBar(
      context,
      AppLocalizations.of(context)!.deal_detail_whatsapp_copied(phone),
      tone: StatusTone.success,
    );
  }

  void _showLocationDialog(NegotiationContactInfo contact) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final labelStyle = AppTextStyles.labelMedium.copyWith(
          color: ctx.appTextSecondary,
        );
        final hasCoordinates =
            contact.counterpartLatitude != null &&
            contact.counterpartLongitude != null;

        return AlertDialog(
          icon: IconSquircle(icon: LucideIcons.mapPin, size: 48),
          title: Text(l10n.deal_detail_location_authorized.replaceAll(':', '')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.counterpartMunicipality != null ||
                  contact.counterpartDepartment != null) ...[
                Text(
                  l10n.deal_detail_municipality_department,
                  style: labelStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  '${contact.counterpartMunicipality ?? ""}, ${contact.counterpartDepartment ?? ""}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: ctx.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (hasCoordinates) ...[
                Text(l10n.deal_detail_geo_coordinates, style: labelStyle),
                const SizedBox(height: 4),
                SelectableText(
                  l10n.deal_detail_lat_lon(
                    contact.counterpartLatitude!.toStringAsFixed(6),
                    contact.counterpartLongitude!.toStringAsFixed(6),
                  ),
                  style: AppTextStyles.figureSmall.copyWith(
                    color: ctx.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.deal_detail_location_verified,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ctx.appTextSecondary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (hasCoordinates)
              TextButton.icon(
                onPressed: () {
                  final coords =
                      '${contact.counterpartLatitude},${contact.counterpartLongitude}';
                  _copyToClipboard(coords, l10n.deal_detail_coordinates_label);
                  Navigator.pop(ctx);
                },
                icon: const Icon(LucideIcons.copy, size: 16),
                label: Text(l10n.deal_detail_copy_coordinates),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.common_close),
            ),
          ],
        );
      },
    );
  }

  /// Small blocking indicator while a deal action reaches the server.
  void _showProgressHud() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ProgressHud(),
    );
  }

  void _navigateToCounterOffer(
    NegotiationModel n,
    NegotiationOfferModel latestOffer,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CounterOfferScreen(
          negotiation: n,
          latestOffer: latestOffer,
          role: widget.role,
          service: _service,
        ),
      ),
    );
    if (result == true) {
      _loadData(reload: true);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _acceptOffer(NegotiationModel n, NegotiationOfferModel? latestOffer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => _AcceptOfferConsentSheet(
        negotiation: n,
        latestOffer: latestOffer,
        isBuyer: _isBuyer,
        onConfirm: (sharePhone, shareLocation) async {
          Navigator.pop(ctx);
          await _executeAcceptWithConsent(n, sharePhone, shareLocation);
        },
      ),
    );
  }

  Future<void> _executeAcceptWithConsent(
    NegotiationModel n,
    bool sharePhone,
    bool shareLocation,
  ) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    final l10n = AppLocalizations.of(context)!;
    try {
      _showProgressHud();

      // 1. Aceptar oferta formalmente (RPC existente accept_negotiation que reserva inventario)
      await _service.acceptOffer(n.id);

      // 2. Persistir consentimiento bidireccional seleccionado
      try {
        await _service.setNegotiationConsent(
          negotiationId: n.id,
          sharePhone: sharePhone,
          shareLocation: shareLocation,
        );
      } catch (consentError) {
        debugPrint(
          'Aviso: no se pudo guardar consentimiento inicial: $consentError',
        );
      }

      if (mounted) {
        Navigator.pop(context); // pop loading dialog
        showAppSnackBar(
          context,
          l10n.deal_accept_success,
          tone: StatusTone.success,
        );
        _loadData(reload: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tone: StatusTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }

  void _showConsentBottomSheet(NegotiationModel n) {
    final l10n = AppLocalizations.of(context)!;
    final currentPhone = _contactInfo?.mySharePhone ?? false;
    final currentLocation = _contactInfo?.myShareLocation ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => _EditConsentSheet(
        initialSharePhone: currentPhone,
        initialShareLocation: currentLocation,
        isBuyer: _isBuyer,
        onSave: (sharePhone, shareLocation) async {
          Navigator.pop(ctx);
          try {
            _showProgressHud();

            await _service.setNegotiationConsent(
              negotiationId: n.id,
              sharePhone: sharePhone,
              shareLocation: shareLocation,
            );

            if (mounted) {
              Navigator.pop(context); // pop loading
              showAppSnackBar(
                context,
                l10n.deal_detail_permissions_updated,
                tone: StatusTone.success,
              );
              _loadData(reload: true);
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              showAppSnackBar(
                context,
                l10n.deal_detail_permissions_update_error(
                  e.toString().replaceFirst('Exception: ', ''),
                ),
                tone: StatusTone.error,
              );
            }
          }
        },
      ),
    );
  }

  /// Confirmation for a destructive or final deal action.
  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.profile_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
              backgroundColor: destructive
                  ? context.appError
                  : context.appPrimary,
              foregroundColor: destructive
                  ? context.appOverlayText
                  : context.appOnPrimary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectOffer(NegotiationModel n) async {
    if (_isActionInProgress) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _confirm(
      title: l10n.deal_reject_confirm_title,
      message: l10n.deal_reject_confirm_desc,
      confirmLabel: l10n.deal_reject_deal,
    );

    if (confirm != true) return;

    _isActionInProgress = true;
    try {
      if (mounted) _showProgressHud();

      await _service.rejectOffer(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        showAppSnackBar(
          context,
          l10n.deal_reject_success,
          tone: StatusTone.error,
        );
        _loadData(reload: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tone: StatusTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }

  Future<void> _cancelOffer(NegotiationModel n) async {
    if (_isActionInProgress) return;
    final l10n = AppLocalizations.of(context)!;
    final isAgreed = n.status == NegotiationStatus.acordada;
    final confirm = await _confirm(
      title: isAgreed
          ? l10n.deal_detail_cancel_confirm_title
          : l10n.deal_detail_cancel_proposal_title,
      message: isAgreed
          ? l10n.deal_detail_cancel_confirm_desc
          : l10n.deal_detail_cancel_proposal_desc,
      confirmLabel: isAgreed ? l10n.deal_cancel_agreed : l10n.deal_cancel_deal,
    );

    if (confirm != true) return;

    _isActionInProgress = true;
    try {
      if (mounted) _showProgressHud();

      await _service.cancelOffer(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        showAppSnackBar(
          context,
          isAgreed
              ? l10n.deal_detail_cancelled_success
              : l10n.deal_detail_proposal_cancelled_success,
          tone: StatusTone.error,
        );
        _loadData(reload: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tone: StatusTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }

  Future<void> _completeNegotiation(NegotiationModel n) async {
    if (_isActionInProgress) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await _confirm(
      title: l10n.deal_detail_complete_confirm_title,
      message: l10n.deal_detail_complete_confirm_desc,
      confirmLabel: l10n.deal_detail_complete,
      destructive: false,
    );

    if (confirm != true) return;

    _isActionInProgress = true;
    try {
      if (mounted) _showProgressHud();

      await _service.completeNegotiation(n.id);

      if (mounted) {
        Navigator.pop(context); // pop loading
        showAppSnackBar(
          context,
          l10n.deal_detail_completed,
          tone: StatusTone.success,
        );
        _loadData(reload: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tone: StatusTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      } else {
        _isActionInProgress = false;
      }
    }
  }
}

/// One term of the deal: a small label over its tabular figure.
class _TermFigure extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _TermFigure({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Two lines so "Precio por kg" wraps between words at large sizes.
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.figureMedium.copyWith(
              fontSize: 16,
              color: emphasized ? context.appPrimary : context.appTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// One offer in the negotiation thread, iMessage style: the user's own
/// offers sit right, the other party's sit left. The tone follows the
/// sender's role, emerald for the farmer and sapphire for the buyer, so the
/// thread reads at a glance. The price per kg leads in large tabular
/// figures; the move against the previous offer is spelled out beneath it.
class _OfferBubble extends StatelessWidget {
  final NegotiationOfferModel offer;
  final NegotiationOfferModel? previous;
  final bool isMine;
  final bool sentByFarmer;
  final String senderLabel;

  const _OfferBubble({
    required this.offer,
    required this.previous,
    required this.isMine,
    required this.sentByFarmer,
    required this.senderLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.appIsDark;
    final hue = sentByFarmer ? context.appPrimary : context.appInfo;
    final fill = hue.withValues(alpha: dark ? 0.16 : 0.10);
    final outline = hue.withValues(alpha: dark ? 0.45 : 0.32);
    final ink = context.appTextPrimary;
    // Secondary text is tinted from the bubble's hue, never grey.
    final soft = sentByFarmer ? context.appOnPrimarySoft : context.appInfoText;
    final delivery = deliveryPresentation(l10n, offer.deliveryMethod);
    final subtotal = offer.quantityKg * offer.proposedPricePerKg;

    const big = Radius.circular(20);
    const tail = Radius.circular(6);

    String? delta;
    IconData? deltaIcon;
    if (previous != null) {
      final diff = offer.proposedPricePerKg - previous!.proposedPricePerKg;
      if (diff == 0) {
        delta = l10n.deal_detail_same_price;
        deltaIcon = LucideIcons.equal;
      } else {
        final sign = diff > 0 ? '+' : '−';
        delta = l10n.deal_detail_vs_previous(
          '$sign${CurrencyFormatters.formatCop(diff.abs())}',
        );
        deltaIcon = diff > 0
            ? LucideIcons.trendingUp
            : LucideIcons.trendingDown;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.only(
                topLeft: big,
                topRight: big,
                bottomLeft: isMine ? big : tail,
                bottomRight: isMine ? tail : big,
              ),
              border: Border.all(color: outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: soft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Text(
                      DateFormatters.formatOfferDateTime(offer.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: soft,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: CurrencyFormatters.formatCop(
                          offer.proposedPricePerKg,
                        ),
                        style: AppTextStyles.figureLarge.copyWith(
                          fontSize: 24,
                          color: ink,
                        ),
                      ),
                      TextSpan(
                        text: ' /kg',
                        style: AppTextStyles.bodySmall.copyWith(color: soft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: AppTextStyles.figureSmall.copyWith(color: soft),
                    children: [
                      TextSpan(
                        text: UnitFormatters.formatKg(offer.quantityKg),
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '  ·  '),
                      TextSpan(text: '${l10n.deal_detail_total} '),
                      TextSpan(
                        text: CurrencyFormatters.formatCop(subtotal),
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (delta != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deltaIcon, size: 13, color: soft),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          delta,
                          style: AppTextStyles.caption.copyWith(
                            color: soft,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.space8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(delivery.icon, size: 14, color: soft),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.deal_detail_delivery(
                          deliveryDisplayLabel(l10n, offer.deliveryMethod),
                        ),
                        style: AppTextStyles.bodySmall.copyWith(color: soft),
                      ),
                    ),
                  ],
                ),
                if (offer.message != null && offer.message!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      offer.message!,
                      style: AppTextStyles.bodyMedium.copyWith(color: ink),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Closes the thread while the other party holds the turn.
class _WaitingBubble extends StatelessWidget {
  final String message;

  const _WaitingBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    const big = Radius.circular(20);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: context.appSurfaceVariant,
          borderRadius: const BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomRight: big,
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.hourglass,
              size: 15,
              color: context.appTextSecondary,
            ),
            const SizedBox(width: AppDimensions.space8),
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Translucent bar pinned above the home indicator. The blur is the iOS
/// bar material: the thread stays faintly visible as it scrolls beneath,
/// while a 90% surface fill keeps every label at full contrast.
class _FrostedActionBar extends StatelessWidget {
  final List<Widget> children;

  const _FrostedActionBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: context.appDivider)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _DealSecondaryAction { counterOffer, reject }

/// Squircle trigger beside the primary button that opens the secondary
/// deal actions (counteroffer, reject) in an anchored menu.
class _DealMoreActionsButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onCounterOffer;
  final VoidCallback onReject;

  const _DealMoreActionsButton({
    required this.enabled,
    required this.onCounterOffer,
    required this.onReject,
  });

  static const double _size = AppDimensions.buttonHeightPrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AppDimensions.radiusControl);
    final destructive = context.appErrorText;

    PopupMenuItem<_DealSecondaryAction> item({
      required _DealSecondaryAction value,
      required IconData icon,
      required String label,
      required Color color,
      bool enabled = true,
      Key? key,
    }) {
      return PopupMenuItem<_DealSecondaryAction>(
        key: key,
        value: value,
        enabled: enabled,
        height: AppDimensions.buttonHeightMedium,
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconSM - 2, color: color),
            const SizedBox(width: AppDimensions.space12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<_DealSecondaryAction>(
      key: const ValueKey('deal_detail_more_actions_button'),
      enabled: enabled,
      tooltip: l10n.deal_detail_more_actions,
      position: PopupMenuPosition.over,
      offset: const Offset(0, -AppDimensions.space8),
      color: context.appSurface,
      surfaceTintColor: AppColors.transparent,
      elevation: 8,
      shadowColor: context.appShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(color: context.appBorder),
      ),
      onOpened: HapticFeedback.selectionClick,
      onSelected: (action) {
        switch (action) {
          case _DealSecondaryAction.counterOffer:
            onCounterOffer?.call();
          case _DealSecondaryAction.reject:
            onReject();
        }
      },
      itemBuilder: (context) => [
        item(
          key: const ValueKey('deal_detail_counter_offer_action'),
          value: _DealSecondaryAction.counterOffer,
          icon: LucideIcons.arrowLeftRight,
          label: l10n.deal_counter_offer,
          color: onCounterOffer == null
              ? context.appTextDisabled
              : context.appTextPrimary,
          enabled: onCounterOffer != null,
        ),
        item(
          key: const ValueKey('deal_detail_reject_action'),
          value: _DealSecondaryAction.reject,
          icon: LucideIcons.circleX,
          label: l10n.deal_reject_deal,
          color: destructive,
        ),
      ],
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurfaceVariant,
            borderRadius: radius,
            border: Border.all(
              color: context.appBorder,
              width: AppDimensions.borderWidthThin,
            ),
          ),
          child: Icon(
            LucideIcons.ellipsis,
            size: AppDimensions.iconSM,
            color: enabled ? context.appTextSecondary : context.appTextDisabled,
          ),
        ),
      ),
    );
  }
}

/// Contacts-style action tile: icon over a short label.
class _ContactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 20, color: context.appTextSecondary),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.appPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A contact detail the other party has kept private.
class _LockedRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LockedRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return InsetGroupRow(
      leading: IconSquircle(icon: icon, size: 30),
      title: text,
    );
  }
}

/// Placeholder rows while the authorized contact loads.
class _ContactSkeleton extends StatelessWidget {
  const _ContactSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppSkeletonBlock(width: 120, height: 10),
            SizedBox(height: 8),
            AppSkeletonBlock(width: 180, height: 22),
            SizedBox(height: 14),
            AppSkeletonBlock(height: 56, radius: 14),
          ],
        ),
      ),
    );
  }
}

/// Compact iOS progress HUD shown while a deal action is in flight.
class _ProgressHud extends StatelessWidget {
  const _ProgressHud();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appBorder),
          ),
          child: const CupertinoActivityIndicator(radius: 13),
        ),
      ),
    );
  }
}

/// Modal de calificación postventa. Mantiene el formulario abierto si el
/// envío falla para que el usuario pueda corregir o reintentar.
class _RatingSheet extends StatefulWidget {
  final String counterpartLabel;
  final Future<void> Function(int rating, String? comment) onSubmit;

  const _RatingSheet({required this.counterpartLabel, required this.onSubmit});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  int _previousRating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _select(int value) {
    if (_isSubmitting || value == _rating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _previousRating = _rating;
      _rating = value;
    });
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      final readable = message.isEmpty
          ? AppLocalizations.of(context)!.deal_detail_rate_error
          : message;
      setState(() {
        _isSubmitting = false;
        _errorMessage = readable;
      });
    }
  }

  String _ratingLabel(AppLocalizations l10n) => switch (_rating) {
    1 => l10n.deal_rating_label_1,
    2 => l10n.deal_rating_label_2,
    3 => l10n.deal_rating_label_3,
    4 => l10n.deal_rating_label_4,
    _ => l10n.deal_rating_label_5,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit = _rating >= 1 && _rating <= 5 && !_isSubmitting;

    return AppSheetFrame(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.space8),
          Center(child: IconSquircle(icon: LucideIcons.handshake, size: 56)),
          const SizedBox(height: AppDimensions.space16),
          Text(
            l10n.deal_detail_rate_title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 22,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            l10n.deal_detail_rate_subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: context.appSurfaceVariant,
                borderRadius: AppDimensions.borderRadiusFull,
              ),
              child: Text(
                '${l10n.deal_detail_rate_target}: ${widget.counterpartLabel}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          Semantics(
            label: l10n.deal_detail_rate_stars_label,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                final newlyFilled = value > _previousRating && value <= _rating;
                return _RatingStar(
                  key: ValueKey('rating_star_$value'),
                  value: value,
                  filled: value <= _rating,
                  popDelay: newlyFilled
                      ? const Duration(milliseconds: 40) *
                            (value - _previousRating - 1)
                      : Duration.zero,
                  enabled: !_isSubmitting,
                  onTap: () => _select(value),
                );
              }),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          SizedBox(
            height: 20,
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.quick),
              switchInCurve: AppMotion.easeOut,
              switchOutCurve: AppMotion.easeOut,
              child: Text(
                _rating == 0
                    ? l10n.deal_detail_rate_stars_required
                    : _ratingLabel(l10n),
                key: ValueKey(_rating),
                textAlign: TextAlign.center,
                style: _rating == 0
                    ? AppTextStyles.bodySmall.copyWith(
                        color: context.appTextSecondary,
                      )
                    : AppTextStyles.titleSmall.copyWith(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          CustomTextField(
            key: const ValueKey('rating_comment_field'),
            label: l10n.deal_detail_rate_comment_label,
            hint: l10n.deal_detail_rate_comment_hint,
            icon: LucideIcons.messageSquareText,
            controller: _commentController,
            isRequired: false,
            enabled: !_isSubmitting,
            maxLines: 3,
            maxLength: InputLimits.review,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppDimensions.space8),
            StatusBanner(tone: StatusTone.error, message: _errorMessage!),
          ],
        ],
      ),
      footer: ElevatedButton(
        key: const ValueKey('rating_submit_button'),
        onPressed: canSubmit ? _submit : null,
        child: _isSubmitting
            ? CupertinoActivityIndicator(color: context.appTextMuted)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.send, size: 18),
                  const SizedBox(width: AppDimensions.space8),
                  Text(l10n.deal_detail_rate_submit),
                ],
              ),
      ),
    );
  }
}

/// One star of the rating row. When it becomes filled it pops (1 → 1.22 →
/// 1) after [popDelay], so a multi-star pick sweeps left to right. The
/// delay lives inside the animation timeline, never in a timer.
class _RatingStar extends StatefulWidget {
  final int value;
  final bool filled;
  final Duration popDelay;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingStar({
    super.key,
    required this.value,
    required this.filled,
    required this.popDelay,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_RatingStar> createState() => _RatingStarState();
}

class _RatingStarState extends State<_RatingStar>
    with SingleTickerProviderStateMixin {
  static const Duration _pop = Duration(milliseconds: 260);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pop,
    value: 1,
  );
  Duration _delay = Duration.zero;

  @override
  void didUpdateWidget(covariant _RatingStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.filled && widget.filled && !AppMotion.reduced(context)) {
      _delay = widget.popDelay;
      _controller.duration = _delay + _pop;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scaleAt(double progress) {
    final total = _controller.duration!.inMicroseconds;
    final start = total == 0 ? 0.0 : _delay.inMicroseconds / total;
    if (progress <= start) return 1;
    final t = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
    if (t < 0.4) {
      return 1 + 0.22 * AppMotion.easeOut.transform(t / 0.4);
    }
    return 1.22 - 0.22 * Curves.easeInOut.transform((t - 0.4) / 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.filled
        ? context.appRatingGold
        : context.appTextMuted.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      selected: widget.filled,
      label: '${widget.value}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: SizedBox.square(
          dimension: 54,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _scaleAt(_controller.value),
              child: child,
            ),
            child: Icon(
              widget.filled ? CupertinoIcons.star_fill : CupertinoIcons.star,
              size: 40,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared anatomy of the two consent sheets, laid out like an iOS
/// Settings page: a shield and title, the optional terms being accepted,
/// then the two sharing switches as one inset grouped list with a single
/// footnote.
class _ConsentBody extends StatelessWidget {
  final String title;
  final Widget? summary;
  final bool isBuyer;
  final bool sharePhone;
  final bool shareLocation;
  final ValueChanged<bool> onPhoneChanged;
  final ValueChanged<bool> onLocationChanged;

  const _ConsentBody({
    required this.title,
    this.summary,
    required this.isBuyer,
    required this.sharePhone,
    required this.shareLocation,
    required this.onPhoneChanged,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget toggle(bool value, ValueChanged<bool> onChanged) => CupertinoSwitch(
      value: value,
      onChanged: (next) {
        HapticFeedback.selectionClick();
        onChanged(next);
      },
      activeTrackColor: context.appPrimary,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const IconSquircle(icon: LucideIcons.shieldCheck, size: 36),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ),
          ],
        ),
        if (summary != null) ...[
          const SizedBox(height: AppDimensions.space16),
          summary!,
        ],
        const SizedBox(height: AppDimensions.space20),
        InsetGroupSection(
          footer: l10n.deal_detail_privacy_note,
          dividerIndent: 58,
          children: [
            InsetGroupRow(
              leading: const IconSquircle(
                icon: LucideIcons.messageCircle,
                size: 30,
              ),
              title: l10n.deal_detail_share_whatsapp,
              trailing: toggle(sharePhone, onPhoneChanged),
            ),
            InsetGroupRow(
              leading: const IconSquircle(icon: LucideIcons.mapPin, size: 30),
              title: isBuyer
                  ? l10n.deal_detail_share_delivery_location_short
                  : l10n.deal_detail_share_farm_location_short,
              trailing: toggle(shareLocation, onLocationChanged),
            ),
          ],
        ),
      ],
    );
  }
}

/// BottomSheet para confirmar la aceptación de una oferta y configurar el consentimiento inicial.
class _AcceptOfferConsentSheet extends StatefulWidget {
  final NegotiationModel negotiation;
  final NegotiationOfferModel? latestOffer;
  final bool isBuyer;
  final Function(bool sharePhone, bool shareLocation) onConfirm;

  const _AcceptOfferConsentSheet({
    required this.negotiation,
    required this.latestOffer,
    required this.isBuyer,
    required this.onConfirm,
  });

  @override
  State<_AcceptOfferConsentSheet> createState() =>
      _AcceptOfferConsentSheetState();
}

class _AcceptOfferConsentSheetState extends State<_AcceptOfferConsentSheet> {
  bool _sharePhone = false;
  bool _shareLocation = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offer = widget.latestOffer;

    return AppSheetFrame(
      body: _ConsentBody(
        title: l10n.deal_detail_accept_terms_title,
        summary: offer == null ? null : _AcceptedTermsStrip(offer: offer),
        isBuyer: widget.isBuyer,
        sharePhone: _sharePhone,
        shareLocation: _shareLocation,
        onPhoneChanged: (val) => setState(() => _sharePhone = val),
        onLocationChanged: (val) => setState(() => _shareLocation = val),
      ),
      footer: Row(
        children: [
          Expanded(
            flex: 2,
            child: SecondaryActionButton(
              onPressed: () => Navigator.pop(context),
              text: l10n.common_cancel,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            flex: 3,
            child: PrimaryActionButton(
              onPressed: () => widget.onConfirm(_sharePhone, _shareLocation),
              text: l10n.deal_detail_confirm_agreement,
            ),
          ),
        ],
      ),
    );
  }
}

/// The terms being accepted, restated before the user commits.
class _AcceptedTermsStrip extends StatelessWidget {
  final NegotiationOfferModel offer;

  const _AcceptedTermsStrip({required this.offer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _TermFigure(
                label: l10n.deal_detail_price_per_kg,
                value: CurrencyFormatters.formatCop(offer.proposedPricePerKg),
                emphasized: true,
              ),
            ),
            VerticalDivider(width: 20, color: context.appBorder),
            Expanded(
              child: _TermFigure(
                label: l10n.deal_detail_quantity,
                value: UnitFormatters.formatKg(offer.quantityKg),
              ),
            ),
            VerticalDivider(width: 20, color: context.appBorder),
            Expanded(
              child: _TermFigure(
                label: l10n.deal_detail_total,
                value: CurrencyFormatters.formatCop(
                  offer.quantityKg * offer.proposedPricePerKg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet para consultar y modificar los permisos de consentimiento propios
/// durante una negociación en estado acordada.
class _EditConsentSheet extends StatefulWidget {
  final bool initialSharePhone;
  final bool initialShareLocation;
  final bool isBuyer;
  final Function(bool sharePhone, bool shareLocation) onSave;

  const _EditConsentSheet({
    required this.initialSharePhone,
    required this.initialShareLocation,
    required this.isBuyer,
    required this.onSave,
  });

  @override
  State<_EditConsentSheet> createState() => _EditConsentSheetState();
}

class _EditConsentSheetState extends State<_EditConsentSheet> {
  late bool _sharePhone;
  late bool _shareLocation;

  @override
  void initState() {
    super.initState();
    _sharePhone = widget.initialSharePhone;
    _shareLocation = widget.initialShareLocation;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppSheetFrame(
      body: _ConsentBody(
        title: l10n.deal_detail_my_permissions_title,
        isBuyer: widget.isBuyer,
        sharePhone: _sharePhone,
        shareLocation: _shareLocation,
        onPhoneChanged: (val) => setState(() => _sharePhone = val),
        onLocationChanged: (val) => setState(() => _shareLocation = val),
      ),
      footer: Row(
        children: [
          Expanded(
            flex: 2,
            child: SecondaryActionButton(
              onPressed: () => Navigator.pop(context),
              text: l10n.common_cancel,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            flex: 3,
            child: PrimaryActionButton(
              onPressed: () => widget.onSave(_sharePhone, _shareLocation),
              text: l10n.common_save_changes,
            ),
          ),
        ],
      ),
    );
  }
}
