/// Estados posibles del cálculo de margen sobre el precio de venta.
enum ProfitMarginStatus {
  calculated,
  costUnavailable,
  invalidCost,
  invalidSellingPrice,
  invalidCalculation,
}

/// Resultado tipado del margen de ganancia por kilogramo.
class ProfitMarginResult {
  final ProfitMarginStatus status;
  final double? costPerKg;
  final double? sellingPricePerKg;
  final double? profitPerKg;
  final double? marginPercentage;
  final String message;

  const ProfitMarginResult({
    required this.status,
    required this.costPerKg,
    required this.sellingPricePerKg,
    required this.profitPerKg,
    required this.marginPercentage,
    required this.message,
  });

  bool get isCalculated => status == ProfitMarginStatus.calculated;

  bool get isLoss => isCalculated && (profitPerKg ?? 0) < 0;
}

/// Estados posibles del cálculo del precio sugerido.
enum SuggestedPriceStatus {
  calculated,
  costUnavailable,
  invalidCost,
  invalidTargetMargin,
  invalidCalculation,
}

/// Resultado tipado del precio sugerido según un margen objetivo.
class SuggestedPriceResult {
  final SuggestedPriceStatus status;
  final double? costPerKg;
  final double? targetMarginPercentage;
  final double? suggestedPricePerKg;
  final String message;

  const SuggestedPriceResult({
    required this.status,
    required this.costPerKg,
    required this.targetMarginPercentage,
    required this.suggestedPricePerKg,
    required this.message,
  });

  bool get isCalculated => status == SuggestedPriceStatus.calculated;
}

/// Estados posibles de la comparación contra una referencia simulada.
enum PriceComparisonStatus {
  calculated,
  invalidEvaluatedPrice,
  invalidReferencePrice,
  invalidCalculation,
}

/// Resultado tipado de la diferencia entre dos precios por kilogramo.
class PriceComparisonResult {
  final PriceComparisonStatus status;
  final double? evaluatedPricePerKg;
  final double? referencePricePerKg;
  final double? differencePerKg;
  final double? percentageDifference;
  final String message;

  const PriceComparisonResult({
    required this.status,
    required this.evaluatedPricePerKg,
    required this.referencePricePerKg,
    required this.differencePerKg,
    required this.percentageDifference,
    required this.message,
  });

  bool get isCalculated => status == PriceComparisonStatus.calculated;

  bool get isAboveReference => isCalculated && (differencePerKg ?? 0) > 0;
}

/// Cálculos puros de margen, precio sugerido y comparación de referencias.
///
/// Todas las fórmulas usan el margen sobre el precio de venta, no un recargo
/// sobre el costo. No accede a Supabase ni modifica el precio publicado.
abstract final class ProfitMarginCalculator {
  static const double referenceMarginPercentage = 15;

  /// Calcula la ganancia y el margen porcentual sobre el precio de venta.
  ///
  /// `margen = ((precioVenta - costoPorKg) / precioVenta) * 100`.
  static ProfitMarginResult calculateMargin({
    required double? costPerKg,
    required double? sellingPricePerKg,
  }) {
    if (costPerKg == null) {
      return const ProfitMarginResult(
        status: ProfitMarginStatus.costUnavailable,
        costPerKg: null,
        sellingPricePerKg: null,
        profitPerKg: null,
        marginPercentage: null,
        message: 'No se puede calcular el margen porque el costo por kg no está disponible.',
      );
    }

    if (!costPerKg.isFinite || costPerKg < 0) {
      return ProfitMarginResult(
        status: ProfitMarginStatus.invalidCost,
        costPerKg: costPerKg,
        sellingPricePerKg: sellingPricePerKg,
        profitPerKg: null,
        marginPercentage: null,
        message: 'No se puede calcular el margen porque el costo por kg no es válido.',
      );
    }

    if (sellingPricePerKg == null) {
      return ProfitMarginResult(
        status: ProfitMarginStatus.invalidSellingPrice,
        costPerKg: costPerKg,
        sellingPricePerKg: null,
        profitPerKg: null,
        marginPercentage: null,
        message: 'No se puede calcular el margen porque falta un precio de venta válido.',
      );
    }

    if (!sellingPricePerKg.isFinite || sellingPricePerKg <= 0) {
      return ProfitMarginResult(
        status: ProfitMarginStatus.invalidSellingPrice,
        costPerKg: costPerKg,
        sellingPricePerKg: sellingPricePerKg,
        profitPerKg: null,
        marginPercentage: null,
        message: 'No se puede calcular el margen porque el precio de venta debe ser mayor que cero.',
      );
    }

    final profitPerKg = sellingPricePerKg - costPerKg;
    final marginPercentage = (profitPerKg / sellingPricePerKg) * 100;

    if (!profitPerKg.isFinite || !marginPercentage.isFinite) {
      return ProfitMarginResult(
        status: ProfitMarginStatus.invalidCalculation,
        costPerKg: costPerKg,
        sellingPricePerKg: sellingPricePerKg,
        profitPerKg: null,
        marginPercentage: null,
        message: 'No se pudo calcular el margen con los valores ingresados.',
      );
    }

    return ProfitMarginResult(
      status: ProfitMarginStatus.calculated,
      costPerKg: costPerKg,
      sellingPricePerKg: sellingPricePerKg,
      profitPerKg: profitPerKg,
      marginPercentage: marginPercentage,
      message: profitPerKg < 0
          ? 'El precio de venta está por debajo del costo de producción.'
          : 'Margen calculado sobre el precio de venta.',
    );
  }

