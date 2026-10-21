/// Referencia regional de precio por kilogramo usada únicamente para el
/// prototipo de demostración.
class RegionalPriceReference {
  final String cropName;
  final List<String> aliases;
  final String region;
  final double referencePricePerKg;
  final bool isSimulated;
  final String? disclaimer;

  const RegionalPriceReference({
    required this.cropName,
    required this.aliases,
    required this.region,
    required this.referencePricePerKg,
    required this.isSimulated,
    this.disclaimer,
  });

  factory RegionalPriceReference.fromJson(Map<String, dynamic> json) {
    final name = (json['crop_name'] as String?)?.trim() ?? '';
    final rawAliases = json['aliases'];
    final List<String> parsedAliases;
    if (rawAliases is List) {
      parsedAliases = rawAliases.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else {
      parsedAliases = name.isNotEmpty ? [name] : [];
    }
    if (name.isNotEmpty && !parsedAliases.contains(name)) {
      parsedAliases.insert(0, name);
    }

    final rawPrice = json['reference_price_per_kg'];
    final price = (rawPrice is num) ? rawPrice.toDouble() : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    return RegionalPriceReference(
      cropName: name,
      aliases: parsedAliases,
      region: (json['region'] as String?)?.trim() ?? 'Nariño, Colombia',
      referencePricePerKg: price,
      isSimulated: true,
      disclaimer: json['disclaimer'] as String?,
    );
  }
}
