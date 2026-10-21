import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_status_badge.dart';
import '../widgets/make_offer_sheet.dart';
import 'publish_crop_screen.dart';
import '../../deals/services/negotiation_service.dart';
import '../../deals/screens/deals_screen.dart';
import '../../profile/models/farmer_profile_data.dart';
import '../../profile/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
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

  String _formatEstimatedDistance(AppLocalizations l10n, DistanceEvaluation eval) {
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(l10n.crop_detail_title),
        actions: _isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDelete,
                  tooltip: l10n.crop_detail_delete_tooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEdit,
                  tooltip: l10n.crop_detail_edit_tooltip,
                ),
              ]
            : const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Galería de imágenes
                  _buildImageGallery(context),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título y Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _crop.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.appTextPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CropStatusBadge(status: _crop.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _crop.cropType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _crop.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: context.appTextPrimary,
                          ),
                        ),

                        Divider(
                          height: 32,
                          color: context.appDivider,
                        ),

                        // Datos de precio y existencias
                        _buildInfoRow(
                          context,
                          l10n.crop_detail_price_per_kg,
                          CurrencyFormatters.formatCop(_crop.pricePerKg),
                        ),
                        if (_regionalReference != null) ...[
                          const SizedBox(height: 4),
                          _buildRegionalReferenceBanner(context),
                          const SizedBox(height: 8),
                        ],
                        _buildInfoRow(
                          context,
                          l10n.crop_detail_available_stock,
                          UnitFormatters.formatKgWithEquivalence(
                            _crop.availableStock,
                          ),
                          onTap: _isBuyer
                              ? () => _showEquivalencesModal(context)
                              : null,
                        ),
                        if (_isBuyer)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                              bottom: 8.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                key: const Key(
                                  'crop_detail_equivalences_button',
                                ),
                                onPressed: () =>
                                    _showEquivalencesModal(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.appPrimary,
                                  backgroundColor: context.appPrimary
                                      .withValues(alpha: 0.08),
                                  side: BorderSide(
                                    color: context.appPrimary
                                        .withValues(alpha: 0.8),
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  Icons.calculate_outlined,
                                  size: 18,
                                  color: context.appPrimary,
                                ),
                                label: Text(
                                  l10n.crop_detail_view_equivalences,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.appPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildInfoRow(
                          context,
                          l10n.crop_detail_min_order,
                          UnitFormatters.formatKg(_crop.minOrderKg),
                        ),
                        _buildInfoRow(
                          context,
                          l10n.crop_detail_location,
                          _distanceEvaluation != null &&
                                  _distanceEvaluation!.hasValidDistance
                              ? '${_crop.municipality}, ${_crop.department} (${_distanceEvaluation!.formatted})'
                              : '${_crop.municipality}, ${_crop.department}',
                        ),
                        if (_isBuyer &&
                            _distanceEvaluation != null &&
                            _distanceEvaluation!.hasValidDistance)
                          _buildInfoRow(
                            context,
                            l10n.crop_detail_estimated_distance,
                            _formatEstimatedDistance(
                              l10n,
                              _distanceEvaluation!,
                            ),
                          ),
                        _buildInfoRow(
                          context,
                          l10n.crop_detail_publication_date,
                          DateFormatters.formatMediumDate(_crop.createdAt),
                        ),
                        if (!_crop.isEarlySale &&
                            _crop.estimatedHarvestDate != null)
                          _buildInfoRow(
                            context,
                            l10n.crop_detail_estimated_harvest,
                            DateFormatters.formatHarvestDateLong(
                              _crop.estimatedHarvestDate,
                            ),
                          ),

                        if (_crop.isEarlySale) ...[
                          Divider(
                            height: 32,
                            color: context.appDivider,
                          ),
                          Text(
                            l10n.crop_detail_early_sale,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_crop.estimatedHarvestDate != null)
                            _buildInfoRow(
                              context,
                              l10n.crop_detail_estimated_harvest,
                              DateFormatters.formatHarvestDateLong(
                                _crop.estimatedHarvestDate,
                              ),
                            ),
                          if (_crop.estimatedYieldKg != null)
                            _buildInfoRow(
                              context,
                              l10n.crop_detail_estimated_yield,
                              UnitFormatters.formatKgWithEquivalence(
                                _crop.estimatedYieldKg,
                              ),
                            ),
                        ],

                        // Sección de información del Productor (para compradores)
                        if (_isBuyer) ...[
                          Divider(
                            height: 32,
                            color: context.appDivider,
                          ),
                          _buildFarmerInfoCard(context, l10n),
                        ],

                        // Sección de Acciones
                        Divider(
                          height: 32,
                          color: context.appDivider,
                        ),
                        Text(
                          l10n.crop_detail_quick_actions,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Si es agricultor dueño: Pausar/Activar y Ver Negociaciones
                        if (_isOwner) ...[
                          if (_crop.status == CropStatus.activa)
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _updateStatus(CropStatus.pausada),
                              icon: const Icon(Icons.pause),
                              label: Text(l10n.crop_detail_pause_crop),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.appWarning,
                                foregroundColor: context.appOnPrimary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          else if (_crop.status == CropStatus.pausada ||
                              _crop.status == CropStatus.borrador)
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(CropStatus.activa),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n.crop_detail_activate_crop),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.appSuccess,
                                foregroundColor: context.appOnPrimary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const Key(
                              'crop_detail_farmer_negotiations_button',
                            ),
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
                            icon: const Icon(Icons.handshake),
                            label: Text(l10n.crop_detail_view_negotiations),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        // Si es comprador: Hacer oferta / Negociar y Ver equivalencias
                        if (_isBuyer) ...[
                          ElevatedButton.icon(
                            onPressed: _openMakeOfferSheet,
                            icon: const Icon(Icons.handshake_outlined),
                            label: Text(
                              l10n.crop_detail_make_offer,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appPrimary,
                              foregroundColor: context.appOnPrimary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key(
                              'crop_detail_equivalences_action_button',
                            ),
                            onPressed: () => _showEquivalencesModal(context),
                            icon: Icon(
                              Icons.scale_outlined,
                              color: context.appPrimary,
                            ),
                            label: Text(
                              l10n.crop_detail_view_equivalences,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.appPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color: context.appPrimary
                                    .withValues(alpha: 0.8),
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
        height: 250,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImageFallback(context),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              color: context.appSurfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _crop.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final url = _cropService.getPublicImageUrl(
                    _crop.imageUrls[index],
                  );
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildImageFallback(context),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: context.appSurfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  key: const Key('crop_gallery_indicator'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appShadow.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${_crop.imageUrls.length}',
                    style: TextStyle(
                      color: context.appOverlayText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: List.generate(_crop.imageUrls.length, (index) {
                    final isSelected = index == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: isSelected ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.appOverlayText
                            : context.appOverlayText.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        Container(
          key: const Key('crop_gallery_thumbnails'),
          height: 64,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: context.appSurface,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _crop.imageUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == _currentImageIndex;
              final url = _cropService.getPublicImageUrl(
                _crop.imageUrls[index],
              );
              final borderColor = isSelected
                  ? context.appPrimary
                  : AppColors.transparent;

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: context.appSurfaceVariant,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                          color: context.appTextDisabled,
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

  Widget _buildImageFallback(BuildContext context) {
    return Container(
      height: 200,
      color: context.appSurfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: context.appTextDisabled,
        ),
      ),
    );
  }

  Widget _buildRegionalReferenceBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ref = _regionalReference!;
    final diff = _crop.pricePerKg - ref.referencePricePerKg;
    final diffPercent = ref.referencePricePerKg > 0
        ? (diff / ref.referencePricePerKg) * 100
        : 0.0;
    final sign = diff > 0 ? '+' : '';
    final comparisonText = diff == 0
        ? l10n.crop_detail_price_matches_reference(
            CurrencyFormatters.formatCop(ref.referencePricePerKg),
          )
        : l10n.crop_detail_price_vs_reference(
            sign,
            CurrencyFormatters.formatCop(diff.abs()),
            diffPercent.toStringAsFixed(1),
            CurrencyFormatters.formatCop(ref.referencePricePerKg),
          );

    return Container(
      key: const Key('crop_detail_regional_reference_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appWarningContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appWarning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: context.appWarning,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.crop_detail_regional_reference_region(ref.region),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              Chip(
                label: Text(l10n.common_simulated),
                visualDensity: VisualDensity.compact,
                backgroundColor: context.appWarningContainer,
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.appWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comparisonText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SimulatedRegionalPriceReferences.notice,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfoCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                imageUrl: avatarUrl,
                radius: 22,
                backgroundColor: context.appPrimary.withValues(alpha: 0.15),
                borderColor: context.appPrimary.withValues(alpha: 0.4),
                iconColor: context.appPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.crop_detail_farmer_info,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextSecondary,
                      ),
                    ),
                    Text(
                      producerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_farmerProfile?.settings.sharePhone == true &&
              _farmerProfile?.phone != null &&
              _farmerProfile!.phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: context.appPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  _farmerProfile!.phone,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appTextSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: rowContent,
      );
    }
    return rowContent;
  }
}
