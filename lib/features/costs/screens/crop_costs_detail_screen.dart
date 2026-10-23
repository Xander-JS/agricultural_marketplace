import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/loading/section_skeletons.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/staggered_entrance.dart';
import '../widgets/cost_category_style.dart';
import '../widgets/cost_wallet_panel.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/unit_formatters.dart';
import '../../crop/models/crop_model.dart';
import '../../crop/services/crop_service.dart';
import '../models/crop_cost_model.dart';
import '../services/crop_cost_calculator.dart';
import '../services/crop_cost_service.dart';
import 'add_crop_cost_screen.dart';
import 'crop_profitability_screen.dart';

class CropCostsDetailScreen extends StatefulWidget {
  final CropModel crop;
  final CropService? cropService;
  final CropCostService? costService;

  const CropCostsDetailScreen({
    super.key,
    required this.crop,
    this.cropService,
    this.costService,
  });

  @override
  State<CropCostsDetailScreen> createState() => _CropCostsDetailScreenState();
}

class _CropCostsDetailScreenState extends State<CropCostsDetailScreen> {
  late final CropCostService _costService;
  late final CropService _cropService;

  List<CropCostModel> _costs = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalCost = 0.0;
  CropCostPerKgResult? _perKgResult;

  @override
  void initState() {
    super.initState();
    _costService = widget.costService ?? CropCostService();
    _cropService = widget.cropService ?? CropService();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final costs = await _costService.getCostsByCropId(widget.crop.id);
      final total = CropCostCalculator.totalForCrop(costs, widget.crop.id);
      final perKg = CropCostCalculator.calculatePerKg(
        crop: widget.crop,
        totalCost: total,
      );

      if (!mounted) return;
      setState(() {
        _costs = costs;
        _totalCost = total;
        _perKgResult = perKg;
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

  void _navigateToAddOrEditCost([CropCostModel? costToEdit]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCropCostScreen(
          cropId: widget.crop.id,
          costToEdit: costToEdit,
          costService: _costService,
        ),
      ),
    );

    if (result == true) {
      await _loadCosts();
    }
  }

  Future<void> _deleteCost(CropCostModel cost) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.costs_delete_title),
        content: Text(l10n.costs_delete_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _costService.deleteCost(cost.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.costs_deleted)));
        await _loadCosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.costs_delete_error(e.toString()))),
        );
      }
    }
  }

  void _openProfitability() {
    final result = _perKgResult;
    if (result == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CropProfitabilityScreen(crop: widget.crop, costPerKgResult: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(widget.crop.title)),
      body: _buildBody(l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddOrEditCost(),
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(l10n.costs_add),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const SectionSkeleton(kind: SectionSkeletonKind.rowCards);
    }

    if (_errorMessage != null) {
      return AppEmptyState(
        icon: LucideIcons.cloudOff,
        title: l10n.common_error_prefix(_errorMessage!),
        action: ElevatedButton.icon(
          onPressed: _loadCosts,
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(l10n.common_retry),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCosts,
      color: context.appPrimary,
      backgroundColor: context.appSurface,
      strokeWidth: 2.5,
      child: ListView(
        physics: AppMotion.scrollPhysics,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _buildWalletSummary(l10n),
          const SizedBox(height: AppDimensions.space12),
          _buildProfitabilityEntryCard(l10n),
          const SizedBox(height: AppDimensions.space24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              l10n.costs_expenses_title,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ),
          if (_costs.isEmpty)
            _buildEmptyState(l10n)
          else
            for (var i = 0; i < _costs.length; i++)
              StaggeredEntrance(
                index: i,
                child: _buildCostCard(_costs[i], l10n),
              ),
        ],
      ),
    );
  }

  /// Apple Wallet style summary: the crop, its total cost as the hero
  /// figure, then the unit cost and the quantity it was divided by.
  Widget _buildWalletSummary(AppLocalizations l10n) {
    final result = _perKgResult;
    const secondary = AppColors.onBrandSecondary;

    return CostWalletPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCropThumb(),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.crop.title,
                      key: const Key('crop_cost_crop_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.onBrand,
                      ),
                    ),
                    Text(
                      '${widget.crop.cropType} · ${widget.crop.municipality}, ${widget.crop.department}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space20),
          Text(
            l10n.costs_total,
            style: AppTextStyles.bodySmall.copyWith(color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatters.formatCop(_totalCost),
            key: const Key('crop_cost_total'),
            style: AppTextStyles.figureLarge.copyWith(
              fontSize: 34,
              letterSpacing: -1,
              color: AppColors.onBrand,
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: AppDimensions.space16),
            Container(
              height: 1,
              color: AppColors.onBrand.withValues(alpha: 0.16),
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPerKgFigure(l10n, result)),
                const SizedBox(width: AppDimensions.space16),
                Expanded(child: _buildDenominatorFigure(l10n, result)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerKgFigure(AppLocalizations l10n, CropCostPerKgResult result) {
    const secondary = AppColors.onBrandSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.scale, size: 14, color: secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.costs_estimated_per_kg,
                style: AppTextStyles.bodySmall.copyWith(color: secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (result.isCalculated)
          Text(
            CurrencyFormatters.formatPricePerKg(result.costPerKg),
            key: const Key('crop_cost_per_kg_value'),
            style: AppTextStyles.figureMedium.copyWith(
              fontSize: 20,
              color: AppColors.onBrand,
            ),
          )
        else
          Text(
            result.message,
            key: const Key('crop_cost_per_kg_message'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.onBrand),
          ),
      ],
    );
  }

  Widget _buildDenominatorFigure(
    AppLocalizations l10n,
    CropCostPerKgResult result,
  ) {
    const secondary = AppColors.onBrandSecondary;
    final denominatorText = result.denominator == null
        ? l10n.common_not_available
        : UnitFormatters.formatKg(result.denominator);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.costs_quantity_used(
            denominatorText,
            result.denominatorSource.displayName,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onBrand,
            fontWeight: FontWeight.w600,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.costs_source_field(result.denominatorSource.fieldName),
          style: AppTextStyles.caption.copyWith(color: secondary),
        ),
      ],
    );
  }

  Widget _buildProfitabilityEntryCard(AppLocalizations l10n) {
    return InsetGroupCard(
      key: const Key('crop_profitability_button'),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _openProfitability,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconSquircle(
                icon: LucideIcons.trendingUp,
                triad: context.appInfoTriad,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.costs_profitability_title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.costs_profitability_subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.appTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropThumb() {
    final placeholder = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.onBrand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onBrand.withValues(alpha: 0.2)),
      ),
      child: const Icon(LucideIcons.sprout, size: 20, color: AppColors.onBrand),
    );

    if (widget.crop.imageUrls.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _cropService.getPublicImageUrl(widget.crop.imageUrls.first),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  Widget _buildCostCard(CropCostModel cost, AppLocalizations l10n) {
    final error = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: InsetGroupCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            IconSquircle(
              icon: cost.category.icon,
              triad: cost.category.triad(context),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.category.toDisplayName(),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                  if (cost.description.isNotEmpty)
                    Text(
                      cost.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Text(
              CurrencyFormatters.formatCop(cost.amount),
              style: AppTextStyles.figureSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
            PopupMenuButton<String>(
              iconColor: context.appTextSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToAddOrEditCost(cost);
                } else if (value == 'delete') {
                  _deleteCost(cost);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.pencil, size: 18),
                      const SizedBox(width: AppDimensions.space12),
                      Text(l10n.common_edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 18, color: error),
                      const SizedBox(width: AppDimensions.space12),
                      Text(l10n.common_delete, style: TextStyle(color: error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return AppEmptyState(
      icon: LucideIcons.receiptText,
      title: l10n.costs_empty_detail_title,
      message: l10n.costs_empty_detail_desc,
    );
  }
}
