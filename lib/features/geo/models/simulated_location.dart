import '../../../core/utils/geo_utils.dart';

/// Configuración de referencia del área geográfica piloto en Nariño.
class NarinoPilotBounds {
  NarinoPilotBounds._();

  static const String department = 'Nariño';

  /// Límites de la caja envolvente (Bounding Box) del departamento de Nariño
  static const double minLatitude = GeoUtils.narinoMinLatitude;
  static const double maxLatitude = GeoUtils.narinoMaxLatitude;
  static const double minLongitude = GeoUtils.narinoMinLongitude;
  static const double maxLongitude = GeoUtils.narinoMaxLongitude;

  /// Centros geográficos ficticios de referencia para municipios del piloto en Nariño.
  /// Se utilizan como anclas para generar coordenadas simuladas coherentes.
  static const Map<String, ({double lat, double lon})> municipalities = {
    'Pasto': (lat: 1.2136, lon: -77.2811),
    'Ipiales': (lat: 0.8248, lon: -77.6417),
    'Tumaco': (lat: 1.7986, lon: -78.8156),
    'Túquerres': (lat: 1.0875, lon: -77.6186),
    'La Unión': (lat: 1.6033, lon: -77.1317),
    'Sandoná': (lat: 1.2883, lon: -77.4722),
    'Buesaco': (lat: 1.3850, lon: -77.1550),
    'Samaniego': (lat: 1.3364, lon: -77.5967),
    'Guaitarilla': (lat: 1.1292, lon: -77.5458),
    'Consacá': (lat: 1.2094, lon: -77.4647),
  };

  /// Lista ordenada de nombres de municipios disponibles para el piloto.
  static List<String> get municipalityNames => municipalities.keys.toList();
}

/// Modelo de datos que representa una ubicación simulada.
/// 
/// Diferencia explícitamente la división político-administrativa (departamento y municipio)
/// de las coordenadas matemáticas sintéticas (latitud y longitud).
class SimulatedLocation {
  final String department;
  final String municipality;
  final double latitude;
  final double longitude;
  final bool isSimulated;

  const SimulatedLocation({
    required this.department,
    required this.municipality,
    required this.latitude,
    required this.longitude,
    this.isSimulated = true,
  });

  /// Verifica si las coordenadas actuales se encuentran dentro del área piloto.
  bool get isWithinPilot =>
      GeoUtils.isWithinNarinoPilot(latitude, longitude);

