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
    if (_distanceEvaluation != null && _distanceEvaluation!.hasValidDistance)
      return;
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

  String _formatEstimatedDistance(DistanceEvaluation eval) {
    final km = eval.distanceKm;
    if (km == null || km < 0) return 'No disponible';
    if (km < 1.0) return '< 1 km';
    return '${km.round()} km';
  }

  void _showEquivalencesModal(BuildContext context) {
    if (!_isBuyer) return;
    final reference = _crop.availableStock;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          UnitEquivalencesSheet(referenceKg: reference, cropTitle: _crop.title),
    );
  }

  Future<void> _updateStatus(CropStatus newStatus) async {
    final l10n = AppLocalizations.of(context);
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acceso denegado: solo el productor dueño puede modificar esta publicación.',
          ),
          backgroundColor: AppColors.error,
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
            content: Text(
              l10n?.crop_detail_status_updated ?? 'Estado actualizado',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
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
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acceso denegado: no puedes editar publicaciones de otros usuarios.',
          ),
          backgroundColor: AppColors.error,
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
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acceso denegado: no puedes borrar publicaciones de otros usuarios.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.crop_detail_confirm_delete_title ?? 'Borrar Publicación',
        ),
        content: Text(
          l10n?.crop_detail_confirm_delete_desc ?? '¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.profile_cancel ?? 'Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              l10n?.crop_detail_delete_tooltip ?? 'Borrar',
              style: const TextStyle(color: Colors.white),
            ),
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
              content: Text(
                l10n?.crop_detail_delete_success ??
                    'Publicación borrada exitosamente',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n?.crop_detail_delete_error ?? "Error al borrar"}: $e',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openMakeOfferSheet() async {
    final l10n = AppLocalizations.of(context);

    // 0. Validar que no sea el productor dueño
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes iniciar una oferta en tu propia cosecha.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // 1. Validar que la cosecha tenga stock disponible
    if (_crop.availableStock <= 0 || _crop.status == CropStatus.agotada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta cosecha se encuentra agotada o sin stock disponible.',
          ),
          backgroundColor: AppColors.warning,
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
                title: Text(
                  l10n?.crop_unapproved_dialog_title ??
                      'Verificación requerida',
                ),
                content: Text(
                  l10n?.crop_unapproved_dialog_desc ?? 'Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      l10n?.crop_unapproved_dialog_action ?? 'Entendido',
                    ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => MakeOfferSheet(
        crop: _crop,
        negotiationService: widget.negotiationService,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Oferta enviada exitosamente.'),
          action: SnackBarAction(
            label: 'Ver Tratos',
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
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n?.crop_detail_title ?? 'Detalle de Cosecha'),
        actions: _isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDelete,
                  tooltip: l10n?.crop_detail_delete_tooltip ?? 'Borrar',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _navigateToEdit,
                  tooltip: l10n?.crop_detail_edit_tooltip ?? 'Editar',
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
                  _buildImageGallery(isDark),

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
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
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
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _crop.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),

                        Divider(
                          height: 32,
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),

                        // Datos de precio y existencias
                        _buildInfoRow(
                          l10n?.crop_detail_price_per_kg ?? 'Precio por kg',
                          CurrencyFormatters.formatCop(_crop.pricePerKg),
                          isDark,
                        ),
                        if (_regionalReference != null) ...[
                          const SizedBox(height: 4),
                          _buildRegionalReferenceBanner(isDark),
                          const SizedBox(height: 8),
                        ],
                        _buildInfoRow(
                          l10n?.crop_detail_available_stock ??
                              'Total Disponible',
                          UnitFormatters.formatKgWithEquivalence(
                            _crop.availableStock,
                          ),
                          isDark,
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
                                  foregroundColor: isDark
                                      ? AppColors.darkTertiary
                                      : AppColors.lightTertiary,
                                  backgroundColor:
                                      (isDark
                                              ? AppColors.darkTertiary
                                              : AppColors.lightTertiary)
                                          .withValues(alpha: 0.08),
                                  side: BorderSide(
                                    color:
                                        (isDark
                                                ? AppColors.darkTertiary
                                                : AppColors.lightTertiary)
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
                                  color: isDark
                                      ? AppColors.darkTertiary
                                      : AppColors.lightTertiary,
                                ),
                                label: Text(
                                  l10n?.crop_detail_view_equivalences ??
                                      'Ver equivalencias',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkTertiary
                                        : AppColors.lightTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildInfoRow(
                          l10n?.crop_detail_min_order ?? 'Pedido Mínimo',
                          UnitFormatters.formatKg(_crop.minOrderKg),
                          isDark,
                        ),
                        _buildInfoRow(
                          l10n?.crop_detail_location ?? 'Ubicación',
                          _distanceEvaluation != null &&
                                  _distanceEvaluation!.hasValidDistance
                              ? '${_crop.municipality}, ${_crop.department} (${_distanceEvaluation!.formatted})'
                              : '${_crop.municipality}, ${_crop.department}',
                          isDark,
                        ),
                        if (_isBuyer &&
                            _distanceEvaluation != null &&
                            _distanceEvaluation!.hasValidDistance)
                          _buildInfoRow(
                            Localizations.localeOf(context).languageCode == 'en'
                                ? 'Estimated distance'
                                : 'Distancia estimada',
                            _formatEstimatedDistance(_distanceEvaluation!),
                            isDark,
                          ),
                        _buildInfoRow(
                          l10n?.crop_detail_publication_date ??
                              'Fecha de publicación',
                          DateFormatters.formatMediumDate(_crop.createdAt),
                          isDark,
                        ),
                        if (!_crop.isEarlySale &&
                            _crop.estimatedHarvestDate != null)
                          _buildInfoRow(
                            l10n?.crop_detail_estimated_harvest ??
                                'Fecha est. de cosecha',
                            DateFormatters.formatHarvestDateLong(
                              _crop.estimatedHarvestDate,
                            ),
                            isDark,
                          ),

                        if (_crop.isEarlySale) ...[
                          Divider(
                            height: 32,
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                          Text(
                            l10n?.crop_detail_early_sale ?? 'Venta Anticipada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_crop.estimatedHarvestDate != null)
                            _buildInfoRow(
                              l10n?.crop_detail_estimated_harvest ??
                                  'Fecha est. de cosecha',
                              DateFormatters.formatHarvestDateLong(
                                _crop.estimatedHarvestDate,
                              ),
                              isDark,
                            ),
                          if (_crop.estimatedYieldKg != null)
                            _buildInfoRow(
                              l10n?.crop_detail_estimated_yield ??
                                  'Rendimiento estimado',
                              UnitFormatters.formatKgWithEquivalence(
                                _crop.estimatedYieldKg,
                              ),
                              isDark,
                            ),
                        ],

                        // Sección de información del Productor (para compradores)
                        if (_isBuyer) ...[
                          Divider(
                            height: 32,
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                          _buildFarmerInfoCard(isDark, l10n),
                        ],

                        // Sección de Acciones
                        Divider(
                          height: 32,
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                        Text(
                          l10n?.crop_detail_quick_actions ?? 'Acciones Rápidas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
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
                              label: Text(
                                l10n?.crop_detail_pause_crop ??
                                    'Pausar Publicación',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
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
                              label: Text(
                                l10n?.crop_detail_activate_crop ??
                                    'Activar Publicación',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
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
                            label: Text(
                              l10n?.crop_detail_view_negotiations ??
                                  'Ver Negociaciones',
                            ),
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
                              l10n?.crop_detail_make_offer ??
                                  'Hacer oferta / Negociar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.darkTertiary
                                  : AppColors.lightTertiary,
                              foregroundColor: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
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
                              color: isDark
                                  ? AppColors.darkTertiary
                                  : AppColors.lightTertiary,
                            ),
                            label: Text(
                              l10n?.crop_detail_view_equivalences ??
                                  'Ver equivalencias',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTertiary
                                    : AppColors.lightTertiary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color:
                                    (isDark
                                            ? AppColors.darkTertiary
                                            : AppColors.lightTertiary)
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

  Widget _buildImageGallery(bool isDark) {
    if (_crop.imageUrls.isEmpty) {
      return _buildImageFallback(isDark);
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
              _buildImageFallback(isDark),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightDivider,
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
                        _buildImageFallback(isDark),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightDivider,
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
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${_crop.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
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
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
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
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                  ? (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                  : Colors.transparent;

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
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightDivider,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
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

  Widget _buildImageFallback(bool isDark) {
    return Container(
      height: 200,
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSecondary.withValues(alpha: 0.35),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: isDark
              ? AppColors.darkTextDisabled
              : AppColors.lightTextDisabled,
        ),
      ),
    );
  }

  Widget _buildRegionalReferenceBanner(bool isDark) {
    final ref = _regionalReference!;
    final diff = _crop.pricePerKg - ref.referencePricePerKg;
    final diffPercent = ref.referencePricePerKg > 0
        ? (diff / ref.referencePricePerKg) * 100
        : 0.0;
    final sign = diff > 0 ? '+' : '';
    final comparisonText = diff == 0
        ? 'Precio igual a la referencia regional (${CurrencyFormatters.formatCop(ref.referencePricePerKg)}/kg)'
        : '$sign${CurrencyFormatters.formatCop(diff)}/kg ($sign${diffPercent.toStringAsFixed(1)}%) vs referencia regional (${CurrencyFormatters.formatCop(ref.referencePricePerKg)}/kg)';

    return Container(
      key: const Key('crop_detail_regional_reference_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Referencia regional (${ref.region})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Chip(
                label: const Text('SIMULADA'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.orange.shade100,
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comparisonText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            SimulatedRegionalPriceReferences.notice,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.darkTextDisabled
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerInfoCard(bool isDark, AppLocalizations? l10n) {
    final producerName = _farmerProfile?.fullName.isNotEmpty == true
        ? _farmerProfile!.fullName
        : '${l10n?.crop_detail_producer ?? "Productor"} (${_crop.municipality})';

    final avatarUrl =
        _farmerProfile?.profilePath != null &&
            _farmerProfile!.profilePath!.isNotEmpty
        ? _profileService.getPublicProfileImageUrl(_farmerProfile!.profilePath!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                imageUrl: avatarUrl,
                radius: 22,
                backgroundColor: isDark
                    ? AppColors.darkTertiary.withValues(alpha: 0.2)
                    : AppColors.lightSecondary,
                borderColor: isDark
                    ? AppColors.darkTertiary.withValues(alpha: 0.4)
                    : AppColors.lightSecondary,
                iconColor: isDark
                    ? AppColors.darkTertiary
                    : AppColors.lightTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.crop_detail_farmer_info ??
                          'Información del Productor',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextDisabled
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      producerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
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
                  color: isDark
                      ? AppColors.darkTertiary
                      : AppColors.lightTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  _farmerProfile!.phone,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
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
    String label,
    String value,
    bool isDark, {
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
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
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
