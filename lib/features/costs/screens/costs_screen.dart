import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
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
        title: Text(l10n.costs_title),
      ),
      body: _buildBody(l10n),
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
              onPressed: _loadData,
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      );
    }

    if (_crops.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _crops.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                l10n.costs_intro,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.appTextSecondary,
                    ),
              ),
            );
          }
          final crop = _crops[index - 1];
          final totalCost = _cropTotals[crop.id] ?? 0.0;
          return _buildCropCard(crop, totalCost, l10n);
        },
      ),
    );
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

  Widget _buildCropCard(
    CropModel crop,
    double totalCost,
    AppLocalizations l10n,
  ) {
    final perKg = CropCostCalculator.calculatePerKg(
      crop: crop,
      totalCost: totalCost,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appBorder),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (crop.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _cropService.getPublicImageUrl(crop.imageUrls.first),
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
                        crop.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.costs_total,
                        style: TextStyle(color: context.appTextSecondary),
                      ),
                      Text(
                        CurrencyFormatters.formatCop(totalCost),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.appPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _perKgSummary(l10n, perKg),
                        style: TextStyle(
                          color: context.appTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (perKg.denominator != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${UnitFormatters.formatKg(perKg.denominator)} · ${perKg.denominatorSource.displayName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToDetail(crop),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.costs_view),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: context.appTextDisabled,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 80,
              color: context.appTextDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.costs_empty_title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.costs_empty_desc,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.appTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateCrop,
              icon: const Icon(Icons.add),
              label: Text(l10n.costs_create_crop),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
