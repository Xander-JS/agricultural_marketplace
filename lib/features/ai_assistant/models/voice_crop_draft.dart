import '../../../core/utils/unit_formatters.dart';

/// Campos del formulario de publicación que la asistencia por voz puede
/// reconocer. Se mantienen separados del modelo principal de cultivos para no
/// alterar la persistencia ni las reglas actuales de `CropModel`.
enum VoiceCropField {
  cropType,
  quantity,
  unit,
  pricePerKg;

  String get label {
    switch (this) {
      case VoiceCropField.cropType:
        return 'Cultivo';
      case VoiceCropField.quantity:
        return 'Cantidad';
      case VoiceCropField.unit:
        return 'Unidad';
      case VoiceCropField.pricePerKg:
        return 'Precio por kg';
    }
  }
}

/// Unidad reconocida por la asistencia. Reutiliza las equivalencias oficiales
/// de [TraditionalUnit] y añade el kilogramo, que es la unidad base del
/// formulario y no forma parte de las unidades tradicionales.
class VoiceCropUnit {
  final String label;
  final String pluralLabel;
  final double kgEquivalent;
  final TraditionalUnit? traditionalUnit;

  const VoiceCropUnit._({
    required this.label,
    required this.pluralLabel,
    required this.kgEquivalent,
    this.traditionalUnit,
  });

  static const VoiceCropUnit kilogram = VoiceCropUnit._(
    label: 'kg',
    pluralLabel: 'kg',
    kgEquivalent: 1,
  );

  factory VoiceCropUnit.fromTraditional(TraditionalUnit unit) {
    return VoiceCropUnit._(
      label: unit.displayName,
      pluralLabel: unit.pluralName,
      kgEquivalent: unit.kgEquivalent,
      traditionalUnit: unit,
    );
  }

  /// Normaliza una unidad escrita por el agricultor o devuelta por la IA.
  /// Devuelve `null` cuando no es una unidad reconocida.
  static VoiceCropUnit? tryParse(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'kg':
      case 'kgs':
      case 'kilo':
      case 'kilos':
      case 'kilogramo':
      case 'kilogramos':
        return VoiceCropUnit.kilogram;
    }

    final traditional = TraditionalUnit.fromString(normalized);
    if (traditional == null) return null;
    return VoiceCropUnit.fromTraditional(traditional);
  }
}

/// Borrador tipado producido por la asistencia por voz.
///
/// `null` significa que el dato no se identificó. [fieldsToReview] contiene
/// datos que sí se identificaron pero que requieren confirmación explícita,
/// por ejemplo una conversión de una unidad tradicional a kilogramos.
class VoiceCropDraft {
  final String transcript;
  final String? cropType;
  final double? quantity;
  final VoiceCropUnit? unit;
  final double? quantityKg;
  final double? pricePerKg;
  final VoiceCropUnit? priceUnit;
  final Set<VoiceCropField> fieldsToReview;
  final List<String> warnings;
  final String? notes;

  const VoiceCropDraft({
    required this.transcript,
    this.cropType,
    this.quantity,
    this.unit,
    this.quantityKg,
    this.pricePerKg,
    this.priceUnit,
    this.fieldsToReview = const <VoiceCropField>{},
    this.warnings = const <String>[],
    this.notes,
  });

  bool get hasAnyUsableData =>
      cropType != null || quantityKg != null || pricePerKg != null;

  List<VoiceCropField> get missingFields {
    final missing = <VoiceCropField>[];
    if (cropType == null) missing.add(VoiceCropField.cropType);
    if (quantity == null || quantityKg == null) {
      missing.add(VoiceCropField.quantity);
    }
    if (unit == null) missing.add(VoiceCropField.unit);
    if (pricePerKg == null) missing.add(VoiceCropField.pricePerKg);
    return missing;
  }

  List<VoiceCropField> get reviewFields {
    return fieldsToReview
        .where((field) {
          switch (field) {
            case VoiceCropField.cropType:
              return cropType != null;
            case VoiceCropField.quantity:
              return quantity != null && quantityKg != null;
            case VoiceCropField.unit:
              return unit != null;
            case VoiceCropField.pricePerKg:
              return pricePerKg != null;
          }
        })
        .toList(growable: false);
  }

  List<VoiceCropField> get identifiedFields {
    final review = reviewFields.toSet();
    final identified = <VoiceCropField>[];
    if (cropType != null && !review.contains(VoiceCropField.cropType)) {
      identified.add(VoiceCropField.cropType);
    }
    if (quantity != null &&
        quantityKg != null &&
        !review.contains(VoiceCropField.quantity)) {
      identified.add(VoiceCropField.quantity);
    }
    if (unit != null && !review.contains(VoiceCropField.unit)) {
      identified.add(VoiceCropField.unit);
    }
    if (pricePerKg != null && !review.contains(VoiceCropField.pricePerKg)) {
      identified.add(VoiceCropField.pricePerKg);
    }
    return identified;
  }

  String? get quantityDescription {
    if (quantity == null) return null;
    final amount = UnitFormatters.formatCleanValue(quantity);
    final unitLabel = unit == null
        ? ''
        : ' ${quantity == 1 ? unit!.label : unit!.pluralLabel}';
    final raw = '$amount$unitLabel'.trim();
    if (quantityKg == null) return raw.isEmpty ? null : raw;
    if (unit == null || unit == VoiceCropUnit.kilogram) {
      return UnitFormatters.formatKg(quantityKg);
    }
    return '$raw (${UnitFormatters.formatKg(quantityKg)})';
  }
}
