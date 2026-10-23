import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/loading/section_skeletons.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../../../core/widgets/misc/staggered_entrance.dart';
import '../../../core/widgets/sheets/app_sheet_frame.dart';
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

  /// The first page of cards staggers in once; later rebuilds (sorting,
  /// search, cards recycled by the lazy list) show items immediately.
  bool _entrancePlayed = false;

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
      showDragHandle: false,
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return AppSheetFrame(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.market_publish_options_title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: sheetContext.appTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              _PublishOptionTile(
                icon: LucideIcons.squarePen,
                triad: sheetContext.appBrandTriad,
                title: l10n.market_publish_manual,
                subtitle: l10n.market_publish_manual_desc,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _navigateToPublish();
                },
              ),
              const SizedBox(height: AppDimensions.space12),
              _PublishOptionTile(
                icon: LucideIcons.mic,
                triad: sheetContext.appInfoTriad,
                title: l10n.market_publish_voice,
                subtitle: l10n.market_publish_voice_desc,
                onTap: () {
                  Navigator.pop(sheetContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _openVoiceAssistant();
                  });
                },
              ),
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

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: AppDimensions.space16,
        title: const KusBrandLogo.compact(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space16),
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
      body: RefreshIndicator(
        onRefresh: _loadCrops,
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
      floatingActionButton: _isBuyer
          ? null
          : FloatingActionButton.extended(
              onPressed: _showPublishOptions,
              icon: const Icon(LucideIcons.plus, size: 20),
              label: Text(l10n.market_publish_btn),
              backgroundColor: context.appPrimary,
              foregroundColor: context.appOnPrimary,
            ),
    );
  }

  /// Large title in the iOS manner: the section name carries the hierarchy,
  /// a live count of lots sits under it, and farmers get a one-tap voice
  /// publish action beside it.
  Widget _buildHeader(AppLocalizations l10n) {
    final title = _isBuyer ? l10n.market_title : l10n.market_title_farmer;
    final showCount = !_isLoading && _errorMessage == null && _crops.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 30,
                    color: context.appTextPrimary,
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.standard),
                  switchInCurve: AppMotion.easeOut,
                  switchOutCurve: AppMotion.easeOut,
                  child: showCount
                      ? Padding(
                          key: const ValueKey('market_count'),
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _isBuyer
                                ? l10n.market_buyer_lot_count(_crops.length)
                                : l10n.market_farmer_lot_count(_crops.length),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.appTextSecondary,
                              fontFeatures: AppTextStyles.tabularFigures,
                            ),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('market_count_empty'),
                          width: double.infinity,
                        ),
                ),
              ],
            ),
          ),
          if (!_isBuyer) ...[
            const SizedBox(width: AppDimensions.space12),
            Tooltip(
              message: l10n.market_voice_quick_action,
              child: PressableScale(
                child: Material(
                  color: context.appPrimarySoft,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: const ValueKey('marketplace_voice_quick_action'),
                    customBorder: const CircleBorder(),
                    onTap: _openVoiceAssistant,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        LucideIcons.mic,
                        size: 20,
                        color: context.appOnPrimarySoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(AppLocalizations l10n) {
    if (_isLoading) {
      return const [
        SliverToBoxAdapter(
          child: SectionSkeleton(
            kind: SectionSkeletonKind.cropCards,
            itemCount: 2,
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
            title: l10n.common_error_prefix(_errorMessage ?? ''),
            action: ElevatedButton.icon(
              onPressed: _loadCrops,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.market_retry),
            ),
          ),
        ),
      ];
    }

    if (_crops.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(l10n),
        ),
      ];
    }

    final visibleCrops = _visibleCrops;
    final animateEntrance = !_entrancePlayed;
    if (animateEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entrancePlayed = true;
      });
    }

    return [
      if (_isBuyer) SliverToBoxAdapter(child: _buildCatalogTools(l10n)),
      if (visibleCrops.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildNoResultsState(l10n),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, _isBuyer ? 24 : 96),
          sliver: SliverList.builder(
            itemCount: visibleCrops.length,
            itemBuilder: (context, index) {
              final crop = visibleCrops[index];
              final distanceEval = _getDistanceForCrop(crop);
              return StaggeredEntrance(
                index: index,
                enabled: animateEntrance,
                child: CropCard(
                  crop: crop,
                  distanceEvaluation: distanceEval,
                  reputation: _farmerReputations[crop.farmerId],
                  onTap: () => _navigateToDetail(crop, distanceEval),
                ),
              );
            },
          ),
        ),
    ];
  }

  Widget _buildCatalogTools(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppDimensions.paddingScreenHorizontal,
            child: TextField(
              key: const ValueKey('marketplace_search_field'),
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.appTextPrimary,
              ),
              cursorColor: context.appPrimary,
              decoration: InputDecoration(
                hintText: l10n.market_search_hint,
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: context.appTextSecondary,
                ),
                isDense: true,
                filled: true,
                fillColor: context.appSurfaceVariant,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: context.appTextSecondary,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('marketplace_search_clear'),
                        tooltip: l10n.market_search_clear,
                        icon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 18,
                        ),
                        color: context.appTextMuted,
                        onPressed: _clearSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.borderRadiusMD,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.borderRadiusMD,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.borderRadiusMD,
                  borderSide: BorderSide(
                    color: context.appPrimary,
                    width: AppDimensions.borderWidthMedium,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: AppDimensions.paddingScreenHorizontal,
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
                  label: l10n.market_sort_reputation,
                  icon: LucideIcons.star,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sort pill: `surface` with a hairline at rest, solid `primary` with
  /// `onPrimary` text when active.
  Widget _buildSortChip({
    required _MarketplaceSortOption value,
    required String keyName,
    required String label,
    IconData? icon,
  }) {
    final isSelected = _sortOption == value;
    final foreground = isSelected
        ? context.appOnPrimary
        : context.appTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.space8),
      child: ChoiceChip(
        key: ValueKey('marketplace_sort_$keyName'),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 13, color: foreground),
            ],
          ],
        ),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) {
          if (_sortOption == value) return;
          HapticFeedback.selectionClick();
          setState(() {
            _sortOption = value;
          });
        },
        labelStyle: AppTextStyles.labelMedium.copyWith(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: foreground,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        selectedColor: context.appPrimary,
        backgroundColor: context.appSurface,
        side: BorderSide(
          color: isSelected ? context.appPrimary : context.appBorder,
        ),
        shape: const StadiumBorder(),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }

  Widget _buildNoResultsState(AppLocalizations l10n) {
    return AppEmptyState(
      icon: LucideIcons.searchX,
      title: l10n.market_no_results,
      message: l10n.market_no_results_desc,
      action: OutlinedButton.icon(
        key: const ValueKey('marketplace_clear_filters'),
        onPressed: _clearFilters,
        icon: const Icon(LucideIcons.listRestart, size: 18),
        label: Text(l10n.market_clear_filters),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    if (_isBuyer) {
      return AppEmptyState(
        icon: LucideIcons.wheatOff,
        title: l10n.market_empty_buyer_title,
        message: l10n.market_empty_buyer_desc,
        action: ElevatedButton.icon(
          onPressed: _loadCrops,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(l10n.market_refresh),
        ),
      );
    }

    return AppEmptyState(
      icon: LucideIcons.sprout,
      tone: AppEmptyStateTone.brand,
      title: l10n.market_empty_farmer_title,
      message: l10n.market_empty_farmer_desc,
      action: ElevatedButton.icon(
        onPressed: _navigateToPublish,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(l10n.market_publish_first),
      ),
    );
  }
}

/// One way to publish, as an iOS inset row: tinted squircle, title,
/// one-line explanation and a chevron.
class _PublishOptionTile extends StatelessWidget {
  final IconData icon;
  final AppSemanticTriad triad;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PublishOptionTile({
    required this.icon,
    required this.triad,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconSquircle(icon: icon, triad: triad),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: context.appTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
