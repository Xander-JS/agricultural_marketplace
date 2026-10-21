import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_card.dart';
import 'publish_crop_screen.dart';
import 'crop_detail_screen.dart';
import '../../../core/widgets/avatars/user_avatar.dart';
import '../../profile/models/farmer_profile_data.dart';
import '../../profile/services/profile_service.dart';
import '../../review/models/review_model.dart';
import '../../review/services/review_service.dart';
import '../../geo/models/simulated_location.dart';
import '../../geo/services/geo_simulation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../ai_assistant/models/voice_crop_draft.dart';
import '../../ai_assistant/widgets/voice_crop_assistant_sheet.dart';

enum _MarketplaceSortOption {
  recent,
  priceAscending,
  priceDescending,
  reputation,
}

class MarketplaceScreen extends StatefulWidget {
  final String? role;
  final List<CropModel>? initialCrops;
  final VoidCallback? onProfileTap;
  final ProfileService? profileService;
  final ReviewService? reviewService;
  final FarmerProfileData? initialUserProfile;

  const MarketplaceScreen({
    super.key,
    this.role,
    this.initialCrops,
    this.onProfileTap,
    this.profileService,
    this.reviewService,
    this.initialUserProfile,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _cropService = CropService();
  late final ProfileService _profileService =
      widget.profileService ?? ProfileService();
  late final ReviewService _reviewService =
      widget.reviewService ?? ReviewService();
  final _searchController = TextEditingController();

  List<CropModel> _crops = [];
  Map<String, ReviewSummary> _farmerReputations = const {};
  String _searchQuery = '';
  _MarketplaceSortOption _sortOption = _MarketplaceSortOption.recent;
  String? _profileImageUrl;
  String? _userRole;
  FarmerProfileData? _currentUserProfile;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isBuyer => UserRole.isBuyerRole(widget.role ?? _userRole);

  @override
  void initState() {
    super.initState();
    if (widget.initialUserProfile != null) {
      _currentUserProfile = widget.initialUserProfile;
    }
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _profileService.getFarmerProfileData(user.id);
        if (mounted) {
          setState(() {
            _currentUserProfile = profile;
            if (profile.profilePath != null &&
                profile.profilePath!.isNotEmpty) {
              _profileImageUrl = _profileService.getPublicProfileImageUrl(
                profile.profilePath!,
              );
            }
          });
        }
      }
    } catch (_) {}
  }

  DistanceEvaluation? _getDistanceForCrop(CropModel crop) {
    if (!_isBuyer) return null;
    final buyer = _currentUserProfile;
    if (buyer == null) return null;
    if (buyer.id == crop.farmerId) return null;
    final eval = GeoSimulationService.evaluateBuyerProfileToCrop(
      buyerProfile: buyer,
      crop: crop,
    );
    return eval.hasValidDistance ? eval : null;
  }

  Future<void> _loadFarmerReputations(List<CropModel> crops) async {
    final farmerIds = crops
        .map((crop) => crop.farmerId)
        .where((farmerId) => farmerId.isNotEmpty)
        .toSet();

    if (farmerIds.isEmpty) {
      if (mounted) {
        setState(() {
          _farmerReputations = const {};
        });
      }
      return;
    }

    try {
      final reputations = await _reviewService.getReputationsForUsers(
        farmerIds,
      );
      if (mounted) {
        setState(() {
          _farmerReputations = reputations;
        });
      }
    } catch (_) {
      // La reputación alimenta el indicador de cada tarjeta y el ordenamiento.
      // Si la consulta falla no se muestra un valor ficticio y el catálogo
      // sigue disponible.
    }
  }

  List<CropModel> get _visibleCrops {
    if (!_isBuyer) return _crops;

    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _crops
        : _crops
              .where((crop) {
                return crop.title.toLowerCase().contains(query) ||
                    crop.cropType.toLowerCase().contains(query);
              })
              .toList(growable: false);

    return _sortCrops(filtered);
  }

  List<CropModel> _sortCrops(List<CropModel> crops) {
    final indexedCrops = crops.asMap().entries.toList(growable: false);

    indexedCrops.sort((a, b) {
      final comparison = _compareCrops(a.value, b.value);
      if (comparison != 0) return comparison;
      // Dart no garantiza un ordenamiento estable: el índice original
      // conserva el orden recibido (created_at descendente desde el servicio).
      return a.key.compareTo(b.key);
    });

    return indexedCrops.map((entry) => entry.value).toList(growable: false);
  }

