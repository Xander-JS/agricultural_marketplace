import 'dart:math' as math;

/// Utilidades matemáticas y geográficas deterministas para el marketplace.
/// 
/// IMPORTANTE: Todas las coordenadas tratadas en este módulo corresponden a
/// ubicaciones simuladas para el piloto de Nariño y NO representan coordenadas GPS
/// reales ni la ubicación física de usuarios reales.
class GeoUtils {
  GeoUtils._();

  /// Radio de la Tierra en kilómetros (aproximación esférica WGS84 media).
  static const double earthRadiusKm = 6371.0;

  /// Límites geográficos de referencia para el piloto en el Departamento de Nariño, Colombia.
  static const double narinoMinLatitude = 0.5000;
  static const double narinoMaxLatitude = 2.1000;
  static const double narinoMinLongitude = -79.0000;
  static const double narinoMaxLongitude = -76.8000;

  /// Valida si un par de coordenadas geográficas es válido dentro de los rangos globales.
  /// 
  /// - Latitud debe estar entre -90.0 y +90.0.
  /// - Longitud debe estar entre -180.0 y +180.0.
  /// - No se permiten valores infinitos ni NaN.
  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || latitude.isInfinite) return false;
    if (longitude.isNaN || longitude.isInfinite) return false;
    if (latitude < -90.0 || latitude > 90.0) return false;
    if (longitude < -180.0 || longitude > 180.0) return false;
    return true;
  }

  /// Verifica si una coordenada se encuentra dentro de los límites del área piloto de Nariño.
  static bool isWithinNarinoPilot(double? latitude, double? longitude) {
    if (!isValidCoordinate(latitude, longitude)) return false;
    return latitude! >= narinoMinLatitude &&
        latitude <= narinoMaxLatitude &&
        longitude! >= narinoMinLongitude &&
        longitude <= narinoMaxLongitude;
  }

  /// Calcula la distancia de círculo máximo (Haversine) entre dos pares de coordenadas
  /// geográficas, retornando la distancia en kilómetros.
  /// 
  /// Es una función pura y estrictamente determinista.
  /// Retorna `null` si cualquiera de las coordenadas es nula, inválida o está fuera de rango.
  static double? calculateHaversineDistanceKm({
    required double? lat1,
    required double? lon1,
    required double? lat2,
    required double? lon2,
  }) {
    if (!isValidCoordinate(lat1, lon1) || !isValidCoordinate(lat2, lon2)) {
      return null;
    }

    final double pLat1 = lat1!;
    final double pLon1 = lon1!;
    final double pLat2 = lat2!;
    final double pLon2 = lon2!;

    // Si ambos puntos son idénticos, distancia 0.0 inmediata sin error de coma flotante
    if (pLat1 == pLat2 && pLon1 == pLon2) {
      return 0.0;
    }

    final double dLatRad = _degreesToRadians(pLat2 - pLat1);
    final double dLonRad = _degreesToRadians(pLon2 - pLon1);
    final double lat1Rad = _degreesToRadians(pLat1);
    final double lat2Rad = _degreesToRadians(pLat2);

    final double sinHalfDLat = math.sin(dLatRad / 2.0);
    final double sinHalfDLon = math.sin(dLonRad / 2.0);

    final double a = sinHalfDLat * sinHalfDLat +
        math.cos(lat1Rad) * math.cos(lat2Rad) * sinHalfDLon * sinHalfDLon;

    // Protección ante imprecisión numérica que pudiera hacer a > 1.0
    final double clampedA = a.clamp(0.0, 1.0);
    final double c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));

    final double distance = earthRadiusKm * c;
    return (distance * 10.0).roundToDouble() / 10.0; // 1 decimal de precisión
  }

  /// Formatea la distancia calculada para uso visual amigable en la interfaz.
  static String formatDistance(double? distanceKm) {
    if (distanceKm == null || distanceKm < 0) {
      return 'Distancia no disponible';
    }
    if (distanceKm < 1.0) {
      return 'Mismo sector (< 1 km)';
    }
    return 'A ${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)} km';
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