  /// Calcula el precio sugerido con `precio = costo / (1 - margen / 100)`.
  static SuggestedPriceResult calculateSuggestedPrice({
    required double? costPerKg,
    required double? targetMarginPercentage,
  }) {
    if (costPerKg == null) {
      return const SuggestedPriceResult(
        status: SuggestedPriceStatus.costUnavailable,
        costPerKg: null,
        targetMarginPercentage: null,
        suggestedPricePerKg: null,
        message: 'No se puede calcular el precio sugerido porque el costo por kg no está disponible.',
      );
    }

    if (!costPerKg.isFinite || costPerKg <= 0) {
      return SuggestedPriceResult(
        status: SuggestedPriceStatus.invalidCost,
        costPerKg: costPerKg,
        targetMarginPercentage: targetMarginPercentage,
        suggestedPricePerKg: null,
        message: 'No se puede calcular el precio sugerido porque el costo por kg debe ser mayor que cero.',
      );
    }

    if (targetMarginPercentage == null) {
      return SuggestedPriceResult(
        status: SuggestedPriceStatus.invalidTargetMargin,
        costPerKg: costPerKg,
        targetMarginPercentage: null,
        suggestedPricePerKg: null,
        message: 'No se puede calcular el precio sugerido porque falta el margen objetivo.',
      );
    }

    if (!targetMarginPercentage.isFinite ||
        targetMarginPercentage < 0 ||
        targetMarginPercentage >= 100) {
      return SuggestedPriceResult(
        status: SuggestedPriceStatus.invalidTargetMargin,
        costPerKg: costPerKg,
        targetMarginPercentage: targetMarginPercentage,
        suggestedPricePerKg: null,
        message: 'El margen objetivo debe ser mayor o igual que 0 % y menor que 100 %.',
      );
    }

    final factor = 1 - (targetMarginPercentage / 100);
    if (!factor.isFinite || factor <= 0) {
      return SuggestedPriceResult(
        status: SuggestedPriceStatus.invalidTargetMargin,
        costPerKg: costPerKg,
        targetMarginPercentage: targetMarginPercentage,
        suggestedPricePerKg: null,
        message: 'El margen objetivo debe ser mayor o igual que 0 % y menor que 100 %.',
      );
    }

    final suggestedPricePerKg = costPerKg / factor;
    if (!suggestedPricePerKg.isFinite || suggestedPricePerKg <= 0) {
      return SuggestedPriceResult(
        status: SuggestedPriceStatus.invalidCalculation,
        costPerKg: costPerKg,
        targetMarginPercentage: targetMarginPercentage,
        suggestedPricePerKg: null,
        message: 'No se pudo calcular un precio sugerido válido con los valores ingresados.',
      );
    }

    return SuggestedPriceResult(
      status: SuggestedPriceStatus.calculated,
      costPerKg: costPerKg,
      targetMarginPercentage: targetMarginPercentage,
      suggestedPricePerKg: suggestedPricePerKg,
      message: 'Precio sugerido según el margen objetivo.',
    );
  }

  /// Convierte el texto de margen objetivo en un porcentaje válido `[0, 100)`.
  static double? parseMarginPercentage(String? raw) {
    if (raw == null) return null;

    final value = raw.trim().replaceAll('%', '').replaceAll(' ', '');
    if (value.isEmpty || !RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(value)) {
      return null;
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed < 0 || parsed >= 100) {
      return null;
    }

    return parsed;
  }

  /// Compara el precio evaluado con una referencia simulada.
  static PriceComparisonResult compareToReference({
    required double? evaluatedPricePerKg,
    required double? referencePricePerKg,
  }) {
    if (evaluatedPricePerKg == null ||
        !evaluatedPricePerKg.isFinite ||
        evaluatedPricePerKg <= 0) {
      return PriceComparisonResult(
        status: PriceComparisonStatus.invalidEvaluatedPrice,
        evaluatedPricePerKg: evaluatedPricePerKg,
        referencePricePerKg: referencePricePerKg,
        differencePerKg: null,
        percentageDifference: null,
        message:
            'No hay un precio evaluado válido para comparar con la referencia.',
      );
    }

    if (referencePricePerKg == null ||
        !referencePricePerKg.isFinite ||
        referencePricePerKg <= 0) {
      return PriceComparisonResult(
        status: PriceComparisonStatus.invalidReferencePrice,
        evaluatedPricePerKg: evaluatedPricePerKg,
        referencePricePerKg: referencePricePerKg,
        differencePerKg: null,
        percentageDifference: null,
        message: 'La referencia de precio no es válida para realizar la comparación.',
      );
    }

    final differencePerKg = evaluatedPricePerKg - referencePricePerKg;
    final percentageDifference = (differencePerKg / referencePricePerKg) * 100;

    if (!differencePerKg.isFinite || !percentageDifference.isFinite) {
      return PriceComparisonResult(
        status: PriceComparisonStatus.invalidCalculation,
        evaluatedPricePerKg: evaluatedPricePerKg,
        referencePricePerKg: referencePricePerKg,
        differencePerKg: null,
        percentageDifference: null,
        message:
            'No se pudo calcular la diferencia con los valores ingresados.',
      );
    }

    return PriceComparisonResult(
      status: PriceComparisonStatus.calculated,
      evaluatedPricePerKg: evaluatedPricePerKg,
      referencePricePerKg: referencePricePerKg,
      differencePerKg: differencePerKg,
      percentageDifference: percentageDifference,
      message: differencePerKg >= 0
          ? 'El precio evaluado está por encima de la referencia simulada.'
          : 'El precio evaluado está por debajo de la referencia simulada.',
    );
  }
}
