import 'package:intl/intl.dart';

/// Utilidad centralizada para formateo de moneda colombiana (COP).
/// Desacopla la presentación visual de los valores numéricos almacenados o calculados.
abstract final class CurrencyFormatters {
  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'es_CO');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00', 'es_CO');

  /// Formatea un valor numérico a pesos colombianos (COP) bajo convención colombiana (`es_CO`).
  ///
  /// Separador de miles con punto (ej: `$ 200.000` o `200.000 COP`).
  ///
  /// Parámetros:
  /// - [amount]: Monto numérico (double, int o num). No se muta.
  /// - [includeSymbol]: Si es true, prefija `$ `. Por defecto `true`.
  /// - [includeCode]: Si es true, añade sufijo ` COP`. Por defecto `false`.
  /// - [decimalDigits]: Forzar cantidad de decimales. Si es null, usa 0 para enteros y hasta 2 para fraccionarios.
  /// - [fallback]: Texto si [amount] es null. Por defecto `$ 0`.
  static String formatCop(
    num? amount, {
    bool includeSymbol = true,
    bool includeCode = false,
    int? decimalDigits,
    String fallback = r'$ 0',
  }) {
    if (amount == null) return fallback;

    final isNegative = amount < 0;
    final absAmount = isNegative ? -amount : amount;

    String numberStr;
    if (decimalDigits != null) {
      final customFormatter = NumberFormat.currency(
        locale: 'es_CO',
        symbol: '',
        decimalDigits: decimalDigits,
      );
      numberStr = customFormatter.format(absAmount).replaceAll('\u00A0', ' ').trim();
    } else {
      final isInteger = absAmount % 1 == 0;
      if (isInteger) {
        numberStr = _integerFormatter.format(absAmount).replaceAll('\u00A0', ' ').trim();
      } else {
        numberStr = _decimalFormatter.format(absAmount).replaceAll('\u00A0', ' ').trim();
      }
    }

    if (includeSymbol && includeCode) {
      return isNegative ? '-\$ $numberStr COP' : '\$ $numberStr COP';
    } else if (includeSymbol) {
      return isNegative ? '-\$ $numberStr' : '\$ $numberStr';
    } else if (includeCode) {
      return isNegative ? '-$numberStr COP' : '$numberStr COP';
    } else {
      return isNegative ? '-$numberStr' : numberStr;
    }
  }

  /// Formatea el precio por kilogramo (ej: `$ 4.500 / kg`).
  static String formatPricePerKg(
    num? pricePerKg, {
    bool includeSymbol = true,
    bool includeCode = false,
  }) {
    final formattedPrice = formatCop(
      pricePerKg,
      includeSymbol: includeSymbol,
      includeCode: includeCode,
    );
    return '$formattedPrice / kg';
  }
}
