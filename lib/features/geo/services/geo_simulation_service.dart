import 'dart:math' as math;
import '../../../core/utils/geo_utils.dart';
import '../../crop/models/crop_model.dart';
import '../../profile/models/farmer_profile_data.dart';
import '../models/simulated_location.dart';

/// Servicio centralizado para la asignación y cálculo de ubicaciones simuladas.
/// 
/// Garantiza:
/// 1. Coordenadas ficticias estrictamente delimitadas al área piloto de Nariño.
/// 2. Asignación determinista y estable basada en semillas (ej. ID de usuario o cultivo).
/// 3. Compatibilidad total entre compradores y agricultores para cálculo de distancias.
/// 4. No requiere permisos de dispositivo ni accede a hardware GPS real.
class GeoSimulationService {
  const GeoSimulationService();

  /// Asigna una ubicación simulada respetando los límites del piloto en Nariño.
  /// 
  /// Si se proporciona [seed], el cálculo es 100% determinista y estable: múltiples llamadas
  /// con la misma semilla devolverán exactamente las mismas coordenadas.
  /// 
  /// Si se proporciona [municipality] y pertenece al catálogo del piloto, se toma su
  /// centro como ancla y se aplica una pequeña dispersión sintética realista (+/- 0.02° ≈ 2 km),
  /// garantizando que el punto permanezca dentro de los límites de Nariño.
  static SimulatedLocation assignSimulatedLocation({
    String? seed,
    String? municipality,
    String? department,
  }) {
    final effectiveDept = department?.trim().isNotEmpty == true
        ? department!.trim()
        : NarinoPilotBounds.department;

    final random = seed != null
        ? math.Random(seed.hashCode)
        : math.Random();

    // 1. Determinar el municipio base
    String selectedMun = municipality?.trim() ?? '';
    if (selectedMun.isEmpty || !NarinoPilotBounds.municipalities.containsKey(selectedMun)) {
      // Si el municipio no coincide con el piloto o viene vacío, seleccionar uno del catálogo
      // usando la semilla para asegurar estabilidad
      final names = NarinoPilotBounds.municipalityNames;
      final index = random.nextInt(names.length);
      selectedMun = names[index];
    }

    // 2. Obtener centro de referencia del municipio
    final center = NarinoPilotBounds.municipalities[selectedMun]!;

    // 3. Generar dispersión determinista alrededor del municipio (+/- 0.02 grados ≈ 2.2 km)
    // Usamos el generador pseudoaleatorio de la semilla
    final double latOffset = (random.nextDouble() - 0.5) * 0.04;
    final double lonOffset = (random.nextDouble() - 0.5) * 0.04;

    double simulatedLat = center.lat + latOffset;
    double simulatedLon = center.lon + lonOffset;

    // 4. Clampear estrictamente a los límites del departamento de Nariño
    simulatedLat = simulatedLat.clamp(
      NarinoPilotBounds.minLatitude,
      NarinoPilotBounds.maxLatitude,
    );
    simulatedLon = simulatedLon.clamp(
      NarinoPilotBounds.minLongitude,
      NarinoPilotBounds.maxLongitude,
    );

    // Redondear a 6 decimales para mantener formato estándar de coordenadas
    simulatedLat = (simulatedLat * 1000000).round() / 1000000;
    simulatedLon = (simulatedLon * 1000000).round() / 1000000;

    return SimulatedLocation(
      department: effectiveDept,
      municipality: selectedMun,
      latitude: simulatedLat,
      longitude: simulatedLon,
      isSimulated: true,
    );
  }

  /// Calcula la distancia en kilómetros entre dos ubicaciones simuladas.
  /// 
  /// Retorna `null` si alguna ubicación es nula o carece de coordenadas válidas.
  static double? calculateDistance(
    SimulatedLocation? origin,
    SimulatedLocation? destination,
  ) {
    if (origin == null || destination == null) return null;
    return GeoUtils.calculateHaversineDistanceKm(
      lat1: origin.latitude,
      lon1: origin.longitude,
      lat2: destination.latitude,
      lon2: destination.longitude,
    );
  }

