import 'package:intl/intl.dart';

/// Unidades tradicionales agrícolas en Colombia según el esquema de base de datos (`unit_type`).
enum TraditionalUnit {
  bulto(displayName: 'bulto', pluralName: 'bultos', kgEquivalent: 50.0),
  arroba(displayName: 'arroba', pluralName: 'arrobas', kgEquivalent: 12.5),
  canastilla(displayName: 'canastilla', pluralName: 'canastillas', kgEquivalent: 25.0),
  caja(displayName: 'caja', pluralName: 'cajas', kgEquivalent: 20.0),
  tonelada(displayName: 'tonelada', pluralName: 'toneladas', kgEquivalent: 1000.0);

  final String displayName;
  final String pluralName;
  final double kgEquivalent;

  const TraditionalUnit({
    required this.displayName,
    required this.pluralName,
    required this.kgEquivalent,
  });

  static TraditionalUnit? fromString(String? unit) {
    if (unit == null) return null;
    switch (unit.toLowerCase().trim()) {
      case 'bulto':
      case 'bultos':
        return TraditionalUnit.bulto;
      case 'arroba':
      case 'arrobas':
      case '@':
        return TraditionalUnit.arroba;
      case 'canastilla':
      case 'canastillas':
        return TraditionalUnit.canastilla;
      case 'caja':
      case 'cajas':
        return TraditionalUnit.caja;
      case 'tonelada':
      case 'toneladas':
      case 't':
        return TraditionalUnit.tonelada;
      default:
        return null;
    }
  }
}

/// Utilidad centralizada para formateo de cantidades y unidades comerciales.
///
/// Reglas:
/// - La unidad base del sistema es estrictamente el kilogramo (`kg`).
/// - Precisión limpia: evitar decimales flotantes como `.00` en enteros (ej. `50 kg`),
///   y máximo 1-2 decimales cuando sea fraccionario (ej. `12,5 kg`).
/// - Conversiones visuales aproximadas hacia unidades tradicionales sin mutar el valor numérico en kg.
abstract final class UnitFormatters {
  static const String baseUnit = 'kg';

  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'es_CO');
  static final NumberFormat _decimal1Formatter = NumberFormat('#,##0.#', 'es_CO');
  static final NumberFormat _decimal2Formatter = NumberFormat('#,##0.##', 'es_CO');

  /// Formatea un valor numérico con precisión limpia y separador de miles.
  ///
  /// Ejemplos:
  /// - `formatCleanValue(50)` => `"50"`
  /// - `formatCleanValue(1250)` => `"1.250"`
  /// - `formatCleanValue(12.5)` => `"12,5"`
  /// - `formatCleanValue(12.555)` => `"12,56"`
  /// - `formatCleanValue(12.5, useLocaleSeparators: false)` => `"12.5"`
  static String formatCleanValue(
    num? value, {
    int maxDecimals = 2,
    bool useLocaleSeparators = true,
    String fallback = '0',
  }) {
    if (value == null) return fallback;

    if (!useLocaleSeparators) {
      if (value % 1 == 0) return value.toInt().toString();
      final fixed = value.toStringAsFixed(maxDecimals);
      return fixed.replaceAll(RegExp(r'\.?0+$'), '');
    }

    if (value % 1 == 0) {
      return _integerFormatter.format(value);
    } else if (maxDecimals == 1) {
      return _decimal1Formatter.format(value);
    } else {
      return _decimal2Formatter.format(value);
    }
  }

  /// Formatea una cantidad en kilogramos (`kg`).
  ///
  /// Ejemplos:
  /// - `formatKg(50)` => `"50 kg"`
  /// - `formatKg(1250)` => `"1.250 kg"`
  /// - `formatKg(12.5)` => `"12,5 kg"`
  /// - `formatKg(50, includeUnit: false)` => `"50"`
  static String formatKg(
    num? quantityKg, {
    bool includeUnit = true,
    int maxDecimals = 2,
    bool useLocaleSeparators = true,
    String fallback = '0 kg',
  }) {
    if (quantityKg == null) return fallback;
    final formattedNumber = formatCleanValue(
      quantityKg,
      maxDecimals: maxDecimals,
      useLocaleSeparators: useLocaleSeparators,
      fallback: '0',
    );
    return includeUnit ? '$formattedNumber $baseUnit' : formattedNumber;
  }

  /// Calcula y formatea la equivalencia visual aproximada en una unidad tradicional.
  /// No altera el valor numérico en kg almacenado o transmitido.
  ///
  /// Ejemplos:
  /// - `formatEquivalence(100, TraditionalUnit.bulto)` => `"≈ 2 bultos"`
  /// - `formatEquivalence(50, TraditionalUnit.bulto)` => `"≈ 1 bulto"`
  /// - `formatEquivalence(2500, TraditionalUnit.tonelada)` => `"≈ 2,5 toneladas"`
  static String? formatEquivalence(
    num? quantityKg,
    TraditionalUnit unit, {
    int maxDecimals = 1,
  }) {
    if (quantityKg == null || quantityKg <= 0 || unit.kgEquivalent <= 0) return null;
    final converted = quantityKg / unit.kgEquivalent;
    final formatted = formatCleanValue(converted, maxDecimals: maxDecimals);
    final unitLabel = (converted == 1.0) ? unit.displayName : unit.pluralName;
    return '≈ $formatted $unitLabel';
  }

  /// Determina la unidad tradicional más representativa para la cantidad dada.
  static String? formatBestTraditionalEquivalence(num? quantityKg) {
    if (quantityKg == null || quantityKg <= 0) return null;
    if (quantityKg >= 1000) {
      return formatEquivalence(quantityKg, TraditionalUnit.tonelada);
    }
    if (quantityKg >= 50) {
      return formatEquivalence(quantityKg, TraditionalUnit.bulto);
    }
    if (quantityKg >= 12.5) {
      return formatEquivalence(quantityKg, TraditionalUnit.arroba);
    }
    return null;
  }

  /// Retorna la cantidad en kg acompañada de su equivalencia tradicional aproximada entre paréntesis.
  ///
  /// Ejemplos:
  /// - `"1.000 kg (≈ 20 bultos)"`
  /// - `"2.500 kg (≈ 2,5 toneladas)"`
  static String formatKgWithEquivalence(
    num? quantityKg, {
    TraditionalUnit? unit,
    int maxDecimals = 2,
  }) {
    final baseKg = formatKg(quantityKg, maxDecimals: maxDecimals);
    final eq = unit != null
        ? formatEquivalence(quantityKg, unit)
        : formatBestTraditionalEquivalence(quantityKg);
    if (eq != null) {
      return '$baseKg ($eq)';
    }
    return baseKg;
  }
}
