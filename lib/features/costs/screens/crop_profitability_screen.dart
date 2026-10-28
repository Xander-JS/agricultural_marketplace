import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/brand/topo_contours_painter.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/inputs/app_segmented_control.dart';
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
import '../../../core/constants/input_limits.dart';
import '../widgets/cost_result_messages.dart';

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
  _ProfitView _view = _ProfitView.evaluate;

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

    final isCalculated = widget.costPerKgResult.isCalculated;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(l10n.profitability_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: AppSegmentedControl<_ProfitView>(
                key: const Key('profit_view_selector'),
                value: _view,
                onChanged: _selectView,
                segments: {
                  _ProfitView.evaluate: AppSegment(
                    label: l10n.profitability_tab_evaluate,
                  ),
                  _ProfitView.suggested: AppSegment(
                    label: l10n.profitability_tab_suggested,
                  ),
                  _ProfitView.regional: AppSegment(
                    label: l10n.profitability_tab_regional,
                  ),
                },
              ),
            ),
          ),
          Expanded(
            child: _SlidingPanels(
              index: _view.index,
              children: [
                _buildPanel([
                  _buildCostSummary(l10n),
                  const SizedBox(height: AppDimensions.space12),
                  if (isCalculated)
                    _buildPriceEvaluationCard(l10n, marginResult)
                  else
                    _buildUnavailableCard(l10n),
                ]),
                _buildPanel([
                  if (isCalculated)
                    _buildSuggestedPriceCard(l10n, suggestedResult, costPerKg)
                  else
                    _buildSuggestedUnavailable(l10n),
                ]),
                _buildPanel([_buildRegionalReferenceCard(l10n, costPerKg)]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectView(_ProfitView view) {
    // A field left focused in the outgoing view would keep the keyboard
    // over a panel the user can no longer see.
    FocusScope.of(context).unfocus();
    setState(() => _view = view);
  }

  /// One view of the calculator: its own scroll, so switching views never
  /// lands the user halfway down another view's content.
  Widget _buildPanel(List<Widget> children) {
    return SingleChildScrollView(
      physics: AppMotion.scrollPhysics,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSuggestedUnavailable(AppLocalizations l10n) {
    final triad = context.appNeutralTriad;
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
          Icon(LucideIcons.target, size: 20, color: triad.foreground),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              l10n.profitability_suggested_unavailable,
              key: const Key('profit_suggested_unavailable'),
              style: AppTextStyles.bodyMedium.copyWith(
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
              result.localizedMessage(l10n),
              key: const Key('profit_cost_unavailable_message'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onBrand,
              ),
            ),
          if (result.denominator != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.costs_quantity_used(
                UnitFormatters.formatKg(result.denominator),
                result.denominatorSource.localizedName(l10n),
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
              const SizedBox(width: AppDimensions.space12),
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
                  widget.costPerKgResult.localizedMessage(l10n),
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
            context.appIconTriad,
          ),
          const SizedBox(height: AppDimensions.space16),
          TextFormField(
            key: const Key('profit_selling_price_field'),
            controller: _sellingPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              // Room for the digits plus thousands/decimal marks.
              LengthLimitingTextInputFormatter(
                InputLimits.pricePerKgDigits + 5,
              ),
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
              marginResult.localizedMessage(l10n),
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
    double? costPerKg,
  ) {
    return InsetGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(
            l10n.profitability_suggested_title,
            LucideIcons300.target,
            context.appIconTriad,
          ),
          const SizedBox(height: AppDimensions.space16),
          TextFormField(
            key: const Key('profit_target_margin_field'),
            controller: _targetMarginController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(InputLimits.percentChars),
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
            // Weighbridge ticket: the inputs as dotted-leader lines, a
            // perforation, then the one figure the farmer takes away.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: BoxDecoration(
                color: context.appPrimarySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBrandTriad.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TicketLine(
                    label: l10n.profitability_ticket_cost_base,
                    value: CurrencyFormatters.formatPricePerKg(costPerKg),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _TicketLine(
                    label: l10n.profitability_ticket_target_margin,
                    value: _formatPercentage(l10n, _targetMargin),
                  ),
                  const SizedBox(height: 14),
                  _Perforation(color: context.appBrandTriad.border),
                  const SizedBox(height: 14),
                  Text(
                    l10n.profitability_ticket_result,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appOnPrimarySoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatters.formatPricePerKg(
                        suggestedResult.suggestedPricePerKg,
                      ),
                      key: const Key('profit_suggested_price'),
                      style: AppTextStyles.figureLarge.copyWith(
                        fontSize: 30,
                        letterSpacing: -0.6,
                        color: context.appOnPrimarySoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
              suggestedResult.localizedMessage(l10n),
              key: const Key('profit_suggested_message'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionalReferenceCard(AppLocalizations l10n, double? costPerKg) {
    final reference = _regionalReference;
    final neutral = context.appNeutralTriad;

    // Neutral ground: the index is a reference, not a recommendation, so
    // it reads as quiet tabular data next to the farmer's own figures.
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: neutral.background,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius),
        border: Border.all(
          color: neutral.border,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                icon: LucideIcons300.trendingUp,
                triad: AppSemanticTriad(
                  background: context.appSurface,
                  border: neutral.border,
                  foreground: neutral.foreground,
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
                    border: Border.all(color: neutral.border),
                  ),
                  child: Text(
                    l10n.common_simulated,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: neutral.foreground,
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
          else ...[
            _RegionalComparisonChart(
              evaluatedPrice: _evaluatedPrice,
              referencePrice: reference.referencePricePerKg,
              costPerKg: costPerKg,
            ),
            const SizedBox(height: AppDimensions.space16),
            _buildReferenceDetails(l10n, reference),
          ],
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
        Divider(height: 20, color: context.appBorder),
        if (comparison.isCalculated) ...[
          _buildInfoRow(
            l10n.profitability_reference_difference,
            CurrencyFormatters.formatPricePerKg(comparison.differencePerKg),
            valueKey: const Key('simulated_reference_difference'),
            valueColor: differenceColor,
          ),
          Text(
            comparison.localizedMessage(l10n),
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
            comparison.localizedMessage(l10n),
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
    // Fixed label and value columns: every value starts on the same line,
    // so a long text value wraps in place instead of drifting right.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                color: context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.start,
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

/// The three views of the calculator, in the order a farmer prices a lot:
/// test a price, see what the target margin asks for, compare with Nariño.
enum _ProfitView { evaluate, suggested, regional }

/// Horizontal pager driven by the segmented control.
///
/// Every view stays mounted so typed values and scroll positions survive a
/// switch, and the outgoing and incoming views slide together on the iOS
/// drawer curve. A tap mid-slide retargets from the current position
/// instead of restarting. Views off screen take no pointer, semantics or
/// ticker time and are not painted.
class _SlidingPanels extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const _SlidingPanels({required this.index, required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: index.toDouble()),
            duration: AppMotion.of(context, AppMotion.emphasized),
            curve: AppMotion.drawer,
            builder: (context, position, _) {
              return Stack(
                children: [
                  for (var i = 0; i < children.length; i++)
                    _panel(i, position, width),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _panel(int i, double position, double width) {
    final active = i == index;
    final onScreen = (i - position).abs() < 1;
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset((i - position) * width, 0),
        child: IgnorePointer(
          ignoring: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: TickerMode(
              enabled: onScreen,
              child: Opacity(opacity: onScreen ? 1 : 0, child: children[i]),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Label ........ value" line of a weighbridge ticket, value in tabular
/// figures so amounts line up down the slip.
class _TicketLine extends StatelessWidget {
  final String label;
  final String value;

  const _TicketLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final ink = context.appOnPrimarySoft;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: context.appTextSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 2,
              child: CustomPaint(
                painter: _DotLeaderPainter(color: context.appBrandTriad.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTextStyles.figureSmall.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ],
    );
  }
}

class _DotLeaderPainter extends CustomPainter {
  final Color color;

  const _DotLeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.height / 2;
    for (double x = radius; x < size.width; x += 5) {
      canvas.drawCircle(Offset(x, radius), radius * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotLeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Tear line between the inputs and the result of the ticket.
class _Perforation extends StatelessWidget {
  final Color color;

  const _Perforation({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color: color)),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 5, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Evaluated price, regional index and production cost as bars on one
/// scale, over the Nariño contour lines.
class _RegionalComparisonChart extends StatelessWidget {
  final double? evaluatedPrice;
  final double referencePrice;
  final double? costPerKg;

  const _RegionalComparisonChart({
    required this.evaluatedPrice,
    required this.referencePrice,
    required this.costPerKg,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bars = <({String label, double value, Color color})>[
      if (_isValid(evaluatedPrice))
        (
          label: l10n.profitability_chart_evaluated,
          value: evaluatedPrice!,
          color: context.appPrimary,
        ),
      if (_isValid(referencePrice))
        (
          label: l10n.profitability_chart_reference,
          value: referencePrice,
          color: context.appTextPrimary,
        ),
      if (_isValid(costPerKg))
        (
          label: l10n.profitability_chart_cost,
          value: costPerKg!,
          color: context.appTextSecondary,
        ),
    ];
    if (bars.isEmpty) return const SizedBox.shrink();

    final scale = bars.map((b) => b.value).reduce(math.max);

    return Container(
      key: const Key('profit_regional_chart'),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: _ContourBackdrop(color: context.appTextMuted),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                children: [
                  for (var i = 0; i < bars.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _ComparisonBar(
                      label: bars[i].label,
                      value: bars[i].value,
                      fraction: bars[i].value / scale,
                      color: bars[i].color,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isValid(double? v) => v != null && v.isFinite && v > 0;
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final double value;
  final double fraction;
  final Color color;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: context.appTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              CurrencyFormatters.formatCop(value),
              style: AppTextStyles.figureSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bars retarget from where they are when the evaluated price
        // changes, so typing reads as one continuous adjustment.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: fraction.clamp(0.0, 1.0)),
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.easeOut,
          builder: (context, f, _) => SizedBox(
            height: 8,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarPainter(
                fraction: f,
                color: color,
                track: context.appDivider.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;

  const _BarPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    final width = size.width * fraction;
    if (width <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, math.max(width, size.height), size.height),
        radius,
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}

/// Nariño contour lines behind the chart. They settle into place each time
/// the regional view comes on screen, a single slow drift that marks the
/// change of view and then stays still while the farmer reads. Static
/// under Reduce Motion.
class _ContourBackdrop extends StatefulWidget {
  final Color color;

  const _ContourBackdrop({required this.color});

  @override
  State<_ContourBackdrop> createState() => _ContourBackdropState();
}

class _ContourBackdropState extends State<_ContourBackdrop>
    with SingleTickerProviderStateMixin {
  // Decorative and seen only when the view opens, so it may run longer
  // than UI feedback; it never blocks reading or input.
  static const Duration _drift = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _drift,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.easeOut,
  );
  bool _wasOnScreen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onScreen = TickerMode.valuesOf(context).enabled;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else if (onScreen && !_wasOnScreen) {
      _controller.forward(from: 0);
    }
    _wasOnScreen = onScreen;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) {
            final t = _progress.value;
            return Opacity(
              opacity: 0.35 + 0.65 * t,
              child: Transform.translate(
                offset: Offset(-18 * (1 - t), 10 * (1 - t)),
                child: child,
              ),
            );
          },
          child: CustomPaint(
            painter: TopoContoursPainter(color: widget.color, intensity: 0.22),
          ),
        ),
      ),
    );
  }
}
