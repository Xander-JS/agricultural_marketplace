import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
        icon: const Icon(Icons.add),
        label: Text(l10n.costs_add),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.appError),
            const SizedBox(height: 16),
            Text(
              l10n.common_error_prefix(_errorMessage!),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCosts,
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCosts,
      child: ListView(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
        children: [
          _buildCropHeader(l10n),
          const SizedBox(height: 16),
          _buildProfitabilityEntryCard(l10n),
          const SizedBox(height: 24),
          if (_costs.isEmpty)
            _buildEmptyState(l10n)
          else
            ..._costs.map((cost) => _buildCostCard(cost, l10n)),
        ],
      ),
    );
  }

  Widget _buildCropHeader(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: context.appPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.crop.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _cropService.getPublicImageUrl(
                        widget.crop.imageUrls.first,
                      ),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    ),
                  )
                else
                  _buildPlaceholderImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.crop.title,
                        key: const Key('crop_cost_crop_title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.crop.cropType} · ${widget.crop.municipality}, ${widget.crop.department}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.costs_total,
                        style: TextStyle(
                          color: context.appOnPrimaryContainer
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatters.formatCop(_totalCost),
                        key: const Key('crop_cost_total'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.appPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerKgSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPerKgSection(AppLocalizations l10n) {
    final result = _perKgResult;
    if (result == null) return const SizedBox.shrink();

    final isCalculated = result.isCalculated;
    final denominatorText = result.denominator == null
        ? l10n.common_not_available
        : UnitFormatters.formatKg(result.denominator);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.appPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.scale_outlined,
                size: 18,
                color: context.appPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.costs_estimated_per_kg,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isCalculated)
            Text(
              CurrencyFormatters.formatPricePerKg(result.costPerKg),
              key: const Key('crop_cost_per_kg_value'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appPrimary,
              ),
            )
          else
            Text(
              result.message,
              key: const Key('crop_cost_per_kg_message'),
              style: TextStyle(color: context.appTextSecondary),
            ),
          const SizedBox(height: 4),
          Text(
            l10n.costs_quantity_used(
              denominatorText,
              result.denominatorSource.displayName,
            ),
            style: TextStyle(fontSize: 12, color: context.appTextSecondary),
          ),
          Text(
            l10n.costs_source_field(result.denominatorSource.fieldName),
            style: TextStyle(fontSize: 12, color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityEntryCard(AppLocalizations l10n) {
    return Card(
      key: const Key('crop_profitability_button'),
      margin: EdgeInsets.zero,
      color: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: context.appPrimary.withValues(alpha: 0.1),
          child: Icon(Icons.trending_up, color: context.appPrimary),
        ),
        title: Text(
          l10n.costs_profitability_title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        subtitle: Text(
          l10n.costs_profitability_subtitle,
          style: TextStyle(color: context.appTextSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: context.appTextSecondary),
        onTap: _openProfitability,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.grass, color: context.appPrimary),
    );
  }

  Widget _buildCostCard(CropCostModel cost, AppLocalizations l10n) {
    IconData getCategoryIcon(CostCategory category) {
      switch (category) {
        case CostCategory.jornales:
          return Icons.people;
        case CostCategory.fertilizantes:
          return Icons.eco;
        case CostCategory.transporte:
          return Icons.local_shipping;
        case CostCategory.otros:
          return Icons.more_horiz;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: CircleAvatar(
          backgroundColor: context.appPrimary.withValues(alpha: 0.1),
          child: Icon(
            getCategoryIcon(cost.category),
            color: context.appPrimary,
          ),
        ),
        title: Text(
          cost.category.toDisplayName(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.appTextPrimary,
          ),
        ),
        subtitle: Text(
          cost.description,
          style: TextStyle(color: context.appTextSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatters.formatCop(cost.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.appTextPrimary,
              ),
            ),
            PopupMenuButton<String>(
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
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.common_edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.common_delete,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: context.appTextDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.costs_empty_detail_title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appTextPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.costs_empty_detail_desc,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appTextSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
