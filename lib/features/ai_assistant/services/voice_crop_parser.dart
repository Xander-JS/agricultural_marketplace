import 'dart:convert';

import '../models/voice_crop_draft.dart';
import '../../../core/utils/app_formatters.dart';

/// Error de interpretación de la respuesta del proveedor. El mensaje está
/// pensado para mostrarse al usuario y nunca incluye credenciales.
class VoiceCropParseException implements Exception {
  final String message;

  const VoiceCropParseException(this.message);

  @override
  String toString() => message;
}

/// Convierte la respuesta JSON del proveedor de IA en un [VoiceCropDraft]
/// estrictamente tipado. No completa datos ausentes y no convierte precios de
/// forma silenciosa: toda conversión queda registrada como advertencia.
abstract final class VoiceCropParser {
  static VoiceCropDraft parse(
    String rawResponse, {
    required String transcript,
  }) {
    final jsonText = _extractJsonObject(rawResponse);
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException {
      throw const VoiceCropParseException(
        'La respuesta de la IA no es un JSON válido. Intenta de nuevo o continúa manualmente.',
      );
    }

    if (decoded is! Map) {
      throw const VoiceCropParseException(
        'La respuesta de la IA no tiene el formato esperado. Intenta de nuevo o continúa manualmente.',
      );
    }

    return parseMap(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
      transcript: transcript,
    );
  }

  static VoiceCropDraft parseMap(
    Map<String, dynamic> json, {
    required String transcript,
  }) {
    final warnings = <String>[];
    final fieldsToReview = <VoiceCropField>{};

    final cropType = _stringOrNull(
      _first(json, const ['cropType', 'crop_type', 'cropName', 'crop_name']),
      'El nombre del cultivo',
      warnings,
    );

    final quantityRaw = _first(json, const ['quantity', 'cantidad']);
    final quantity = _positiveNumber(quantityRaw, 'La cantidad', warnings);

    final unitRaw = _first(json, const ['unit', 'unidad']);
    final unit = VoiceCropUnit.tryParse(unitRaw);
    if (unitRaw is String && unitRaw.trim().isNotEmpty && unit == null) {
      warnings.add(
        'La unidad "$unitRaw" no se reconoce. Indica si es kg, bulto, arroba, canastilla, caja o tonelada.',
      );
    }

    double? quantityKg;
    if (quantity != null && unit != null) {
      quantityKg = quantity * unit.kgEquivalent;
      if (unit.traditionalUnit != null) {
        fieldsToReview.add(VoiceCropField.quantity);
        warnings.add(
          'La cantidad se convirtió a ${UnitFormatters.formatKg(quantityKg)}. Confírmala antes de publicar.',
        );
      }
    } else if (quantity != null) {
      warnings.add(
        'No se pudo convertir la cantidad a kilogramos porque falta una unidad reconocida.',
      );
    }

    final priceValueRaw = _first(json, const [
      'priceValue',
      'price_value',
      'price',
      'precio',
    ]);
    final priceValue = _positiveNumber(priceValueRaw, 'El precio', warnings);
    final priceUnitRaw = _first(json, const [
      'priceUnit',
      'price_unit',
      'precioUnidad',
      'precio_unidad',
    ]);
    final priceUnit = VoiceCropUnit.tryParse(priceUnitRaw);
    if (priceUnitRaw is String &&
        priceUnitRaw.trim().isNotEmpty &&
        priceUnit == null) {
      warnings.add(
        'La unidad del precio "$priceUnitRaw" no se reconoce. Indica si el precio es por kg o por otra unidad.',
      );
    }

    double? pricePerKg;
    if (priceValue != null && priceUnit != null) {
      pricePerKg = priceValue / priceUnit.kgEquivalent;
      if (priceUnit != VoiceCropUnit.kilogram) {
        fieldsToReview.add(VoiceCropField.pricePerKg);
        warnings.add(
          'El precio se convirtió a ${CurrencyFormatters.formatCop(pricePerKg)} por kg. Confírmalo antes de publicar.',
        );
      }
    } else if (priceValue != null) {
      final directPriceRaw = _first(json, const [
        'pricePerKg',
        'price_per_kg',
        'precioPorKg',
        'precio_por_kg',
      ]);
      final directPrice = _positiveNumber(
        directPriceRaw,
        'El precio por kg',
        warnings,
      );
      if (directPrice != null) {
        pricePerKg = directPrice;
        fieldsToReview.add(VoiceCropField.pricePerKg);
        warnings.add(
          'La IA devolvió un precio por kg sin indicar la unidad original. Confírmalo antes de publicar.',
        );
      } else {
        warnings.add(
          'No se indicó si el precio era por kg o por otra unidad. Ingrésalo manualmente.',
        );
      }
    } else {
      // Algunos proveedores pueden devolver directamente `pricePerKg`.
      final directPriceRaw = _first(json, const [
        'pricePerKg',
        'price_per_kg',
        'precioPorKg',
        'precio_por_kg',
      ]);
      final directPrice = _positiveNumber(
        directPriceRaw,
        'El precio por kg',
        warnings,
      );
      if (directPrice != null) {
        pricePerKg = directPrice;
        fieldsToReview.add(VoiceCropField.pricePerKg);
        warnings.add(
          'La IA devolvió un precio por kg. Confírmalo antes de publicar.',
        );
      }
    }

    final notes = _stringOrNull(
      _first(json, const ['notes', 'notas', 'comment', 'comentario']),
      'Las notas',
      warnings,
    );

    return VoiceCropDraft(
      transcript: transcript,
      cropType: cropType,
      quantity: quantity,
      unit: unit,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      priceUnit: priceUnit,
      fieldsToReview: fieldsToReview,
      warnings: warnings,
      notes: notes,
    );
  }

  static dynamic _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return json[key];
    }
    return null;
  }

  static String? _stringOrNull(
    dynamic value,
    String label,
    List<String> warnings,
  ) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    warnings.add('$label no tiene un formato válido y se omitió.');
    return null;
  }

  static double? _positiveNumber(
    dynamic value,
    String label,
    List<String> warnings,
  ) {
    if (value == null) return null;

    double? parsed;
    if (value is num) {
      parsed = value.toDouble();
    } else if (value is String) {
      // Se aceptan números simples y decimales con coma o punto, pero no
      // cadenas ambiguas como "1.000" (podrían ser mil o uno con decimales).
      final cleaned = value
          .trim()
          .replaceAll(RegExp(r'[^\d,.\-]'), '')
          .replaceAll(',', '.');
      if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(cleaned)) {
        warnings.add(
          '$label no tiene un formato numérico válido. Ingrésalo manualmente.',
        );
        return null;
      }
      parsed = double.tryParse(cleaned);
    } else {
      warnings.add(
        '$label no tiene un formato numérico válido. Ingrésalo manualmente.',
      );
      return null;
    }

    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      warnings.add('$label debe ser mayor que cero. Ingrésalo manualmente.');
      return null;
    }
    return parsed;
  }

  static String _extractJsonObject(String rawResponse) {
    var text = rawResponse.trim();
    if (text.startsWith('```')) {
      final firstLineEnd = text.indexOf('\n');
      if (firstLineEnd >= 0) {
        text = text.substring(firstLineEnd + 1).trim();
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }

    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace < 0 || lastBrace <= firstBrace) {
      throw const VoiceCropParseException(
        'La IA no devolvió un objeto JSON reconocible. Intenta de nuevo o continúa manualmente.',
      );
    }
    return text.substring(firstBrace, lastBrace + 1);
  }
}
