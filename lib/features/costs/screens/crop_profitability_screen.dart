import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/unit_formatters.dart';
import '../../crop/models/crop_model.dart';
import '../data/simulated_regional_price_references.dart';
import '../models/regional_price_reference.dart';
import '../services/crop_cost_calculator.dart';
import '../services/profit_margin_calculator.dart';
import '../services/regional_price_reference_service.dart';

/// Calculadora orientativa de margen y precio sugerido para un cultivo.
///
/// No guarda preferencias, no modifica `pricePerKg` y no publica cambios.
class CropProfitabilityScreen extends StatefulWidget {
  final CropModel crop;
  final CropCostPerKgResult costPerKgResult;
  final RegionalPriceReferenceService? regionalReferenceService;
  final RegionalPriceReference? initialReference;

  const CropProfitabilityScreen({
    super.key,
    required this.crop,
    required this.costPerKgResult,
    this.regionalReferenceService,
    this.initialReference,
  });

  @override
  State<CropProfitabilityScreen> createState() =>
      _CropProfitabilityScreenState();
}

class _CropProfitabilityScreenState extends State<CropProfitabilityScreen> {
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _targetMarginController;
  late final RegionalPriceReferenceService _referenceService;

  RegionalPriceReference? _regionalReference;
  double? _evaluatedPrice;
  double? _targetMargin;
  bool _priceEdited = false;

  bool get _hasCurrentPrice =>
      widget.crop.pricePerKg.isFinite && widget.crop.pricePerKg > 0;

  bool get _isUsingTemporaryPrice {
    if (_evaluatedPrice == null) return false;
    if (!_hasCurrentPrice) return _priceEdited;
    return (_evaluatedPrice! - widget.crop.pricePerKg).abs() > 0.005;
  }

  @override
  void initState() {
    super.initState();
    _referenceService = widget.regionalReferenceService ?? RegionalPriceReferenceService();
    _regionalReference = widget.initialReference ??
        SimulatedRegionalPriceReferences.findForCrop(
          cropType: widget.crop.cropType,
          title: widget.crop.title,
        );
    _loadRegionalReference();

    final currentPrice = widget.crop.pricePerKg;
    _evaluatedPrice = _hasCurrentPrice ? currentPrice : null;
    _sellingPriceController = TextEditingController(
      text: _hasCurrentPrice
          ? UnitFormatters.formatCleanValue(
              currentPrice,
              useLocaleSeparators: false,
            )
          : '',
    );
    _targetMargin = 15;
    _targetMarginController = TextEditingController(text: '15');
  }

