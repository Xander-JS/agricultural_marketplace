import '../../crop/models/crop_model.dart';
import '../models/crop_cost_model.dart';

/// Origen de la cantidad usada como denominador del costo por kilogramo.
enum CropCostDenominatorSource {
  stockTotal,
  estimatedYieldKg;

  /// Nombre del campo real utilizado en el cálculo.
  String get fieldName {
    switch (this) {
      case CropCostDenominatorSource.stockTotal:
        return 'stock_total';
      case CropCostDenominatorSource.estimatedYieldKg:
        return 'estimated_yield_kg';
    }
  }

  /// Nombre comprensible para mostrar en la interfaz.
  String get displayName {
    switch (this) {
      case CropCostDenominatorSource.stockTotal:
        return 'stock total';
      case CropCostDenominatorSource.estimatedYieldKg:
        return 'rendimiento estimado';
    }
  }
}

/// Estados posibles del cálculo de costo por kilogramo.
enum CropCostPerKgStatus {
  calculated,
  noCosts,
  invalidCostTotal,
  invalidDenominator,
  estimatedYieldPending,
}

/// Resultado explícito del cálculo de costo por kilogramo.
class CropCostPerKgResult {
  final CropCostPerKgStatus status;
  final double? costPerKg;
  final double? denominator;
  final CropCostDenominatorSource denominatorSource;
  final String message;

  const CropCostPerKgResult({
    required this.status,
    required this.costPerKg,
    required this.denominator,
    required this.denominatorSource,
    required this.message,
  });

  bool get isCalculated => status == CropCostPerKgStatus.calculated;
}

/// Cálculos puros y testeables de costos de producción.
///
/// No accede a Supabase ni a la interfaz. Las pantallas y el servicio reutilizan
/// estas funciones para evitar duplicar las fórmulas.
abstract final class CropCostCalculator {
  static const String noCostsMessage =
      'Aún no hay costos registrados. Agrega un costo para calcular el costo por kg.';

  /// Suma los importes de una colección de costos sin contar dos veces un
  /// registro con el mismo identificador.
  static double totalOf(Iterable<CropCostModel> costs) {
    final seenIds = <String>{};
    final amounts = <num>[];

    for (final cost in costs) {
      if (cost.id.isNotEmpty && !seenIds.add(cost.id)) continue;
      amounts.add(cost.amount);
    }

    return totalFromAmounts(amounts);
  }

  /// Suma únicamente los costos que pertenecen al cultivo indicado.
  static double totalForCrop(Iterable<CropCostModel> costs, String cropId) {
    return totalOf(costs.where((cost) => cost.cropId == cropId));
  }

  /// Suma importes ya extraídos, rechazando valores no finitos o negativos.
  static double totalFromAmounts(Iterable<num> amounts) {
    var total = 0.0;

    for (final amount in amounts) {
      final value = amount.toDouble();
      if (!value.isFinite || value < 0) {
        throw const FormatException('Importe de costo inválido.');
      }
      total += value;
    }

    if (!total.isFinite) {
      throw const FormatException('Total de costos inválido.');
    }

    return total;
  }

