import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_card.dart';
import 'publish_crop_screen.dart';
import 'crop_detail_screen.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../../profile/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? role;
  final List<CropModel>? initialCrops;

  const MarketplaceScreen({
    super.key,
    this.role,
    this.initialCrops,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _cropService = CropService();
  final _profileService = ProfileService();

  List<CropModel> _crops = [];
  String? _profileImageUrl;
  String? _userRole;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isBuyer {
    if (widget.role != null) {
      final r = widget.role!.trim().toLowerCase();
      return r == 'comprador' || r == 'comerciante';
    }
    if (_userRole != null) {
      final r = _userRole!.trim().toLowerCase();
      return r == 'comprador' || r == 'comerciante';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.initialCrops != null) {
      setState(() {
        _crops = widget.initialCrops!;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Si no se proporcionó el rol por parámetro, lo consultamos en el perfil
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

      // Cargar cosechas según el rol
      List<CropModel> crops;
      if (_isBuyer) {
        crops = await _cropService.getActiveMarketplaceCrops(excludeFarmerId: user.id);
      } else {
        crops = await _cropService.getCropsByFarmerId(user.id);
      }

      // Cargar info del perfil para el avatar
      try {
        final profileData = await _profileService.getFarmerProfileData(user.id);
        if (profileData.profilePath != null && profileData.profilePath!.isNotEmpty) {
          _profileImageUrl = _profileService.getPublicProfileImageUrl(profileData.profilePath!);
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _crops = crops;
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

  Future<void> _loadCrops() async {
    if (widget.initialCrops != null) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        List<CropModel> crops;
        if (_isBuyer) {
          crops = await _cropService.getActiveMarketplaceCrops(excludeFarmerId: user.id);
        } else {
          crops = await _cropService.getCropsByFarmerId(user.id);
        }

        try {
          final profileData = await _profileService.getFarmerProfileData(user.id);
          if (profileData.profilePath != null && profileData.profilePath!.isNotEmpty) {
            _profileImageUrl = _profileService.getPublicProfileImageUrl(profileData.profilePath!);
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _crops = crops;
          });
        }
      }
    } catch (_) {}
  }

  void _navigateToPublish() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PublishCropScreen()),
    );

    if (result == true) {
      _loadCrops();
    }
  }

  void _showPublishOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n?.market_publish_options_title ?? '¿Cómo deseas publicar?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.edit_document,
                    color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  ),
                ),
                title: Text(
                  l10n?.market_publish_manual ?? 'Publicación Manual',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.market_publish_manual_desc ?? 'Llena el formulario paso a paso',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPublish();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.mic,
                    color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  ),
                ),
                title: Text(
                  l10n?.market_publish_voice ?? 'Publicación por Nota de Voz',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.market_publish_voice_desc ?? 'Cuéntanos qué quieres publicar (Con IA)',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.market_ai_coming_soon ?? 'Función de IA próximamente...',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(CropModel crop) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropDetailScreen(crop: crop, role: widget.role),
      ),
    );

    if (result == true) {
      _loadCrops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final title = _isBuyer
        ? (l10n?.market_title ?? 'Mercado')
        : (l10n?.market_title_farmer ?? 'Mi Mercado');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: UserAvatar(
                imageUrl: _profileImageUrl,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Este es tu perfil')),
                  );
                },
              ),
            ),
          )
        ],
      ),
      body: _buildBody(isDark, l10n),
      floatingActionButton: _isBuyer
          ? null
          : FloatingActionButton.extended(
              onPressed: _showPublishOptions,
              icon: const Icon(Icons.add),
              label: Text(l10n?.market_publish_btn ?? 'Publicar'),
              backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
            ),
    );
  }

  Widget _buildBody(bool isDark, AppLocalizations? l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Ocurrió un error: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCrops,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                ),
                child: Text(l10n?.market_retry ?? 'Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_crops.isEmpty) {
      return _buildEmptyState(isDark, l10n);
    }

    return RefreshIndicator(
      onRefresh: _loadCrops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0).copyWith(
          bottom: _isBuyer ? 24 : 80, // Espacio para el FAB solo si es agricultor
        ),
        itemCount: _crops.length,
        itemBuilder: (context, index) {
          final crop = _crops[index];
          return CropCard(
            crop: crop,
            onTap: () => _navigateToDetail(crop),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations? l10n) {
    if (_isBuyer) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 80,
                color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                l10n?.market_empty_buyer_title ?? 'No hay cosechas disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.market_empty_buyer_desc ??
                    'En este momento no hay productos agrícolas disponibles para negociar. Intenta actualizar más tarde.',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadCrops,
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.market_refresh ?? 'Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80,
              color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.market_empty_farmer_title ?? 'Aún no tienes cosechas publicadas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.market_empty_farmer_desc ??
                  'Comienza a ofrecer tus productos en el mercado agrícola creando tu primera publicación.',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToPublish,
              icon: const Icon(Icons.add),
              label: Text(l10n?.market_publish_first ?? 'Publicar mi primera cosecha'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
