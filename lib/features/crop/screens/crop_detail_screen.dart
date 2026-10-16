import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_status_badge.dart';
import '../widgets/make_offer_sheet.dart';
import 'publish_crop_screen.dart';
import '../../deals/services/negotiation_service.dart';
import '../../profile/models/farmer_profile_data.dart';
import '../../profile/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';

class CropDetailScreen extends StatefulWidget {
  final CropModel crop;
  final String? role;
  final bool? isOwner;
  final FarmerProfileData? initialFarmerProfile;
  final NegotiationService? negotiationService;

  const CropDetailScreen({
    super.key,
    required this.crop,
    this.role,
    this.isOwner,
    this.initialFarmerProfile,
    this.negotiationService,
  });

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  late CropModel _crop;
  final _cropService = CropService();
  final _profileService = ProfileService();
  FarmerProfileData? _farmerProfile;
  bool _isLoading = false;

  bool get _isBuyer {
    if (widget.role != null) {
      return UserRole.isBuyerRole(widget.role);
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
    _farmerProfile = widget.initialFarmerProfile;

    if (_isBuyer && _farmerProfile == null) {
      _loadFarmerProfile();
    }
  }

  Future<void> _loadFarmerProfile() async {
    try {
      final profile = await _profileService.getFarmerProfileData(_crop.farmerId);
      if (mounted) {
        setState(() => _farmerProfile = profile);
      }
    } catch (_) {
      // Si falla la carga del perfil del agricultor, se usa la información básica de la cosecha
    }
  }

  Future<void> _updateStatus(CropStatus newStatus) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      await _cropService.updateCropStatus(_crop.id, newStatus);
      setState(() {
        _crop = CropModel(
          id: _crop.id,
          farmerId: _crop.farmerId,
          title: _crop.title,
          description: _crop.description,
          cropType: _crop.cropType,
          pricePerKg: _crop.pricePerKg,
          stockTotal: _crop.stockTotal,
          stockCommitted: _crop.stockCommitted,
          stockSold: _crop.stockSold,
          minOrderKg: _crop.minOrderKg,
          department: _crop.department,
          municipality: _crop.municipality,
          isEarlySale: _crop.isEarlySale,
          status: newStatus,
          createdAt: _crop.createdAt,
          updatedAt: DateTime.now(),
          imageUrls: _crop.imageUrls,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.crop_detail_status_updated ?? 'Estado actualizado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PublishCropScreen(cropToEdit: _crop)),
    );

    if (result == true) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.crop_detail_confirm_delete_title ?? 'Borrar Publicación'),
        content: Text(
          l10n?.crop_detail_confirm_delete_desc ??
              '¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.',
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
                l10n?.crop_detail_delete_success ?? 'Publicación borrada exitosamente',
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
              content: Text('${l10n?.crop_detail_delete_error ?? "Error al borrar"}: $e'),
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

    // 1. Validar que la cosecha tenga stock disponible
    if (_crop.availableStock <= 0 || _crop.status == CropStatus.agotada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta cosecha se encuentra agotada o sin stock disponible.'),
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
                title: Text(l10n?.crop_unapproved_dialog_title ?? 'Verificación requerida'),
                content: Text(
                  l10n?.crop_unapproved_dialog_desc ??
                      'Para realizar ofertas y negociar con los agricultores, tu perfil debe estar verificado y aprobado por un moderador.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n?.crop_unapproved_dialog_action ?? 'Entendido'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MakeOfferSheet(
        crop: _crop,
        negotiationService: widget.negotiationService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    String? primaryImageUrl;
    if (_crop.imageUrls.isNotEmpty) {
      primaryImageUrl = _cropService.getPublicImageUrl(_crop.imageUrls.first);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                  // Imagen principal
                  if (primaryImageUrl != null)
                    Image.network(
                      primaryImageUrl,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImageFallback(isDark),
                    )
                  else
                    _buildImageFallback(isDark),

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
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _crop.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),

                        Divider(
                          height: 32,
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),

                        // Datos de precio y existencias
                        _buildInfoRow(
                          l10n?.crop_detail_price_per_kg ?? 'Precio por kg',
                          '\$${_crop.pricePerKg.toStringAsFixed(2)}',
                          isDark,
                        ),
                        _buildInfoRow(
                          l10n?.crop_detail_available_stock ?? 'Total Disponible',
                          '${_crop.stockTotal.toStringAsFixed(2)} kg',
                          isDark,
                        ),
                        _buildInfoRow(
                          l10n?.crop_detail_min_order ?? 'Pedido Mínimo',
                          '${_crop.minOrderKg.toStringAsFixed(2)} kg',
                          isDark,
                        ),
                        _buildInfoRow(
                          l10n?.crop_detail_location ?? 'Ubicación',
                          '${_crop.municipality}, ${_crop.department}',
                          isDark,
                        ),

                        if (_crop.isEarlySale) ...[
                          Divider(
                            height: 32,
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                          Text(
                            l10n?.crop_detail_early_sale ?? 'Venta Anticipada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_crop.estimatedHarvestDate != null)
                            _buildInfoRow(
                              l10n?.crop_detail_estimated_harvest ?? 'Fecha est. de cosecha',
                              '${_crop.estimatedHarvestDate!.day}/${_crop.estimatedHarvestDate!.month}/${_crop.estimatedHarvestDate!.year}',
                              isDark,
                            ),
                          if (_crop.estimatedYieldKg != null)
                            _buildInfoRow(
                              l10n?.crop_detail_estimated_yield ?? 'Rendimiento estimado',
                              '${_crop.estimatedYieldKg} kg',
                              isDark,
                            ),
                        ],

                        // Sección de información del Productor (para compradores)
                        if (_isBuyer) ...[
                          Divider(
                            height: 32,
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                          _buildFarmerInfoCard(isDark, l10n),
                        ],

                        // Sección de Acciones
                        Divider(
                          height: 32,
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                        Text(
                          l10n?.crop_detail_quick_actions ?? 'Acciones Rápidas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Si es agricultor dueño: Pausar/Activar y Ver Negociaciones
                        if (_isOwner) ...[
                          if (_crop.status == CropStatus.activa)
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(CropStatus.pausada),
                              icon: const Icon(Icons.pause),
                              label: Text(l10n?.crop_detail_pause_crop ?? 'Pausar Publicación'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          else if (_crop.status == CropStatus.pausada || _crop.status == CropStatus.borrador)
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(CropStatus.activa),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(l10n?.crop_detail_activate_crop ?? 'Activar Publicación'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.crop_detail_negotiations_coming_soon ??
                                        'Próximamente: Ver negociaciones',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.handshake),
                            label: Text(l10n?.crop_detail_view_negotiations ?? 'Ver Negociaciones'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],

                        // Si es comprador: Hacer oferta / Negociar
                        if (_isBuyer) ...[
                          ElevatedButton.icon(
                            onPressed: _openMakeOfferSheet,
                            icon: const Icon(Icons.handshake_outlined),
                            label: Text(
                              l10n?.crop_detail_make_offer ?? 'Hacer oferta / Negociar',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
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

  Widget _buildImageFallback(bool isDark) {
    return Container(
      height: 200,
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSecondary.withValues(alpha: 0.35),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
        ),
      ),
    );
  }

  Widget _buildFarmerInfoCard(bool isDark, AppLocalizations? l10n) {
    final producerName = _farmerProfile?.fullName.isNotEmpty == true
        ? _farmerProfile!.fullName
        : '${l10n?.crop_detail_producer ?? "Productor"} (${_crop.municipality})';

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
              CircleAvatar(
                backgroundColor: isDark
                    ? AppColors.darkTertiary.withValues(alpha: 0.2)
                    : AppColors.lightSecondary,
                radius: 22,
                child: Icon(
                  Icons.person,
                  color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.crop_detail_farmer_info ?? 'Información del Productor',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      producerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  _farmerProfile!.phone,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