  int _compareCrops(CropModel a, CropModel b) {
    switch (_sortOption) {
      case _MarketplaceSortOption.recent:
        return b.createdAt.compareTo(a.createdAt);
      case _MarketplaceSortOption.priceAscending:
        return a.pricePerKg.compareTo(b.pricePerKg);
      case _MarketplaceSortOption.priceDescending:
        return b.pricePerKg.compareTo(a.pricePerKg);
      case _MarketplaceSortOption.reputation:
        final aReputation =
            _farmerReputations[a.farmerId] ?? ReviewSummary.empty;
        final bReputation =
            _farmerReputations[b.farmerId] ?? ReviewSummary.empty;

        if (aReputation.isNew != bReputation.isNew) {
          return aReputation.isNew ? 1 : -1;
        }
        if (aReputation.isNew) return 0;

        return bReputation.averageRating.compareTo(aReputation.averageRating);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _sortOption = _MarketplaceSortOption.recent;
    });
  }

  Future<void> _loadData() async {
    _loadUserProfile();

    if (widget.initialCrops != null) {
      final initialCrops = widget.initialCrops!;
      setState(() {
        _crops = initialCrops;
        _isLoading = false;
        _errorMessage = null;
      });
      await _loadFarmerReputations(initialCrops);
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
        crops = await _cropService.getActiveMarketplaceCrops(
          excludeFarmerId: user.id,
        );
      } else {
        crops = await _cropService.getCropsByFarmerId(user.id);
      }

      // Cargar info del perfil para el avatar
      try {
        final profileData = await _profileService.getFarmerProfileData(user.id);
        if (profileData.profilePath != null &&
            profileData.profilePath!.isNotEmpty) {
          _profileImageUrl = _profileService.getPublicProfileImageUrl(
            profileData.profilePath!,
          );
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

    if (mounted && _errorMessage == null) {
      await _loadFarmerReputations(_crops);
    }
  }

  Future<void> _loadCrops() async {
    if (widget.initialCrops != null) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        List<CropModel> crops;
        if (_isBuyer) {
          crops = await _cropService.getActiveMarketplaceCrops(
            excludeFarmerId: user.id,
          );
        } else {
          crops = await _cropService.getCropsByFarmerId(user.id);
        }

        try {
          final profileData = await _profileService.getFarmerProfileData(
            user.id,
          );
          if (profileData.profilePath != null &&
              profileData.profilePath!.isNotEmpty) {
            _profileImageUrl = _profileService.getPublicProfileImageUrl(
              profileData.profilePath!,
            );
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _crops = crops;
          });
        }

        await _loadFarmerReputations(crops);
      }
    } catch (_) {}
  }

  void _navigateToPublish({VoiceCropDraft? initialDraft}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublishCropScreen(
          initialDraft: initialDraft,
          role: widget.role ?? _userRole,
        ),
      ),
    );

    if (result == true) {
      _loadCrops();
    }
  }

  Future<void> _openVoiceAssistant() async {
    final result = await showModalBottomSheet<VoiceCropAssistantResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceCropAssistantSheet(),
    );

    if (!mounted || result == null) return;
    if (result.openManual) {
      _navigateToPublish();
      return;
    }
    final draft = result.draft;
    if (draft != null) {
      _navigateToPublish(initialDraft: draft);
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
                  l10n?.market_publish_options_title ??
                      '¿Cómo deseas publicar?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (isDark
                              ? AppColors.darkTertiary
                              : AppColors.lightTertiary)
                          .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.edit_document,
                    color: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                  ),
                ),
                title: Text(
                  l10n?.market_publish_manual ?? 'Publicación Manual',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.market_publish_manual_desc ??
                      'Llena el formulario paso a paso',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPublish();
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (isDark
                              ? AppColors.darkTertiary
                              : AppColors.lightTertiary)
                          .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.mic,
                    color: isDark
                        ? AppColors.darkTertiary
                        : AppColors.lightTertiary,
                  ),
                ),
                title: Text(
                  l10n?.market_publish_voice ?? 'Publicación por Nota de Voz',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.market_publish_voice_desc ??
                      'Cuéntanos qué quieres publicar (Con IA)',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _openVoiceAssistant();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(
    CropModel crop, [
    DistanceEvaluation? distanceEval,
  ]) async {
    final effectiveEval = distanceEval ?? _getDistanceForCrop(crop);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropDetailScreen(
          crop: crop,
          role: widget.role ?? _userRole,
          initialDistanceEvaluation: effectiveEval,
          initialBuyerProfile: _currentUserProfile,
          profileService: _profileService,
        ),
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ValueListenableBuilder<String?>(
                valueListenable: _profileService.profilePathNotifier,
                builder: (context, livePath, _) {
                  final effectivePath =
                      (livePath != null && livePath.isNotEmpty)
                      ? livePath
                      : null;
                  final effectiveUrl = effectivePath != null
                      ? _profileService.getPublicProfileImageUrl(effectivePath)
                      : _profileImageUrl;

                  return UserAvatar(
                    imageUrl: effectiveUrl,
                    onTap:
                        widget.onProfileTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Este es tu perfil')),
                          );
                        },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(isDark, l10n),
      floatingActionButton: _isBuyer
          ? null
          : FloatingActionButton.extended(
              onPressed: _showPublishOptions,
              icon: const Icon(Icons.add),
              label: Text(l10n?.market_publish_btn ?? 'Publicar'),
              backgroundColor: isDark
                  ? AppColors.darkTertiary
                  : AppColors.lightTertiary,
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCrops,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkTertiary
                      : AppColors.lightTertiary,
                  foregroundColor: isDark
                      ? AppColors.darkBackground
                      : Colors.white,
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

    final visibleCrops = _visibleCrops;

    return Column(
      children: [
        if (_isBuyer) _buildCatalogTools(isDark, l10n),
        Expanded(
          child: visibleCrops.isEmpty
              ? _buildNoResultsState(isDark, l10n)
              : RefreshIndicator(
                  onRefresh: _loadCrops,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0).copyWith(
                      bottom: _isBuyer
                          ? 24
                          : 80, // Espacio para el FAB solo si es agricultor
                    ),
                    itemCount: visibleCrops.length,
                    itemBuilder: (context, index) {
                      final crop = visibleCrops[index];
                      final distanceEval = _getDistanceForCrop(crop);
                      return CropCard(
                        crop: crop,
                        distanceEvaluation: distanceEval,
                        reputation: _farmerReputations[crop.farmerId],
                        onTap: () => _navigateToDetail(crop, distanceEval),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCatalogTools(bool isDark, AppLocalizations? l10n) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('marketplace_search_field'),
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            textInputAction: TextInputAction.search,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText:
                  l10n?.market_search_hint ??
                  'Buscar por título o tipo de cultivo',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextDisabled
                    : AppColors.lightTextDisabled,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark
                    ? AppColors.darkTextDisabled
                    : AppColors.lightTextDisabled,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('marketplace_search_clear'),
                      tooltip: l10n?.market_search_clear ?? 'Borrar búsqueda',
                      icon: const Icon(Icons.close),
                      color: secondaryTextColor,
                      onPressed: _clearSearch,
                    ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkTertiary
                      : AppColors.lightTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(
                  isDark: isDark,
                  value: _MarketplaceSortOption.recent,
                  keyName: 'recent',
                  label: l10n?.market_sort_recent ?? 'Most recent first',
                ),
                _buildSortChip(
                  isDark: isDark,
                  value: _MarketplaceSortOption.priceAscending,
                  keyName: 'price_asc',
                  label: l10n?.market_sort_price_asc ?? 'Lowest price first',
                ),
                _buildSortChip(
                  isDark: isDark,
                  value: _MarketplaceSortOption.priceDescending,
                  keyName: 'price_desc',
                  label: l10n?.market_sort_price_desc ?? 'Highest price first',
                ),
                _buildSortChip(
                  isDark: isDark,
                  value: _MarketplaceSortOption.reputation,
                  keyName: 'reputation',
                  label:
                      l10n?.market_sort_reputation ??
                      'Highest reputation first',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required bool isDark,
    required _MarketplaceSortOption value,
    required String keyName,
    required String label,
  }) {
    final isSelected = _sortOption == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey('marketplace_sort_$keyName'),
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) {
          if (_sortOption == value) return;
          setState(() {
            _sortOption = value;
          });
        },
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? (isDark ? AppColors.darkBackground : Colors.white)
              : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
        ),
        selectedColor: isDark
            ? AppColors.darkTertiary
            : AppColors.lightTertiary,
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark
                  ? AppColors.darkTextDisabled
                  : AppColors.lightTextDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.market_no_results ??
                  'No crops were found matching these criteria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const ValueKey('marketplace_clear_filters'),
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: Text(l10n?.market_clear_filters ?? 'Clear filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkTertiary
                    : AppColors.lightTertiary,
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
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
                color: isDark
                    ? AppColors.darkTextDisabled
                    : AppColors.lightTextDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                l10n?.market_empty_buyer_title ?? 'No hay cosechas disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.market_empty_buyer_desc ?? 'En este momento no hay productos agrícolas disponibles para negociar. Intenta actualizar más tarde.',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadCrops,
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.market_refresh ?? 'Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkTertiary
                      : AppColors.lightTertiary,
                  foregroundColor: isDark
                      ? AppColors.darkBackground
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              color: isDark
                  ? AppColors.darkTextDisabled
                  : AppColors.lightTextDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.market_empty_farmer_title ??
                  'Aún no tienes cosechas publicadas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.market_empty_farmer_desc ?? 'Comienza a ofrecer tus productos en el mercado agrícola creando tu primera publicación.',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToPublish,
              icon: const Icon(Icons.add),
              label: Text(
                l10n?.market_publish_first ?? 'Publicar mi primera cosecha',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkTertiary
                    : AppColors.lightTertiary,
                foregroundColor: isDark
                    ? AppColors.darkBackground
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