  /// Calcula el costo por kilogramo con las reglas del proyecto.
  ///
  /// - Cosecha regular: `costoTotal / stock_total`.
  /// - Venta anticipada: `costoTotal / estimated_yield_kg`.
  ///
  /// Nunca usa `availableStock`, `stock_committed` ni `stock_sold` como
  /// denominador. Si una venta anticipada no tiene rendimiento estimado, el
  /// resultado queda pendiente y no se reemplaza por `stock_total`.
  static CropCostPerKgResult calculatePerKg({
    required CropModel crop,
    required double totalCost,
  }) {
    final source = crop.isEarlySale
        ? CropCostDenominatorSource.estimatedYieldKg
        : CropCostDenominatorSource.stockTotal;
    final rawDenominator = crop.isEarlySale
        ? crop.estimatedYieldKg
        : crop.stockTotal;
    final reportedDenominator =
        rawDenominator != null && rawDenominator.isFinite
        ? rawDenominator
        : null;

    if (!totalCost.isFinite || totalCost < 0) {
      return CropCostPerKgResult(
        status: CropCostPerKgStatus.invalidCostTotal,
        costPerKg: null,
        denominator: reportedDenominator,
        denominatorSource: source,
        message: 'No se puede calcular el costo por kg porque el total de costos no es válido.',
      );
    }

    if (totalCost == 0) {
      return CropCostPerKgResult(
        status: CropCostPerKgStatus.noCosts,
        costPerKg: null,
        denominator: reportedDenominator,
        denominatorSource: source,
        message: noCostsMessage,
      );
    }

    if (crop.isEarlySale && rawDenominator == null) {
      return CropCostPerKgResult(
        status: CropCostPerKgStatus.estimatedYieldPending,
        costPerKg: null,
        denominator: null,
        denominatorSource: source,
        message: 'No se puede calcular el costo por kg: la venta anticipada no tiene rendimiento estimado registrado.',
      );
    }

    if (rawDenominator == null ||
        !rawDenominator.isFinite ||
        rawDenominator <= 0) {
      return CropCostPerKgResult(
        status: CropCostPerKgStatus.invalidDenominator,
        costPerKg: null,
        denominator: reportedDenominator,
        denominatorSource: source,
        message: 'No se puede calcular el costo por kg porque la cantidad usada como denominador no es válida. Debe ser mayor que cero.',
      );
    }

    final costPerKg = totalCost / rawDenominator;
    if (!costPerKg.isFinite) {
      return CropCostPerKgResult(
        status: CropCostPerKgStatus.invalidCostTotal,
        costPerKg: null,
        denominator: rawDenominator,
        denominatorSource: source,
        message: 'No se puede calcular el costo por kg porque el resultado no es un valor válido.',
      );
    }

    return CropCostPerKgResult(
      status: CropCostPerKgStatus.calculated,
      costPerKg: costPerKg,
      denominator: rawDenominator,
      denominatorSource: source,
      message: 'Costo estimado por kg',
    );
  }

  /// Convierte el texto ingresado por el usuario en un importe monetario.
  ///
  /// Acepta separadores de miles y decimales habituales (`1.500`, `1.500,50`,
  /// `1,500.50`, `1500.5`). Devuelve `null` para entradas vacías, no numéricas,
  /// cero, negativas o no finitas.
  static double? parseAmount(String? raw) {
    if (raw == null) return null;

    final value = raw.replaceAll(RegExp(r'[\s$]'), '');
    if (value.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(value)) {
      return null;
    }

    final lastDot = value.lastIndexOf('.');
    final lastComma = value.lastIndexOf(',');
    String normalized;

    if (lastDot >= 0 && lastComma >= 0) {
      final decimalIndex = lastDot > lastComma ? lastDot : lastComma;
      final decimalSeparator = value[decimalIndex];
      final groupSeparator = decimalSeparator == '.' ? ',' : '.';
      final integerPart = value.substring(0, decimalIndex);
      final decimalPart = value.substring(decimalIndex + 1);

      if (decimalPart.isEmpty ||
          decimalPart.contains('.') ||
          decimalPart.contains(',')) {
        return null;
      }

      final groupPattern = RegExp(
        '^\\d{1,3}(?:${RegExp.escape(groupSeparator)}\\d{3})*\$',
      );
      if (!groupPattern.hasMatch(integerPart)) return null;

      normalized = '${integerPart.replaceAll(groupSeparator, '')}.$decimalPart';
    } else if (lastDot >= 0 || lastComma >= 0) {
      final separator = lastDot >= 0 ? '.' : ',';
      final parts = value.split(separator);

      if (parts.length > 2) {
        final groupPattern = RegExp(
          '^\\d{1,3}(?:${RegExp.escape(separator)}\\d{3})+\$',
        );
        if (!groupPattern.hasMatch(value)) return null;
        normalized = value.replaceAll(separator, '');
      } else {
        final integerPart = parts[0];
        final fractionalPart = parts[1];
        if (fractionalPart.isEmpty) return null;

        final isZeroInteger = integerPart.replaceAll('0', '').isEmpty;
        final looksLikeThousands =
            fractionalPart.length == 3 &&
            integerPart.isNotEmpty &&
            !isZeroInteger &&
            integerPart.length <= 3;

        normalized = looksLikeThousands
            ? '$integerPart$fractionalPart'
            : '$integerPart.$fractionalPart';
      }
    } else {
      normalized = value;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return null;
    }

    return parsed;
  }
}
