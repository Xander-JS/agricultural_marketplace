import '../models/regional_price_reference.dart';

/// Conjunto de referencias de precios inventadas para el prototipo.
///
/// Estos valores no provienen de plazas de mercado, entidades oficiales,
/// fuentes externas ni mediciones reales. Sirven únicamente para demostrar la
/// comparación visual en Nariño, Colombia.
abstract final class SimulatedRegionalPriceReferences {
  /// Visible notice (Spanish). Screens show the localized
  /// `profitability_reference_notice`, which matches this text in Spanish.
  static const String notice =
      'Índice de referencia regional (Nariño) • Proyección de mercado KUS AI.';

  static const String region = 'Nariño, Colombia';

  static const List<RegionalPriceReference> all = [
    RegionalPriceReference(
      cropName: 'Papa Pastusa',
      aliases: ['Papa Pastusa'],
      region: region,
      referencePricePerKg: 2200,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Papa Criolla',
      aliases: ['Papa Criolla'],
      region: region,
      referencePricePerKg: 3600,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Zanahoria',
      aliases: ['Zanahoria'],
      region: region,
      referencePricePerKg: 1800,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Cebolla Cabezona',
      aliases: ['Cebolla Cabezona'],
      region: region,
      referencePricePerKg: 2500,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Tomate',
      aliases: ['Tomate', 'Tomate Chonto'],
      region: region,
      referencePricePerKg: 3200,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Habichuela',
      aliases: ['Habichuela'],
      region: region,
      referencePricePerKg: 4200,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Arveja',
      aliases: ['Arveja'],
      region: region,
      referencePricePerKg: 4500,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Mora',
      aliases: ['Mora'],
      region: region,
      referencePricePerKg: 6000,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Lulo',
      aliases: ['Lulo'],
      region: region,
      referencePricePerKg: 5500,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Café',
      aliases: ['Café'],
      region: region,
      referencePricePerKg: 12000,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Maíz',
      aliases: ['Maíz'],
      region: region,
      referencePricePerKg: 2000,
      isSimulated: true,
    ),
    RegionalPriceReference(
      cropName: 'Fríjol',
      aliases: ['Fríjol'],
      region: region,
      referencePricePerKg: 5000,
      isSimulated: true,
    ),
  ];

  /// Busca una referencia dentro de una lista dada por tipo o nombre del cultivo.
  static RegionalPriceReference? findInList({
    required List<RegionalPriceReference> references,
    required String cropType,
    required String title,
  }) {
    final normalizedType = _normalize(cropType);
    final normalizedTitle = _normalize(title);

    for (final reference in references) {
      final normalizedName = _normalize(reference.cropName);
      if (normalizedType == normalizedName || normalizedTitle == normalizedName) {
        return reference;
      }
      for (final alias in reference.aliases) {
        final normalizedAlias = _normalize(alias);
        if (normalizedType == normalizedAlias ||
            normalizedTitle == normalizedAlias) {
          return reference;
        }
      }
    }

    return null;
  }

  /// Busca una referencia por tipo o nombre del cultivo en la lista local.
  static RegionalPriceReference? findForCrop({
    required String cropType,
    required String title,
  }) {
    return findInList(
      references: all,
      cropType: cropType,
      title: title,
    );
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }
}
