import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_photo_placeholder.dart';
import '../widgets/crop_status_badge.dart';
import '../widgets/make_offer_sheet.dart';
import 'publish_crop_screen.dart';
import '../../deals/services/negotiation_service.dart';
import '../../deals/screens/deals_screen.dart';
import '../../profile/models/farmer_profile_data.dart';
import '../../profile/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/badges/media_capsule.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/loading/app_skeleton.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../../geo/models/simulated_location.dart';
import '../../geo/services/geo_simulation_service.dart';
import '../../../core/utils/app_formatters.dart';
import '../widgets/unit_equivalences_sheet.dart';
import '../../costs/models/regional_price_reference.dart';
import '../../costs/data/simulated_regional_price_references.dart';
import '../../costs/services/regional_price_reference_service.dart';

class CropDetailScreen extends StatefulWidget {
  final CropModel crop;
  final String? role;
  final bool? isOwner;
  final FarmerProfileData? initialFarmerProfile;
  final DistanceEvaluation? initialDistanceEvaluation;
  final FarmerProfileData? initialBuyerProfile;
  final NegotiationService? negotiationService;
  final CropService? cropService;
  final ProfileService? profileService;
  final RegionalPriceReferenceService? regionalReferenceService;
  final RegionalPriceReference? initialRegionalReference;

  const CropDetailScreen({
    super.key,
    required this.crop,
    this.role,
    this.isOwner,
    this.initialFarmerProfile,
    this.initialDistanceEvaluation,
    this.initialBuyerProfile,
    this.negotiationService,
    this.cropService,
    this.profileService,
    this.regionalReferenceService,
    this.initialRegionalReference,
  });

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  late CropModel _crop;
  late final CropService _cropService;
  late final ProfileService _profileService;
  late final PageController _pageController;
  late final RegionalPriceReferenceService _referenceService;
  RegionalPriceReference? _regionalReference;
  int _currentImageIndex = 0;
  FarmerProfileData? _farmerProfile;
  DistanceEvaluation? _distanceEvaluation;
  bool _isLoading = false;
  String? _currentUserRole;

  bool get _isBuyer {
    final effectiveRole = widget.role ?? _currentUserRole;
    if (effectiveRole != null && effectiveRole.trim().isNotEmpty) {
      return UserRole.isBuyerRole(effectiveRole);
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.id != _crop.farmerId) {
      return true;
    }
    return false;
  }

  bool get _isOwner {
    if (widget.isOwner != null) return widget.isOwner!;
    if (_isBuyer) return false;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return user.id == _crop.farmerId;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _crop = widget.crop;
    _cropService = widget.cropService ?? CropService();
    _profileService = widget.profileService ?? ProfileService();
    _pageController = PageController();
    _farmerProfile = widget.initialFarmerProfile;
    _distanceEvaluation = widget.initialDistanceEvaluation;

    _referenceService =
        widget.regionalReferenceService ?? RegionalPriceReferenceService();
    _regionalReference =
        widget.initialRegionalReference ??
        SimulatedRegionalPriceReferences.findForCrop(
          cropType: _crop.cropType,
          title: _crop.title,
        );
    _loadRegionalReference();

    if (widget.role == null) {
      _loadCurrentUserRole();
    }

    if (_isBuyer) {
      if (_distanceEvaluation == null) {
        _resolveDistanceEvaluation(initialBuyer: widget.initialBuyerProfile);
      }
      if (_farmerProfile == null) {
        _loadFarmerProfile();
      }
    }
  }

