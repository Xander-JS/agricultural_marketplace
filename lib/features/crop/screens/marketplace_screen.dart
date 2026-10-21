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
      backgroundColor: AppColors.transparent,
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
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
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
                  l10n.market_publish_options_title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      (context.appPrimary)
                          .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.edit_document,
                    color: context.appPrimary,
                  ),
                ),
                title: Text(
                  l10n.market_publish_manual,
                  style: TextStyle(
                    color: context.appTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.market_publish_manual_desc,
                  style: TextStyle(
                    color: context.appTextSecondary,
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
                      (context.appPrimary)
                          .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.mic,
                    color: context.appPrimary,
                  ),
                ),
                title: Text(
                  l10n.market_publish_voice,
                  style: TextStyle(
                    color: context.appTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.market_publish_voice_desc,
                  style: TextStyle(
                    color: context.appTextSecondary,
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
    final l10n = AppLocalizations.of(context)!;

    final title = _isBuyer
        ? (l10n.market_title)
        : (l10n.market_title_farmer);

    return Scaffold(
      backgroundColor: context.appBackground,
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
                            SnackBar(content: Text(l10n.market_own_profile)),
                          );
                        },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(l10n),
      floatingActionButton: _isBuyer
          ? null
          : FloatingActionButton.extended(
              onPressed: _showPublishOptions,
              icon: const Icon(Icons.add),
              label: Text(l10n.market_publish_btn),
              backgroundColor: context.appPrimary,
              foregroundColor: context.appOnPrimary,
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
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
              Icon(Icons.error_outline, size: 48, color: context.appError),
              const SizedBox(height: 16),
              Text(
                l10n.common_error_prefix(_errorMessage ?? ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCrops,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: context.appOnPrimary,
                ),
                child: Text(l10n.market_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_crops.isEmpty) {
      return _buildEmptyState(l10n);
    }

    final visibleCrops = _visibleCrops;

    return Column(
      children: [
        if (_isBuyer) _buildCatalogTools(l10n),
        Expanded(
          child: visibleCrops.isEmpty
              ? _buildNoResultsState(l10n)
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

  Widget _buildCatalogTools(AppLocalizations l10n) {
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
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(
              hintText:
                  l10n.market_search_hint,
              hintStyle: TextStyle(
                color: context.appTextDisabled,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: context.appTextDisabled,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('marketplace_search_clear'),
                      tooltip: l10n.market_search_clear,
                      icon: const Icon(Icons.close),
                      color: context.appTextSecondary,
                      onPressed: _clearSearch,
                    ),
              filled: true,
              fillColor: context.appSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.appBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.appBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: context.appPrimary,
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
                  value: _MarketplaceSortOption.recent,
                  keyName: 'recent',
                  label: l10n.market_sort_recent,
                ),
                _buildSortChip(
                  value: _MarketplaceSortOption.priceAscending,
                  keyName: 'price_asc',
                  label: l10n.market_sort_price_asc,
                ),
                _buildSortChip(
                  value: _MarketplaceSortOption.priceDescending,
                  keyName: 'price_desc',
                  label: l10n.market_sort_price_desc,
                ),
                _buildSortChip(
                  value: _MarketplaceSortOption.reputation,
                  keyName: 'reputation',
                  label:
                      l10n.market_sort_reputation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
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
              ? (context.appOnPrimary)
              : (context.appTextSecondary),
        ),
        selectedColor: context.appPrimary,
        backgroundColor: context.appSurface,
        side: BorderSide(
          color: context.appBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildNoResultsState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.appTextDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.market_no_results,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const ValueKey('marketplace_clear_filters'),
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: Text(l10n.market_clear_filters),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appPrimary,
                side: BorderSide(
                  color: context.appBorder,
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

  Widget _buildEmptyState(AppLocalizations l10n) {
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
                color: context.appTextDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.market_empty_buyer_title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.market_empty_buyer_desc,
                style: TextStyle(
                  fontSize: 15,
                  color: context.appTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadCrops,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.market_refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: context.appOnPrimary,
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
              color: context.appTextDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.market_empty_farmer_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.market_empty_farmer_desc,
              style: TextStyle(
                fontSize: 15,
                color: context.appTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToPublish,
              icon: const Icon(Icons.add),
              label: Text(
                l10n.market_publish_first,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appOnPrimary,
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