  /// Calcula la distancia en kilómetros entre dos pares de coordenadas directas.
  static double? calculateDistanceBetweenCoordinates({
    required double? lat1,
    required double? lon1,
    required double? lat2,
    required double? lon2,
  }) {
    return GeoUtils.calculateHaversineDistanceKm(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
  }

  /// Evalúa la distancia y clasifica el rango logístico entre dos ubicaciones.
  static DistanceEvaluation evaluateDistance({
    required double? lat1,
    required double? lon1,
    required double? lat2,
    required double? lon2,
    String originSource = 'crop',
  }) {
    final distanceKm = calculateDistanceBetweenCoordinates(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
    return DistanceEvaluation.fromDistance(
      distanceKm,
      originSource: originSource,
    );
  }

  /// Resuelve las coordenadas geográficas de origen de un lote agrícola.
  /// 
  /// Criterio de prevalencia del marketplace:
  /// 1. Las coordenadas del cultivo ([CropModel.latitude], [CropModel.longitude])
  ///    prevalecen porque corresponden a la ubicación física de la cosecha o predio.
  /// 2. Si el cultivo carece de coordenadas, se recurre a las coordenadas del perfil
  ///    del agricultor ([FarmerProfileData.latitude], [FarmerProfileData.longitude]).
  /// 3. Si [useFallback] es true y ninguno tiene coordenadas persistidas, se genera
  ///    una ubicación simulada determinista usando como semilla el ID de la entidad,
  ///    sin modificar silenciosamente la base de datos.
  /// 4. Si no hay coordenadas ni fallback activo, retorna coordenadas nulas con origen 'none'.
  static ({double? latitude, double? longitude, String source}) resolveCropOriginCoordinates({
    required CropModel? crop,
    FarmerProfileData? farmerProfile,
    bool useFallback = false,
  }) {
    // 1. Prevalencia de coordenadas del cultivo
    if (crop != null && GeoUtils.isValidCoordinate(crop.latitude, crop.longitude)) {
      return (
        latitude: crop.latitude,
        longitude: crop.longitude,
        source: 'crop',
      );
    }

    // 2. Fallback al perfil del agricultor
    if (farmerProfile != null &&
        GeoUtils.isValidCoordinate(farmerProfile.latitude, farmerProfile.longitude)) {
      return (
        latitude: farmerProfile.latitude,
        longitude: farmerProfile.longitude,
        source: 'farmer',
      );
    }

    // 3. Fallback determinista estable si está explícitamente habilitado
    if (useFallback) {
      if (crop != null) {
        final fallback = assignSimulatedLocation(
          seed: 'crop_${crop.id.isNotEmpty ? crop.id : crop.farmerId}_${crop.title}',
          municipality: crop.municipality,
          department: crop.department,
        );
        return (
          latitude: fallback.latitude,
          longitude: fallback.longitude,
          source: 'crop_fallback',
        );
      }
      if (farmerProfile != null) {
        final fallback = getFallbackUserLocation(
          farmerProfile.id,
          municipality: farmerProfile.municipality,
          department: farmerProfile.department,
        );
        return (
          latitude: fallback.latitude,
          longitude: fallback.longitude,
          source: 'farmer_fallback',
        );
      }
    }

    return (latitude: null, longitude: null, source: 'none');
  }

  /// Evalúa la distancia entre un comprador y un cultivo o su agricultor.
  /// 
  /// - Valida que las coordenadas del comprador existan y sean correctas.
  /// - Aplica el criterio de prevalencia para determinar el origen: cultivo > perfil agricultor.
  /// - Si las coordenadas de alguna de las partes están ausentes o son inválidas,
  ///   retorna [DistanceEvaluation.unavailable] sin inventar distancias erróneas.
  /// - Mantiene determinismo estricto para las mismas coordenadas.
  /// - Diferencia explícitamente una distancia válida de 0.0 km de una distancia no disponible.
  static DistanceEvaluation evaluateBuyerToCropDistance({
    required double? buyerLatitude,
    required double? buyerLongitude,
    required CropModel? crop,
    FarmerProfileData? farmerProfile,
    bool useFallbackIfMissing = false,
  }) {
    if (!GeoUtils.isValidCoordinate(buyerLatitude, buyerLongitude)) {
      return DistanceEvaluation.unavailable(originSource: 'none');
    }

    final origin = resolveCropOriginCoordinates(
      crop: crop,
      farmerProfile: farmerProfile,
      useFallback: useFallbackIfMissing,
    );

    if (!GeoUtils.isValidCoordinate(origin.latitude, origin.longitude)) {
      return DistanceEvaluation.unavailable(originSource: origin.source);
    }

    final distanceKm = GeoUtils.calculateHaversineDistanceKm(
      lat1: buyerLatitude,
      lon1: buyerLongitude,
      lat2: origin.latitude,
      lon2: origin.longitude,
    );

    return DistanceEvaluation.fromDistance(
      distanceKm,
      originSource: origin.source,
      isSimulated: true,
    );
  }

  /// Sobrecarga que evalúa la distancia a partir del perfil del comprador.
  /// 
  /// Si el perfil del comprador carece de coordenadas y [useFallbackIfMissing] es true,
  /// se usa su fallback determinista estable.
  static DistanceEvaluation evaluateBuyerProfileToCrop({
    required FarmerProfileData? buyerProfile,
    required CropModel? crop,
    FarmerProfileData? farmerProfile,
    bool useFallbackIfMissing = false,
  }) {
    if (buyerProfile == null) {
      return DistanceEvaluation.unavailable(originSource: 'none');
    }

    double? buyerLat = buyerProfile.latitude;
    double? buyerLon = buyerProfile.longitude;

    if (!GeoUtils.isValidCoordinate(buyerLat, buyerLon) && useFallbackIfMissing) {
      final fallbackBuyer = getFallbackUserLocation(
        buyerProfile.id,
        municipality: buyerProfile.municipality,
        department: buyerProfile.department,
      );
      buyerLat = fallbackBuyer.latitude;
      buyerLon = fallbackBuyer.longitude;
    }

    return evaluateBuyerToCropDistance(
      buyerLatitude: buyerLat,
      buyerLongitude: buyerLon,
      crop: crop,
      farmerProfile: farmerProfile,
      useFallbackIfMissing: useFallbackIfMissing,
    );
  }

  /// Obtiene o genera la ubicación simulada estable de un usuario a partir de su ID.
  /// 
  /// Si el usuario ya cuenta con coordenadas en su perfil, deben usarse esas.
  /// Este método sirve como fallback determinista cuando el perfil aún no las tiene persistidas.
  static SimulatedLocation getFallbackUserLocation(
    String userId, {
    String? municipality,
    String? department,
  }) {
    return assignSimulatedLocation(
      seed: 'user_geo_$userId',
      municipality: municipality,
      department: department,
    );
  }
}
