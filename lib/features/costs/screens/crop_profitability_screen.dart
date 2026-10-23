import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../widgets/cost_wallet_panel.dart';
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
    _referenceService =
        widget.regionalReferenceService ?? RegionalPriceReferenceService();
    _regionalReference =
        widget.initialReference ??
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
          _buildReferenceNoticeBanner(),
          Expanded(
            child: SingleChildScrollView(
              physics: AppMotion.scrollPhysics,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCostSummary(l10n),
                  const SizedBox(height: AppDimensions.space12),
                  if (!widget.costPerKgResult.isCalculated)
                    _buildUnavailableCard(l10n)
                  else ...[
                    _buildPriceEvaluationCard(l10n, marginResult),
                    const SizedBox(height: AppDimensions.space12),
                    _buildSuggestedPriceCard(l10n, suggestedResult),
                  ],
                  const SizedBox(height: AppDimensions.space12),
                  _buildRegionalReferenceCard(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceNoticeBanner() {
    final l10n = AppLocalizations.of(context)!;
    final triad = context.appInfoTriad;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: triad.background,
        border: Border(bottom: BorderSide(color: triad.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.sparkles,
              size: 16,
              color: triad.foreground,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.profitability_reference_notice,
              key: const Key('simulated_reference_notice'),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card heading shared by the calculator cards: tinted squircle + title.
  Widget _buildCardHeader(String title, IconData icon, AppSemanticTriad triad) {
    return Row(
      children: [
        IconSquircle(icon: icon, triad: triad, size: 32),
        const SizedBox(width: AppDimensions.space12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.appTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostSummary(AppLocalizations l10n) {
    final result = widget.costPerKgResult;
    const secondary = AppColors.onBrandSecondary;

    return CostWalletPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.scale, size: 16, color: secondary),
              const SizedBox(width: 6),
              Text(
                l10n.profitability_cost_per_kg,
                style: AppTextStyles.bodySmall.copyWith(color: secondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (result.isCalculated)
            Text(
              CurrencyFormatters.formatPricePerKg(result.costPerKg),
              key: const Key('profit_cost_per_kg'),
              style: AppTextStyles.figureLarge.copyWith(
                fontSize: 32,
                letterSpacing: -1,
                color: AppColors.onBrand,
              ),
            )
          else
            Text(
              result.message,
              key: const Key('profit_cost_unavailable_message'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onBrand,
              ),
            ),
          if (result.denominator != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.profitability_used_quantity(
                UnitFormatters.formatKg(result.denominator),
                result.denominatorSource.displayName,
                result.denominatorSource.fieldName,
              ),
              style: AppTextStyles.caption.copyWith(
                color: secondary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space16),
          Container(
            height: 1,
            color: AppColors.onBrand.withValues(alpha: 0.16),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profitability_current_price,
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
              ),
              Text(
                _hasCurrentPrice
                    ? CurrencyFormatters.formatPricePerKg(
                        widget.crop.pricePerKg,
                      )
                    : l10n.common_not_available,
                key: const Key('profit_current_price'),
                style: AppTextStyles.figureSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBrand,
                ),
              ),
            ],
          ),
          if (!_hasCurrentPrice) ...[
            const SizedBox(height: 4),
            Text(
              l10n.profitability_invalid_current_price,
              style: AppTextStyles.caption.copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(AppLocalizations l10n) {
    final triad = context.appErrorTriad;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius),
        border: Border.all(color: triad.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circleAlert, size: 20, color: triad.foreground),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profitability_unavailable_title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.costPerKgResult.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.profitability_unavailable_desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceEvaluationCard(
    AppLocalizations l10n,
    ProfitMarginResult marginResult,
  ) {
    // Success green when the evaluated price leaves a profit, coral red
    // when it does not cover the production cost.
    final outcome = marginResult.isLoss
        ? context.appErrorTriad
        : context.appSuccessTriad;

    return InsetGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(
            l10n.profitability_evaluate_title,
            LucideIcons.coins,
            context.appBrandTriad,
          ),
          const SizedBox(height: AppDimensions.space16),
          TextFormField(
            key: const Key('profit_selling_price_field'),
            controller: _sellingPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.figureMedium.copyWith(
              color: context.appTextPrimary,
            ),
            decoration: InputDecoration(
              labelText: l10n.profitability_selling_price,
              prefixText: '\$ ',
              suffixText: '/ kg',
            ),
            onChanged: (value) {
              setState(() {
                _priceEdited = true;
                _evaluatedPrice = CropCostCalculator.parseAmount(value);
              });
            },
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            l10n.profitability_edit_note,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          if (_isUsingTemporaryPrice) ...[
            const SizedBox(height: 4),
            Text(
              l10n.profitability_temporary_price,
              key: const Key('profit_temporary_price_note'),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appWarningText,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space16),
          if (_evaluatedPrice == null)
            Text(
              l10n.profitability_invalid_price,
              key: const Key('profit_price_error'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appErrorText,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (marginResult.isCalculated)
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.standard),
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: outcome.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outcome.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _OutcomeFigure(
                            label: marginResult.isLoss
                                ? l10n.profitability_loss_per_kg
                                : l10n.profitability_profit_per_kg,
                            value: CurrencyFormatters.formatPricePerKg(
                              marginResult.profitPerKg,
                            ),
                            valueKey: const Key('profit_amount_value'),
                            color: outcome.text,
                            icon: marginResult.isLoss
                                ? LucideIcons.trendingDown
                                : LucideIcons.trendingUp,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: _OutcomeFigure(
                            label: l10n.profitability_margin_over_price,
                            value: _formatPercentage(
                              l10n,
                              marginResult.marginPercentage,
                            ),
                            valueKey: const Key('profit_margin_value'),
                            color: outcome.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (marginResult.isLoss) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      l10n.profitability_loss_message,
                      key: const Key('profit_loss_message'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: outcome.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if ((marginResult.marginPercentage ?? 0) <
                      ProfitMarginCalculator.referenceMarginPercentage) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(
                      l10n.profitability_low_margin,
                      key: const Key('profit_low_margin_warning'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appWarningText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    l10n.profitability_margin_formula,
                    style: AppTextStyles.caption.copyWith(
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPriceCard(
    AppLocalizations l10n,
    SuggestedPriceResult suggestedResult,
  ) {
    return InsetGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(
            l10n.profitability_suggested_title,
            LucideIcons.target,
            context.appInfoTriad,
          ),
          const SizedBox(height: AppDimensions.space16),
          TextFormField(
            key: const Key('profit_target_margin_field'),
            controller: _targetMarginController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.figureMedium.copyWith(
              color: context.appTextPrimary,
            ),
            decoration: InputDecoration(
              labelText: l10n.profitability_target_margin,
              suffixText: '%',
            ),
            onChanged: (value) {
              setState(() {
                _targetMargin = ProfitMarginCalculator.parseMarginPercentage(
                  value,
                );
              });
            },
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            l10n.profitability_margin_note,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          if (_targetMargin == null)
            Text(
              l10n.profitability_invalid_margin,
              key: const Key('profit_target_margin_error'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appErrorText,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (suggestedResult.isCalculated)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appPrimarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBrandTriad.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatters.formatPricePerKg(
                      suggestedResult.suggestedPricePerKg,
                    ),
                    key: const Key('profit_suggested_price'),
                    style: AppTextStyles.figureLarge.copyWith(
                      fontSize: 28,
                      color: context.appOnPrimarySoft,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profitability_orientation,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              suggestedResult.message,
              key: const Key('profit_suggested_message'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionalReferenceCard(AppLocalizations l10n) {
    final reference = _regionalReference;
    final info = context.appInfoTriad;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius),
        border: Border.all(color: info.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                icon: LucideIcons.trendingUp,
                triad: AppSemanticTriad(
                  background: context.appSurface,
                  border: info.border,
                  foreground: info.foreground,
                ),
                size: 32,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  l10n.profitability_regional_reference,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              if (reference?.isSimulated == true) ...[
                const SizedBox(width: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: info.border),
                  ),
                  child: Text(
                    l10n.common_simulated,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: info.text,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          if (reference == null)
            Text(
              l10n.profitability_reference_missing,
              key: const Key('simulated_reference_missing'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            )
          else
            _buildReferenceDetails(l10n, reference),
        ],
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
    final difference = comparison.differencePerKg ?? 0;
    final differenceColor = !comparison.isCalculated || difference == 0
        ? context.appTextPrimary
        : difference > 0
        ? context.appSuccessText
        : context.appErrorText;

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
        Divider(height: 20, color: context.appInfoTriad.border),
        if (comparison.isCalculated) ...[
          _buildInfoRow(
            l10n.profitability_reference_difference,
            CurrencyFormatters.formatPricePerKg(comparison.differencePerKg),
            valueKey: const Key('simulated_reference_difference'),
            valueColor: differenceColor,
          ),
          Text(
            comparison.message,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.profitability_reference_difference_note,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ] else
          Text(
            comparison.message,
            key: const Key('simulated_reference_difference_unavailable'),
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Key? valueKey,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Flexible(
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: AppTextStyles.figureSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? context.appTextPrimary,
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

/// One outcome figure in the evaluation result: label, then the value in
/// the outcome tint with tabular figures.
class _OutcomeFigure extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  final Color color;
  final IconData? icon;

  const _OutcomeFigure({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Labels may wrap to different line counts; the values stay on one
    // shared line at the bottom of the pair.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  key: valueKey,
                  style: AppTextStyles.figureLarge.copyWith(
                    fontSize: 20,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