  /// Texto legible de ubicación administrativa (ej. "Pasto, Nariño").
  String get administrativeDisplay =>
      municipality.isNotEmpty ? '$municipality, $department' : department;

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'municipality': municipality,
      'latitude': latitude,
      'longitude': longitude,
      'is_simulated': isSimulated,
    };
  }

  factory SimulatedLocation.fromMap(Map<String, dynamic> map) {
    return SimulatedLocation(
      department: (map['department'] as String?)?.trim() ?? NarinoPilotBounds.department,
      municipality: (map['municipality'] as String?)?.trim() ?? '',
      latitude: ((map['latitude'] as num?)?.toDouble()) ?? NarinoPilotBounds.municipalities['Pasto']!.lat,
      longitude: ((map['longitude'] as num?)?.toDouble()) ?? NarinoPilotBounds.municipalities['Pasto']!.lon,
      isSimulated: map['is_simulated'] as bool? ?? true,
    );
  }

  SimulatedLocation copyWith({
    String? department,
    String? municipality,
    double? latitude,
    double? longitude,
    bool? isSimulated,
  }) {
    return SimulatedLocation(
      department: department ?? this.department,
      municipality: municipality ?? this.municipality,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimulatedLocation &&
          runtimeType == other.runtimeType &&
          department == other.department &&
          municipality == other.municipality &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      department.hashCode ^
      municipality.hashCode ^
      latitude.hashCode ^
      longitude.hashCode;

  @override
  String toString() =>
      'SimulatedLocation($administrativeDisplay, lat: $latitude, lon: $longitude, simulated: $isSimulated)';
}

/// Categorización de rangos de distancia entre comprador y cultivo.
/// Prepara la arquitectura para las subetapas 2.5 y 4.4 sin fijar tarifas definitivas.
enum DistanceRangeCategory {
  /// Dentro del mismo sector o radio local (ej. <= 20 km)
  local,

  /// Distancia regional corta (ej. > 20 km y <= 60 km)
  regionalShort,

  /// Distancia regional media (ej. > 60 km y <= 120 km)
  regionalMedium,

  /// Distancia regional larga o extendida (ej. > 120 km)
  regionalLong,

  /// Coordenadas no disponibles o incompletas
  unknown;

  /// Clasifica una distancia calculada en su categoría de rango logístico.
  static DistanceRangeCategory fromDistanceKm(double? distanceKm) {
    if (distanceKm == null || distanceKm < 0) return DistanceRangeCategory.unknown;
    if (distanceKm <= 20.0) return DistanceRangeCategory.local;
    if (distanceKm <= 60.0) return DistanceRangeCategory.regionalShort;
    if (distanceKm <= 120.0) return DistanceRangeCategory.regionalMedium;
    return DistanceRangeCategory.regionalLong;
  }
}

/// Evaluación de distancia entre dos entidades geográficas.
/// 
/// Diferencia explícitamente:
/// - Una distancia válida de cero kilómetros ([isZeroDistance] = true, [hasValidDistance] = true, categoría local).
/// - Una distancia no disponible por coordenadas ausentes o incompletas ([distanceKm] = null, categoría unknown).
class DistanceEvaluation {
  final double? distanceKm;
  final DistanceRangeCategory category;
  final bool isSimulated;
  final String formatted;
  final String originSource;

  const DistanceEvaluation({
    required this.distanceKm,
    required this.category,
    this.isSimulated = true,
    required this.formatted,
    this.originSource = 'crop',
  });

  /// Indica si la distancia calculada es numérica y válida (mayor o igual a cero).
  bool get hasValidDistance => distanceKm != null && distanceKm! >= 0;

  /// Indica si la distancia representa exactamente cero kilómetros (mismo punto geográfico).
  bool get isZeroDistance => distanceKm != null && distanceKm == 0.0;

  /// Alias de conveniencia para comprobar si la distancia está disponible.
  bool get isAvailable => hasValidDistance;

  /// Helpers para evaluar los rangos logísticos de forma expresiva.
  bool get isLocal => category == DistanceRangeCategory.local;
  bool get isRegionalShort => category == DistanceRangeCategory.regionalShort;
  bool get isRegionalMedium => category == DistanceRangeCategory.regionalMedium;
  bool get isRegionalLong => category == DistanceRangeCategory.regionalLong;
  bool get isUnknown => category == DistanceRangeCategory.unknown;

  /// Instancia predeterminada para coordenadas ausentes, inválidas o no calculables.
  factory DistanceEvaluation.unavailable({
    String originSource = 'none',
    bool isSimulated = true,
  }) {
    return DistanceEvaluation(
      distanceKm: null,
      category: DistanceRangeCategory.unknown,
      isSimulated: isSimulated,
      formatted: GeoUtils.formatDistance(null),
      originSource: originSource,
    );
  }

  /// Construye una evaluación a partir de una distancia en kilómetros.
  /// Si la distancia es nula o negativa, retorna [unavailable].
  factory DistanceEvaluation.fromDistance(
    double? distanceKm, {
    String originSource = 'crop',
    bool isSimulated = true,
  }) {
    if (distanceKm == null || distanceKm < 0) {
      return DistanceEvaluation.unavailable(
        originSource: originSource,
        isSimulated: isSimulated,
      );
    }
    return DistanceEvaluation(
      distanceKm: distanceKm,
      category: DistanceRangeCategory.fromDistanceKm(distanceKm),
      isSimulated: isSimulated,
      formatted: GeoUtils.formatDistance(distanceKm),
      originSource: originSource,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceEvaluation &&
          runtimeType == other.runtimeType &&
          distanceKm == other.distanceKm &&
          category == other.category &&
          isSimulated == other.isSimulated &&
          formatted == other.formatted &&
          originSource == other.originSource;

  @override
  int get hashCode =>
      distanceKm.hashCode ^
      category.hashCode ^
      isSimulated.hashCode ^
      formatted.hashCode ^
      originSource.hashCode;

  @override
  String toString() =>
      'DistanceEvaluation(km: $distanceKm, category: ${category.name}, origin: $originSource, formatted: "$formatted")';
}