  Future<void> _loadRegionalReference() async {
    try {
      final ref = await _referenceService.findForCrop(
        cropType: _crop.cropType,
        title: _crop.title,
      );
      if (mounted && ref != null) {
        setState(() {
          _regionalReference = ref;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        final role = profileRes?['role'] as String?;
        if (mounted && role != null) {
          setState(() {
            _currentUserRole = role;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _resolveDistanceEvaluation({
    FarmerProfileData? initialBuyer,
  }) async {
    if (_distanceEvaluation != null && _distanceEvaluation!.hasValidDistance) {
      return;
    }
    try {
      FarmerProfileData? buyer = initialBuyer;
      if (buyer == null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.id != _crop.farmerId) {
          buyer = await _profileService.getFarmerProfileData(user.id);
        }
      }
      if (buyer != null && buyer.id != _crop.farmerId) {
        final eval = GeoSimulationService.evaluateBuyerProfileToCrop(
          buyerProfile: buyer,
          crop: _crop,
          farmerProfile: _farmerProfile,
        );
        if (mounted && eval.hasValidDistance) {
          setState(() {
            _distanceEvaluation = eval;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFarmerProfile() async {
    try {
      final profile = await _profileService.getFarmerProfileData(
        _crop.farmerId,
      );
      if (mounted) {
        setState(() => _farmerProfile = profile);
        if (_isBuyer &&
            (_distanceEvaluation == null ||
                !_distanceEvaluation!.hasValidDistance)) {
          _resolveDistanceEvaluation(initialBuyer: widget.initialBuyerProfile);
        }
      }
    } catch (_) {
      // Si falla la carga del perfil del agricultor, se usa la información básica de la cosecha
    }
  }

  String _formatEstimatedDistance(
    AppLocalizations l10n,
    DistanceEvaluation eval,
  ) {
    final km = eval.distanceKm;
    if (km == null || km < 0) return l10n.common_not_available;
    if (km < 1.0) return l10n.crop_detail_less_than_km;
    return l10n.crop_detail_km(km.round().toString());
  }

  void _showEquivalencesModal(BuildContext context) {
    if (!_isBuyer) return;
    final reference = _crop.availableStock;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.transparent,
      builder: (ctx) =>
          UnitEquivalencesSheet(referenceKg: reference, cropTitle: _crop.title),
    );
  }

  Future<void> _updateStatus(CropStatus newStatus) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crop_detail_owner_edit_denied),
          backgroundColor: context.appError,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _cropService.updateCropStatus(_crop.id, newStatus);
      setState(() {
        _crop = _crop.copyWith(status: newStatus, updatedAt: DateTime.now());
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.crop_detail_status_updated),
            backgroundColor: context.appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.crop_detail_error(e.toString())),
            backgroundColor: context.appError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEdit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crop_detail_other_edit_denied),
          backgroundColor: context.appError,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublishCropScreen(
          cropToEdit: _crop,
          cropService: _cropService,
          role: widget.role ?? _currentUserRole,
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crop_detail_other_delete_denied),
          backgroundColor: context.appError,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.crop_detail_confirm_delete_title),
        content: Text(l10n.crop_detail_confirm_delete_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.profile_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.crop_detail_delete_tooltip),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _cropService.deleteCrop(_crop.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.crop_detail_delete_success),
              backgroundColor: context.appSuccess,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.crop_detail_delete_error}: $e'),
              backgroundColor: context.appError,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openMakeOfferSheet() async {
    final l10n = AppLocalizations.of(context)!;

    // 0. Validar que no sea el productor dueño
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crop_detail_own_offer_error),
          backgroundColor: context.appWarning,
        ),
      );
      return;
    }

    // 1. Validar que la cosecha tenga stock disponible
    if (_crop.availableStock <= 0 || _crop.status == CropStatus.agotada) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crop_detail_out_of_stock),
          backgroundColor: context.appWarning,
        ),
      );
      return;
    }

    // 2. Validar estado de verificación comercial del usuario autenticado
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('verification_status')
            .eq('id', user.id)
            .maybeSingle();

        if (profileRes != null) {
          final status = UserVerificationStatus.fromString(
            profileRes['verification_status'] as String?,
          );

          if (!status.isApproved && mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.crop_unapproved_dialog_title),
                content: Text(l10n.crop_unapproved_dialog_desc),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.crop_unapproved_dialog_action),
                  ),
                ],
              ),
            );
            return;
          }
        }
      } catch (_) {
        // En caso de que no haya conexión de red para verificar, el backend volverá a validar
      }
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.transparent,
      builder: (context) => MakeOfferSheet(
        crop: _crop,
        negotiationService: widget.negotiationService,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.crop_detail_offer_sent),
          action: SnackBarAction(
            label: l10n.crop_detail_view_deals,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DealsScreen(
                    role: 'comprador',
                    service: widget.negotiationService,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showOfferBar = _isBuyer && !_isLoading;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(l10n.crop_detail_title),
        actions: _isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: context.appError,
                  onPressed: _confirmDelete,
                  tooltip: l10n.crop_detail_delete_tooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEdit,
                  tooltip: l10n.crop_detail_edit_tooltip,
                ),
                const SizedBox(width: AppDimensions.space4),
              ]
            : const [],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 12))
          : SingleChildScrollView(
              physics: AppMotion.scrollPhysics,
              padding: const EdgeInsets.only(bottom: AppDimensions.space32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageGallery(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitleBlock(context),
                        const SizedBox(height: AppDimensions.space20),
                        _buildPriceCard(context, l10n),
                        const SizedBox(height: AppDimensions.space12),
                        _buildStockGroup(context, l10n),
                        if (_regionalReference != null) ...[
                          const SizedBox(height: AppDimensions.space12),
                          _buildRegionalReferenceBanner(context),
                        ],
                        const SizedBox(height: AppDimensions.space12),
                        _buildDateTiles(context, l10n),
                        if (_crop.isEarlySale) ...[
                          const SizedBox(height: AppDimensions.space12),
                          _buildEarlySaleCard(context, l10n),
                        ],
                        if (_crop.description.trim().isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.space24),
                          _buildSectionLabel(
                            context,
                            l10n.crop_detail_description,
                          ),
                          Text(
                            _crop.description,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: context.appTextPrimary,
                            ),
                          ),
                        ],
                        if (_isBuyer) ...[
                          const SizedBox(height: AppDimensions.space24),
                          _buildFarmerInfoCard(context, l10n),
                        ],
                        const SizedBox(height: AppDimensions.space24),
                        _buildActions(context, l10n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: showOfferBar ? _buildOfferBar(context, l10n) : null,
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text, {Key? key}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.space8),
      child: Text(
        text,
        key: key,
        style: AppTextStyles.titleMedium.copyWith(
          color: context.appTextPrimary,
        ),
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _crop.title,
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Row(
          children: [
            Flexible(
              child: Text(
                _crop.cropType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            CropStatusBadge(status: _crop.status),
          ],
        ),
      ],
    );
  }

  /// The two numbers a buyer weighs together: price per kilogram as the
  /// hero figure, and the kilograms available right under it, where the
  /// equivalences pill converts them.
  Widget _buildPriceCard(BuildContext context, AppLocalizations l10n) {
    return InsetGroupCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: _buildPriceFigure(context, l10n),
          ),
          Divider(height: 1, indent: 16, color: context.appDivider),
          _buildInfoRow(
            context,
            LucideIcons.package,
            l10n.crop_detail_available_stock,
            UnitFormatters.formatKgWithEquivalence(_crop.availableStock),
            onTap: _isBuyer ? () => _showEquivalencesModal(context) : null,
            footer: _isBuyer ? _buildEquivalencesPill(context, l10n) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFigure(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.crop_detail_price_per_kg,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.space4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              CurrencyFormatters.formatCop(_crop.pricePerKg),
              style: AppTextStyles.figureLarge.copyWith(
                fontSize: 30,
                letterSpacing: -0.8,
                color: context.appPrimary,
              ),
            ),
            const SizedBox(width: AppDimensions.space4),
            Text(
              '/ kg',
              style: AppTextStyles.titleMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Minimum order, location and distance as an iOS inset-grouped list.
  Widget _buildStockGroup(BuildContext context, AppLocalizations l10n) {
    final hasDistance =
        _distanceEvaluation != null && _distanceEvaluation!.hasValidDistance;

    final rows = <Widget>[
      _buildInfoRow(
        context,
        LucideIcons.packageCheck,
        l10n.crop_detail_min_order,
        UnitFormatters.formatKg(_crop.minOrderKg),
      ),
      _buildInfoRow(
        context,
        LucideIcons.mapPin,
        l10n.crop_detail_location,
        hasDistance
            ? '${_crop.municipality}, ${_crop.department} (${_distanceEvaluation!.formatted})'
            : '${_crop.municipality}, ${_crop.department}',
      ),
      if (_isBuyer && hasDistance)
        _buildInfoRow(
          context,
          LucideIcons.navigation,
          l10n.crop_detail_estimated_distance,
          _formatEstimatedDistance(l10n, _distanceEvaluation!),
        ),
    ];

    return InsetGroupCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 48, color: context.appDivider),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _buildEquivalencesPill(BuildContext context, AppLocalizations l10n) {
    final triad = context.appBrandTriad;
    return Align(
      alignment: Alignment.centerLeft,
      child: PressableScale(
        child: Material(
          color: triad.background,
          shape: StadiumBorder(side: BorderSide(color: triad.border)),
          child: InkWell(
            key: const Key('crop_detail_equivalences_button'),
            customBorder: const StadiumBorder(),
            onTap: () => _showEquivalencesModal(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.scale, size: 15, color: triad.foreground),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.crop_detail_equivalences_pill,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: triad.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Publication and harvest dates side by side. The harvest tile is amber
  /// so a future date can never be mistaken for the listing date.
  Widget _buildDateTiles(BuildContext context, AppLocalizations l10n) {
    final harvest = _crop.estimatedHarvestDate;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _DateTile(
              icon: LucideIcons.calendar,
              label: l10n.crop_detail_publication_date,
              value: DateFormatters.formatMediumDate(_crop.createdAt),
              triad: AppSemanticTriad(
                background: context.appSurface,
                border: context.appBorder,
                foreground: context.appTextSecondary,
              ),
            ),
          ),
          if (harvest != null) ...[
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _DateTile(
                icon: LucideIcons.calendarClock,
                label: l10n.crop_detail_estimated_harvest,
                value: DateFormatters.formatHarvestDateLong(harvest),
                triad: context.appWarningTriad,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarlySaleCard(BuildContext context, AppLocalizations l10n) {
    final triad = context.appBrandTriad;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: triad.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sprout, size: 18, color: triad.foreground),
              const SizedBox(width: AppDimensions.space8),
              Text(
                l10n.crop_detail_early_sale,
                style: AppTextStyles.titleMedium.copyWith(
                  color: triad.foreground,
                ),
              ),
            ],
          ),
          if (_crop.estimatedYieldKg != null) ...[
            const SizedBox(height: AppDimensions.space8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.crop_detail_estimated_yield,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                Text(
                  UnitFormatters.formatKgWithEquivalence(
                    _crop.estimatedYieldKg,
                  ),
                  style: AppTextStyles.figureSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    if (_isOwner) {
      final warning = context.appWarningTriad;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel(context, l10n.crop_detail_quick_actions),
          if (_crop.status == CropStatus.activa)
            ElevatedButton.icon(
              onPressed: () => _updateStatus(CropStatus.pausada),
              icon: const Icon(LucideIcons.pause, size: 18),
              label: Text(l10n.crop_detail_pause_crop),
              style: ElevatedButton.styleFrom(
                backgroundColor: warning.background,
                foregroundColor: warning.text,
                side: BorderSide(color: warning.border),
              ),
            )
          else if (_crop.status == CropStatus.pausada ||
              _crop.status == CropStatus.borrador)
            ElevatedButton.icon(
              onPressed: () => _updateStatus(CropStatus.activa),
              icon: const Icon(LucideIcons.play, size: 18),
              label: Text(l10n.crop_detail_activate_crop),
            ),
          const SizedBox(height: AppDimensions.space12),
          OutlinedButton.icon(
            key: const Key('crop_detail_farmer_negotiations_button'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DealsScreen(
                    role: 'agricultor',
                    service: widget.negotiationService,
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.handshake, size: 18),
            label: Text(l10n.crop_detail_view_negotiations),
          ),
        ],
      );
    }

    if (_isBuyer) {
      return OutlinedButton.icon(
        key: const Key('crop_detail_equivalences_action_button'),
        onPressed: () => _showEquivalencesModal(context),
        icon: const Icon(LucideIcons.scale, size: 18),
        label: Text(l10n.crop_detail_view_equivalences),
      );
    }

    return const SizedBox.shrink();
  }

  /// Frosted bar that keeps the buyer's primary action in reach while the
  /// lot details scroll underneath.
  Widget _buildOfferBar(BuildContext context, AppLocalizations l10n) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: context.appBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ElevatedButton.icon(
                onPressed: _openMakeOfferSheet,
                icon: const Icon(LucideIcons.handshake, size: 20),
                label: Text(l10n.crop_detail_make_offer),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    if (_crop.imageUrls.isEmpty) {
      return _buildImageFallback(context);
    }

    if (_crop.imageUrls.length == 1) {
      final url = _cropService.getPublicImageUrl(_crop.imageUrls.first);
      return SizedBox(
        height: _galleryHeight,
        width: double.infinity,
        child: _buildNetworkPhoto(context, url),
      );
    }

    final count = _crop.imageUrls.length;
    return Column(
      children: [
        SizedBox(
          height: _galleryHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: count,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final url = _cropService.getPublicImageUrl(
                    _crop.imageUrls[index],
                  );
                  return _buildNetworkPhoto(context, url);
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: MediaCapsule.custom(
                  key: const Key('crop_gallery_indicator'),
                  child: Text(
                    '${_currentImageIndex + 1} / $count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onBrand,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: MediaCapsule.custom(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < count; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              right: i == count - 1 ? 0 : 6,
                            ),
                            child: _PageDot(active: i == _currentImageIndex),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          key: const Key('crop_gallery_thumbnails'),
          height: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(bottom: BorderSide(color: context.appBorder)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppDimensions.paddingScreenHorizontal,
            itemCount: count,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppDimensions.space8),
            itemBuilder: (context, index) {
              final isSelected = index == _currentImageIndex;
              final url = _cropService.getPublicImageUrl(
                _crop.imageUrls[index],
              );

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: AppMotion.of(context, AppMotion.emphasized),
                    curve: AppMotion.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.standard),
                  curve: AppMotion.easeOut,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? context.appPrimary
                          : context.appBorder,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: context.appSurfaceVariant,
                        child: Icon(
                          LucideIcons.imageOff,
                          size: 18,
                          color: context.appTextMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static const double _galleryHeight = 280;

  /// Network photo that shimmers while loading and fades in on its first
  /// frame.
  Widget _buildNetworkPhoto(BuildContext context, String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          _buildImageFallback(context),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const AppShimmer(
          child: AppSkeletonBlock(height: _galleryHeight, radius: 0),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.easeOut,
          child: child,
        );
      },
    );
  }

  Widget _buildImageFallback(BuildContext context) {
    return const SizedBox(
      height: 180,
      width: double.infinity,
      child: CropPhotoPlaceholder(iconSize: 44),
    );
  }

  /// Market intelligence card: how the asking price sits against the
  /// Nariño regional index. Informational blue, never alarm colors.
  Widget _buildRegionalReferenceBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ref = _regionalReference!;
    final diff = _crop.pricePerKg - ref.referencePricePerKg;
    final diffPercent = ref.referencePricePerKg > 0
        ? (diff / ref.referencePricePerKg) * 100
        : 0.0;
    // Both the amount and the percentage are shown unsigned with one shared
    // sign, so a price under the index reads "-\$ 700/kg (-15.6%)".
    final sign = diff > 0 ? '+' : '-';
    final comparisonText = diff == 0
        ? l10n.crop_detail_price_matches_reference(
            CurrencyFormatters.formatCop(ref.referencePricePerKg),
          )
        : l10n.crop_detail_price_vs_reference(
            sign,
            CurrencyFormatters.formatCop(diff.abs()),
            diffPercent.abs().toStringAsFixed(1),
            CurrencyFormatters.formatCop(ref.referencePricePerKg),
          );
    final info = context.appInfoTriad;

    return Container(
      key: const Key('crop_detail_regional_reference_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                icon: LucideIcons.trendingUp,
                triad: AppSemanticTriad(
                  background: context.appSurface,
                  border: info.border,
                  foreground: info.foreground,
                ),
                size: 36,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  l10n.crop_detail_regional_index_title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              _InfoTag(label: l10n.common_simulated, triad: info),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            comparisonText,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            l10n.profitability_reference_notice,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfoCard(BuildContext context, AppLocalizations l10n) {
    final producerName = _farmerProfile?.fullName.isNotEmpty == true
        ? _farmerProfile!.fullName
        : l10n.crop_detail_producer_with_location(
            l10n.crop_detail_producer,
            _crop.municipality,
          );

    final avatarUrl =
        _farmerProfile?.profilePath != null &&
            _farmerProfile!.profilePath!.isNotEmpty
        ? _profileService.getPublicProfileImageUrl(_farmerProfile!.profilePath!)
        : null;
    final showPhone =
        _farmerProfile?.settings.sharePhone == true &&
        _farmerProfile?.phone != null &&
        _farmerProfile!.phone.isNotEmpty;

    return InsetGroupCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: avatarUrl,
                  radius: 24,
                  backgroundColor: context.appPrimarySoft,
                  borderColor: context.appBrandTriad.border,
                  iconColor: context.appOnPrimarySoft,
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.crop_detail_farmer_info,
                        style: AppTextStyles.caption.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        producerName,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showPhone) ...[
            Divider(height: 1, indent: 16, color: context.appDivider),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.phone, size: 16, color: context.appPrimary),
                  const SizedBox(width: AppDimensions.space12),
                  Text(
                    _farmerProfile!.phone,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: context.appTextPrimary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    Widget? footer,
  }) {
    final rowContent = Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: context.appTextSecondary),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.figureSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppDimensions.space12),
            Padding(padding: const EdgeInsets.only(left: 32), child: footer),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: rowContent);
    }
    return rowContent;
  }
}

/// iOS page control dot: fixed size, only the fill changes, so paging
/// never shifts the row.
class _PageDot extends StatelessWidget {
  final bool active;

  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: active
            ? AppColors.onBrand
            : AppColors.onBrand.withValues(alpha: 0.42),
      ),
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.easeOut,
      builder: (context, color, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppSemanticTriad triad;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.triad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: triad.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: triad.foreground),
          const SizedBox(height: AppDimensions.space8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: triad.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appTextPrimary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final AppSemanticTriad triad;

  const _InfoTag({required this.label, required this.triad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: triad.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: triad.text,
        ),
      ),
    );
  }
}
