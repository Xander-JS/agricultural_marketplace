import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/loading/section_skeletons.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/staggered_entrance.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/unit_formatters.dart';
import '../../crop/models/crop_model.dart';
import '../../crop/services/crop_service.dart';
import '../../crop/screens/publish_crop_screen.dart';
import '../services/crop_cost_calculator.dart';
import '../services/crop_cost_service.dart';
import 'crop_costs_detail_screen.dart';

class CostsScreen extends StatefulWidget {
  final CropService? cropService;
  final CropCostService? costService;
  final String? currentUserIdForTesting;

  const CostsScreen({
    super.key,
    this.cropService,
    this.costService,
    this.currentUserIdForTesting,
  });

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  late final CropService _cropService;
  late final CropCostService _costService;

  List<CropModel> _crops = [];
  Map<String, double> _cropTotals = {};
  bool _isLoading = true;
  String? _errorMessage;

  /// Crop cards stagger in on the first load only.
  bool _entrancePlayed = false;

  @override
  void initState() {
    super.initState();
    _cropService = widget.cropService ?? CropService();
    _costService = widget.costService ?? CropCostService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = widget.currentUserIdForTesting ?? user?.id;
      if (userId == null || userId.isEmpty) {
        throw Exception('Usuario no autenticado');
      }

      final crops = await _cropService.getCropsByFarmerId(userId);

      final totals = <String, double>{};
      for (final crop in crops) {
        totals[crop.id] = await _costService.getTotalCostByCropId(crop.id);
      }

      if (!mounted) return;
      setState(() {
        _crops = crops;
        _cropTotals = totals;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCreateCrop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PublishCropScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToDetail(CropModel crop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropCostsDetailScreen(
          crop: crop,
          cropService: _cropService,
          costService: _costService,
        ),
      ),
    );
    // Reload to update total costs in case they were modified
    _loadData();
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
        onRefresh: _loadData,
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.costs_title,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 30,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.costs_intro.replaceAll('\n', ' '),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(AppLocalizations l10n) {
    if (_isLoading) {
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
            title: l10n.common_error_prefix(_errorMessage!),
            action: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.common_retry),
            ),
          ),
        ),
      ];
    }

    if (_crops.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: LucideIcons.sprout,
            tone: AppEmptyStateTone.brand,
            title: l10n.costs_empty_title,
            message: l10n.costs_empty_desc,
            action: ElevatedButton.icon(
              onPressed: _navigateToCreateCrop,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l10n.costs_create_crop),
            ),
          ),
        ),
      ];
    }

    final animateEntrance = !_entrancePlayed;
    if (animateEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entrancePlayed = true;
      });
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        sliver: SliverList.builder(
          itemCount: _crops.length,
          itemBuilder: (context, index) {
            final crop = _crops[index];
            return StaggeredEntrance(
              index: index,
              enabled: animateEntrance,
              child: _buildCropCard(crop, _cropTotals[crop.id] ?? 0.0, l10n),
            );
          },
        ),
      ),
    ];
  }

  String _perKgSummary(AppLocalizations l10n, CropCostPerKgResult result) {
    switch (result.status) {
      case CropCostPerKgStatus.calculated:
        return l10n.costs_per_kg_calculated(
          CurrencyFormatters.formatPricePerKg(result.costPerKg),
        );
      case CropCostPerKgStatus.noCosts:
        return l10n.costs_per_kg_no_costs;
      case CropCostPerKgStatus.invalidCostTotal:
        return l10n.costs_per_kg_invalid_total;
      case CropCostPerKgStatus.invalidDenominator:
        return l10n.costs_per_kg_invalid_quantity;
      case CropCostPerKgStatus.estimatedYieldPending:
        return l10n.costs_per_kg_pending_yield;
    }
  }

  /// Ledger card for one crop: what it has cost so far, what that means
  /// per kilogram and which quantity the division used.
  Widget _buildCropCard(
    CropModel crop,
    double totalCost,
    AppLocalizations l10n,
  ) {
    final perKg = CropCostCalculator.calculatePerKg(
      crop: crop,
      totalCost: totalCost,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space12),
      child: InsetGroupCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CropThumb(
                        imageUrl: crop.imageUrls.isNotEmpty
                            ? _cropService.getPublicImageUrl(
                                crop.imageUrls.first,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            Text(
                              crop.cropType,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  Text(
                    l10n.costs_total,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatters.formatCop(totalCost),
                    style: AppTextStyles.figureLarge.copyWith(
                      fontSize: 26,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    _perKgSummary(l10n, perKg),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: perKg.isCalculated
                          ? context.appPrimary
                          : context.appTextSecondary,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                  if (perKg.denominator != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${UnitFormatters.formatKg(perKg.denominator)} · ${perKg.denominatorSource.displayName}',
                        style: AppTextStyles.caption.copyWith(
                          color: context.appTextSecondary,
                          fontFeatures: AppTextStyles.tabularFigures,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appDivider),
            InkWell(
              onTap: () => _navigateToDetail(crop),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(InsetGroupCard.radius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.receiptText,
                      size: 18,
                      color: context.appPrimary,
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Expanded(
                      child: Text(
                        l10n.costs_view,
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: context.appPrimary,
                        ),
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
          ],
        ),
      ),
    );
  }
}

/// 52px crop thumbnail; a sprout on the brand soft tone when the crop has
/// no photo yet.
class _CropThumb extends StatelessWidget {
  final String? imageUrl;

  const _CropThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = IconSquircle(
      icon: LucideIcons.sprout,
      triad: context.appBrandTriad,
      size: 52,
    );
    if (imageUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
