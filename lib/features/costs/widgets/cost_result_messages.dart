import '../../../core/localization/app_localizations.dart';
import '../services/crop_cost_calculator.dart';
import '../services/profit_margin_calculator.dart';

// The calculators stay locale-free; screens show these localized messages
// built from each result's status instead of its Spanish `message`.

extension CropCostDenominatorSourceL10n on CropCostDenominatorSource {
  String localizedName(AppLocalizations l10n) => switch (this) {
    CropCostDenominatorSource.stockTotal => l10n.cost_source_stock_total,
    CropCostDenominatorSource.estimatedYieldKg =>
      l10n.cost_source_estimated_yield,
  };
}

extension CropCostPerKgResultL10n on CropCostPerKgResult {
  String localizedMessage(AppLocalizations l10n) => switch (status) {
    CropCostPerKgStatus.calculated => l10n.cost_msg_calculated,
    CropCostPerKgStatus.noCosts => l10n.cost_msg_no_costs,
    CropCostPerKgStatus.invalidCostTotal => l10n.cost_msg_invalid_total,
    CropCostPerKgStatus.invalidDenominator => l10n.cost_msg_invalid_quantity,
    CropCostPerKgStatus.estimatedYieldPending => l10n.cost_msg_yield_pending,
  };
}

extension ProfitMarginResultL10n on ProfitMarginResult {
  String localizedMessage(AppLocalizations l10n) => switch (status) {
    ProfitMarginStatus.calculated =>
      (profitPerKg ?? 0) < 0
          ? l10n.margin_msg_below_cost
          : l10n.margin_msg_calculated,
    ProfitMarginStatus.costUnavailable => l10n.margin_msg_cost_unavailable,
    ProfitMarginStatus.invalidCost => l10n.margin_msg_invalid_cost,
    ProfitMarginStatus.invalidSellingPrice =>
      sellingPricePerKg == null || !sellingPricePerKg!.isFinite
          ? l10n.margin_msg_missing_price
          : l10n.margin_msg_price_not_positive,
    ProfitMarginStatus.invalidCalculation => l10n.margin_msg_invalid_calc,
  };
}

extension SuggestedPriceResultL10n on SuggestedPriceResult {
  String localizedMessage(AppLocalizations l10n) => switch (status) {
    SuggestedPriceStatus.calculated => l10n.suggested_msg_calculated,
    SuggestedPriceStatus.costUnavailable => l10n.suggested_msg_cost_unavailable,
    SuggestedPriceStatus.invalidCost => l10n.suggested_msg_invalid_cost,
    SuggestedPriceStatus.invalidTargetMargin =>
      targetMarginPercentage == null
          ? l10n.suggested_msg_missing_margin
          : l10n.suggested_msg_margin_range,
    SuggestedPriceStatus.invalidCalculation => l10n.suggested_msg_invalid_calc,
  };
}

extension PriceComparisonResultL10n on PriceComparisonResult {
  String localizedMessage(AppLocalizations l10n) => switch (status) {
    PriceComparisonStatus.calculated =>
      (differencePerKg ?? 0) >= 0
          ? l10n.compare_msg_above
          : l10n.compare_msg_below,
    PriceComparisonStatus.invalidEvaluatedPrice =>
      l10n.compare_msg_invalid_evaluated,
    PriceComparisonStatus.invalidReferencePrice =>
      l10n.compare_msg_invalid_reference,
    PriceComparisonStatus.invalidCalculation => l10n.compare_msg_invalid_calc,
  };
}