  Future<void> _loadRegionalReference() async {
    try {
      final ref = await _referenceService.findForCrop(
        cropType: widget.crop.cropType,
        title: widget.crop.title,
      );
      if (mounted && ref != null) {
        setState(() {
          _regionalReference = ref;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _targetMarginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final costPerKg = widget.costPerKgResult.isCalculated
        ? widget.costPerKgResult.costPerKg
        : null;
    final marginResult = ProfitMarginCalculator.calculateMargin(
      costPerKg: costPerKg,
      sellingPricePerKg: _evaluatedPrice,
    );
    final suggestedResult = ProfitMarginCalculator.calculateSuggestedPrice(
      costPerKg: costPerKg,
      targetMarginPercentage: _targetMargin,
    );

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(l10n.profitability_title)),
      body: Column(
        children: [
          _buildSimulatedNoticeBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCostSummary(l10n),
                  const SizedBox(height: 16),
                  if (!widget.costPerKgResult.isCalculated)
                    _buildUnavailableCard(l10n)
                  else ...[
                    _buildPriceEvaluationCard(l10n, marginResult),
                    const SizedBox(height: 16),
                    _buildSuggestedPriceCard(l10n, suggestedResult),
                  ],
                  const SizedBox(height: 16),
                  _buildRegionalReferenceCard(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.appWarningContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: context.appTextPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              SimulatedRegionalPriceReferences.notice,
              key: const Key('simulated_reference_notice'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(AppLocalizations l10n) {
    final result = widget.costPerKgResult;

    return Card(
      elevation: 0,
      color: context.appPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scale_outlined, size: 20, color: context.appPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n.profitability_cost_per_kg,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (result.isCalculated)
              Text(
                CurrencyFormatters.formatPricePerKg(result.costPerKg),
                key: const Key('profit_cost_per_kg'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.appPrimary,
                ),
              )
            else
              Text(
                result.message,
                key: const Key('profit_cost_unavailable_message'),
                style: TextStyle(color: context.appTextSecondary),
              ),
            if (result.denominator != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profitability_used_quantity(
                  UnitFormatters.formatKg(result.denominator),
                  result.denominatorSource.displayName,
                  result.denominatorSource.fieldName,
                ),
                style: TextStyle(fontSize: 12, color: context.appTextSecondary),
              ),
            ],
            Divider(height: 24, color: context.appDivider),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profitability_current_price,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                Text(
                  _hasCurrentPrice
                      ? CurrencyFormatters.formatPricePerKg(
                          widget.crop.pricePerKg,
                        )
                      : l10n.common_not_available,
                  key: const Key('profit_current_price'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
            if (!_hasCurrentPrice) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profitability_invalid_current_price,
                style: TextStyle(fontSize: 12, color: context.appTextSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableCard(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: context.appErrorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: context.appError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profitability_unavailable_title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.costPerKgResult.message,
                    style: TextStyle(color: context.appTextSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profitability_unavailable_desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceEvaluationCard(
    AppLocalizations l10n,
    ProfitMarginResult marginResult,
  ) {
    final color = marginResult.isLoss ? context.appError : context.appSuccess;

    return Card(
      color: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profitability_evaluate_title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profit_selling_price_field'),
              controller: _sellingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.profitability_selling_price,
                prefixText: '\$ ',
                suffixText: '/ kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _priceEdited = true;
                  _evaluatedPrice = CropCostCalculator.parseAmount(value);
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profitability_edit_note,
              style: TextStyle(fontSize: 12, color: context.appTextSecondary),
            ),
            if (_isUsingTemporaryPrice) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profitability_temporary_price,
                key: const Key('profit_temporary_price_note'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appWarning,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_evaluatedPrice == null)
              Text(
                l10n.profitability_invalid_price,
                key: const Key('profit_price_error'),
                style: TextStyle(
                  color: context.appError,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (marginResult.isCalculated)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marginResult.isLoss
                          ? l10n.profitability_loss_per_kg
                          : l10n.profitability_profit_per_kg,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatters.formatPricePerKg(
                        marginResult.profitPerKg,
                      ),
                      key: const Key('profit_amount_value'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profitability_margin_over_price,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                    ),
                    Text(
                      _formatPercentage(l10n, marginResult.marginPercentage),
                      key: const Key('profit_margin_value'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (marginResult.isLoss)
                      Text(
                        l10n.profitability_loss_message,
                        key: const Key('profit_loss_message'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if ((marginResult.marginPercentage ?? 0) <
                        ProfitMarginCalculator.referenceMarginPercentage)
                      Text(
                        l10n.profitability_low_margin,
                        key: const Key('profit_low_margin_warning'),
                        style: TextStyle(
                          color: context.appWarning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.profitability_margin_formula,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                marginResult.message,
                key: const Key('profit_margin_message'),
                style: TextStyle(color: context.appTextSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPriceCard(
    AppLocalizations l10n,
    SuggestedPriceResult suggestedResult,
  ) {
    return Card(
      color: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profitability_suggested_title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profit_target_margin_field'),
              controller: _targetMarginController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.profitability_target_margin,
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _targetMargin = ProfitMarginCalculator.parseMarginPercentage(
                    value,
                  );
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profitability_margin_note,
              style: TextStyle(fontSize: 12, color: context.appTextSecondary),
            ),
            const SizedBox(height: 12),
            if (_targetMargin == null)
              Text(
                l10n.profitability_invalid_margin,
                key: const Key('profit_target_margin_error'),
                style: TextStyle(
                  color: context.appError,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (suggestedResult.isCalculated) ...[
              Text(
                CurrencyFormatters.formatPricePerKg(
                  suggestedResult.suggestedPricePerKg,
                ),
                key: const Key('profit_suggested_price'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.appPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.profitability_orientation,
                style: TextStyle(
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
            ] else
              Text(
                suggestedResult.message,
                key: const Key('profit_suggested_message'),
                style: TextStyle(color: context.appTextSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalReferenceCard(AppLocalizations l10n) {
    final reference = _regionalReference;

    return Card(
      elevation: 0,
      color: context.appSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profitability_regional_reference,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                if (reference?.isSimulated == true)
                  Chip(
                    label: Text(l10n.common_simulated),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: context.appWarningContainer,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.appWarning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (reference == null)
              Text(
                l10n.profitability_reference_missing,
                key: const Key('simulated_reference_missing'),
                style: TextStyle(color: context.appTextSecondary),
              )
            else
              _buildReferenceDetails(l10n, reference),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceDetails(
    AppLocalizations l10n,
    RegionalPriceReference reference,
  ) {
    final comparison = ProfitMarginCalculator.compareToReference(
      evaluatedPricePerKg: _evaluatedPrice,
      referencePricePerKg: reference.referencePricePerKg,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(l10n.profitability_reference_crop, reference.cropName),
        _buildInfoRow(l10n.profitability_reference_region, reference.region),
        _buildInfoRow(
          l10n.profitability_reference_price,
          CurrencyFormatters.formatPricePerKg(reference.referencePricePerKg),
          valueKey: const Key('simulated_reference_price'),
        ),
        _buildInfoRow(
          l10n.profitability_reference_type,
          l10n.profitability_reference_simulated,
        ),
        Divider(height: 24, color: context.appDivider),
        if (comparison.isCalculated) ...[
          _buildInfoRow(
            l10n.profitability_reference_difference,
            CurrencyFormatters.formatPricePerKg(comparison.differencePerKg),
            valueKey: const Key('simulated_reference_difference'),
          ),
          Text(
            comparison.message,
            style: TextStyle(
              fontSize: 12,
              color: context.appTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.profitability_reference_difference_note,
            style: TextStyle(fontSize: 12, color: context.appTextSecondary),
          ),
        ] else
          Text(
            comparison.message,
            key: const Key('simulated_reference_difference_unavailable'),
            style: TextStyle(fontSize: 12, color: context.appTextSecondary),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Key? valueKey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.appTextSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercentage(AppLocalizations l10n, double? value) {
    if (value == null || !value.isFinite) return l10n.common_not_available;
    return '${UnitFormatters.formatCleanValue(value, maxDecimals: 2)} %';
  }
}
