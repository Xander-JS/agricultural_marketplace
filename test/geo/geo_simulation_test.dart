import 'package:flutter_test/flutter_test.dart';
import 'package:agricultural_marketplace/core/utils/geo_utils.dart';
import 'package:agricultural_marketplace/features/geo/models/simulated_location.dart';
import 'package:agricultural_marketplace/features/geo/services/geo_simulation_service.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';
import 'package:agricultural_marketplace/features/auth/registro/services/registration_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Fase 2 — Subetapa 2.4: Utilidades y Validación Geográfica', () {
    test('1. Validación de coordenadas correctas e incorrectas', () {
      // Coordenadas válidas
      expect(GeoUtils.isValidCoordinate(1.2136, -77.2811), isTrue);
      expect(GeoUtils.isValidCoordinate(0.0, 0.0), isTrue);
      expect(GeoUtils.isValidCoordinate(-90.0, -180.0), isTrue);
      expect(GeoUtils.isValidCoordinate(90.0, 180.0), isTrue);

      // Coordenadas nulas
      expect(GeoUtils.isValidCoordinate(null, -77.2811), isFalse);
      expect(GeoUtils.isValidCoordinate(1.2136, null), isFalse);
      expect(GeoUtils.isValidCoordinate(null, null), isFalse);

      // Coordenadas fuera de rango
      expect(GeoUtils.isValidCoordinate(91.0, -77.2811), isFalse);
      expect(GeoUtils.isValidCoordinate(-91.0, -77.2811), isFalse);
      expect(GeoUtils.isValidCoordinate(1.2136, 181.0), isFalse);
      expect(GeoUtils.isValidCoordinate(1.2136, -181.0), isFalse);

      // Coordenadas especiales (NaN, Infinito)
      expect(GeoUtils.isValidCoordinate(double.nan, -77.2811), isFalse);
      expect(GeoUtils.isValidCoordinate(1.2136, double.infinity), isFalse);
    });

    test('2. Verificación de límites del piloto en Nariño', () {
      // Municipios del piloto en Nariño (deben estar dentro)
      expect(GeoUtils.isWithinNarinoPilot(1.2136, -77.2811), isTrue); // Pasto
      expect(GeoUtils.isWithinNarinoPilot(0.8248, -77.6417), isTrue); // Ipiales
      expect(GeoUtils.isWithinNarinoPilot(1.7986, -78.8156), isTrue); // Tumaco
      expect(GeoUtils.isWithinNarinoPilot(1.0875, -77.6186), isTrue); // Túquerres
      expect(GeoUtils.isWithinNarinoPilot(1.6033, -77.1317), isTrue); // La Unión

      // Ubicaciones fuera de Nariño (deben ser rechazadas por los límites del piloto)
      expect(GeoUtils.isWithinNarinoPilot(4.7110, -74.0721), isFalse); // Bogotá
      expect(GeoUtils.isWithinNarinoPilot(3.4516, -76.5320), isFalse); // Cali
      expect(GeoUtils.isWithinNarinoPilot(6.2442, -75.5812), isFalse); // Medellín
      expect(GeoUtils.isWithinNarinoPilot(null, null), isFalse);
    });

    test('3. Cálculo de distancia Haversine con casos conocidos y determinismo', () {
      // Pasto a Pasto (mismo punto) = 0.0 km
      final samePoint = GeoUtils.calculateHaversineDistanceKm(
        lat1: 1.2136,
        lon1: -77.2811,
        lat2: 1.2136,
        lon2: -77.2811,
      );
      expect(samePoint, 0.0);

      // Pasto a Ipiales (~58.9 km gran círculo)
      final pastoToIpiales = GeoUtils.calculateHaversineDistanceKm(
        lat1: 1.2136,
        lon1: -77.2811,
        lat2: 0.8248,
        lon2: -77.6417,
      );
      expect(pastoToIpiales, isNotNull);
      expect(pastoToIpiales!, closeTo(58.9, 1.0));

      // Pasto a Tumaco (~183.9 km gran círculo)
      final pastoToTumaco = GeoUtils.calculateHaversineDistanceKm(
        lat1: 1.2136,
        lon1: -77.2811,
        lat2: 1.7986,
        lon2: -78.8156,
      );
      expect(pastoToTumaco, isNotNull);
      expect(pastoToTumaco!, closeTo(183.9, 2.0));

      // Simetría determinista (d(A, B) == d(B, A))
      final ipialesToPasto = GeoUtils.calculateHaversineDistanceKm(
        lat1: 0.8248,
        lon1: -77.6417,
        lat2: 1.2136,
        lon2: -77.2811,
      );
      expect(pastoToIpiales, equals(ipialesToPasto));
    });

    test('4. Manejo de coordenadas ausentes sin producir distancias falsas', () {
      expect(
        GeoUtils.calculateHaversineDistanceKm(
          lat1: null,
          lon1: -77.2811,
          lat2: 0.8248,
          lon2: -77.6417,
        ),
        isNull,
      );

      expect(
        GeoUtils.calculateHaversineDistanceKm(
          lat1: 1.2136,
          lon1: null,
          lat2: 0.8248,
          lon2: -77.6417,
        ),
        isNull,
      );

      expect(
        GeoUtils.calculateHaversineDistanceKm(
          lat1: 1.2136,
          lon1: -77.2811,
          lat2: null,
          lon2: null,
        ),
        isNull,
      );
    });

    test('5. Formato amigable de distancias', () {
      expect(GeoUtils.formatDistance(0.0), 'Mismo sector (< 1 km)');
      expect(GeoUtils.formatDistance(0.8), 'Mismo sector (< 1 km)');
      expect(GeoUtils.formatDistance(5.4), 'A 5.4 km');
      expect(GeoUtils.formatDistance(58.9), 'A 59 km');
      expect(GeoUtils.formatDistance(null), 'Distancia no disponible');
      expect(GeoUtils.formatDistance(-10), 'Distancia no disponible');
    });
  });

  group('Fase 2 — Subetapa 2.4: Servicio de Simulación y Estabilidad', () {
    test('6. Asignación de ubicación simulada dentro de los límites del piloto', () {
      for (final mun in NarinoPilotBounds.municipalityNames) {
        final loc = GeoSimulationService.assignSimulatedLocation(
          seed: 'seed_test_$mun',
          municipality: mun,
        );

        expect(loc.department, NarinoPilotBounds.department);
        expect(loc.municipality, mun);
        expect(loc.isSimulated, isTrue);
        expect(loc.isWithinPilot, isTrue,
            reason: 'Coordenadas de $mun deben respetar los límites de Nariño');
        expect(loc.latitude, greaterThanOrEqualTo(NarinoPilotBounds.minLatitude));
        expect(loc.latitude, lessThanOrEqualTo(NarinoPilotBounds.maxLatitude));
        expect(loc.longitude, greaterThanOrEqualTo(NarinoPilotBounds.minLongitude));
        expect(loc.longitude, lessThanOrEqualTo(NarinoPilotBounds.maxLongitude));
      }
    });

    test('7. Estabilidad determinista: la ubicación asignada no cambia con la misma semilla', () {
      const seed = 'user_uuid_12345_estabilidad';

      final loc1 = GeoSimulationService.assignSimulatedLocation(seed: seed, municipality: 'Pasto');
      final loc2 = GeoSimulationService.assignSimulatedLocation(seed: seed, municipality: 'Pasto');
      final loc3 = GeoSimulationService.assignSimulatedLocation(seed: seed, municipality: 'Pasto');

      // Las coordenadas deben ser 100% idénticas en todas las invocaciones
      expect(loc1.latitude, equals(loc2.latitude));
      expect(loc1.longitude, equals(loc2.longitude));
      expect(loc2.latitude, equals(loc3.latitude));
      expect(loc2.longitude, equals(loc3.longitude));
      expect(loc1, equals(loc2));
    });

    test('8. Fallback determinista para usuarios sin coordenadas previas', () {
      const userId = 'farmer_abc_789';

      final fallback1 = GeoSimulationService.getFallbackUserLocation(userId, municipality: 'Ipiales');
      final fallback2 = GeoSimulationService.getFallbackUserLocation(userId, municipality: 'Ipiales');

      expect(fallback1.latitude, equals(fallback2.latitude));
      expect(fallback1.longitude, equals(fallback2.longitude));
      expect(fallback1.isWithinPilot, isTrue);
    });

    test('9. Clasificación de rangos logísticos para arquitectura de reglas posteriores', () {
      // Local: <= 20 km
      expect(DistanceRangeCategory.fromDistanceKm(0.0), DistanceRangeCategory.local);
      expect(DistanceRangeCategory.fromDistanceKm(15.5), DistanceRangeCategory.local);
      expect(DistanceRangeCategory.fromDistanceKm(20.0), DistanceRangeCategory.local);

      // Regional corto: > 20 y <= 60 km
      expect(DistanceRangeCategory.fromDistanceKm(20.1), DistanceRangeCategory.regionalShort);
      expect(DistanceRangeCategory.fromDistanceKm(58.9), DistanceRangeCategory.regionalShort);
      expect(DistanceRangeCategory.fromDistanceKm(60.0), DistanceRangeCategory.regionalShort);

      // Regional medio: > 60 y <= 120 km
      expect(DistanceRangeCategory.fromDistanceKm(60.1), DistanceRangeCategory.regionalMedium);
      expect(DistanceRangeCategory.fromDistanceKm(95.0), DistanceRangeCategory.regionalMedium);
      expect(DistanceRangeCategory.fromDistanceKm(120.0), DistanceRangeCategory.regionalMedium);

      // Regional largo: > 120 km
      expect(DistanceRangeCategory.fromDistanceKm(120.1), DistanceRangeCategory.regionalLong);
      expect(DistanceRangeCategory.fromDistanceKm(183.9), DistanceRangeCategory.regionalLong);

      // Desconocido
      expect(DistanceRangeCategory.fromDistanceKm(null), DistanceRangeCategory.unknown);
      expect(DistanceRangeCategory.fromDistanceKm(-5.0), DistanceRangeCategory.unknown);
    });

    test('10. Evaluación completa de distancias entre dos ubicaciones simuladas', () {
      final pasto = GeoSimulationService.assignSimulatedLocation(seed: 'pasto_eval', municipality: 'Pasto');
      final ipiales = GeoSimulationService.assignSimulatedLocation(seed: 'ipiales_eval', municipality: 'Ipiales');

      final eval = GeoSimulationService.evaluateDistance(
        lat1: pasto.latitude,
        lon1: pasto.longitude,
        lat2: ipiales.latitude,
        lon2: ipiales.longitude,
      );

      expect(eval.hasValidDistance, isTrue);
      expect(eval.distanceKm, isNotNull);
      expect(eval.distanceKm!, closeTo(58.9, 5.0));
      expect(eval.category, DistanceRangeCategory.regionalShort);
      expect(eval.formatted, contains('km'));
      expect(eval.isSimulated, isTrue);
    });
  });

  group('Fase 2 — Subetapa 2.4: Integración en Modelos de Cultivos y Perfiles', () {
    test('11. CropModel preserva coordenadas y datos geográficos en serialización y copyWith', () {
      final crop = CropModel(
        id: 'crop_test_1',
        farmerId: 'farmer_1',
        title: 'Papa Pastusa',
        description: 'Cosecha fresca',
        cropType: 'Papa',
        pricePerKg: 2500,
        stockTotal: 1000,
        department: 'Nariño',
        municipality: 'Túquerres',
        latitude: 1.0875,
        longitude: -77.6186,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = crop.toJson();
      expect(json['department'], 'Nariño');
      expect(json['municipality'], 'Túquerres');
      expect(json['latitude'], 1.0875);
      expect(json['longitude'], -77.6186);

      // Deserialización
      json['id'] = 'crop_test_1';
      json['status'] = 'borrador';
      json['stock_committed'] = 0;
      json['stock_sold'] = 0;
      json['created_at'] = DateTime.now().toIso8601String();
      json['updated_at'] = DateTime.now().toIso8601String();
      final fromJson = CropModel.fromJson(json);

      expect(fromJson.department, 'Nariño');
      expect(fromJson.municipality, 'Túquerres');
      expect(fromJson.latitude, 1.0875);
      expect(fromJson.longitude, -77.6186);

      // Conservación en copyWith al editar otros campos
      final updated = fromJson.copyWith(pricePerKg: 2800);
      expect(updated.pricePerKg, 2800);
      expect(updated.department, 'Nariño');
      expect(updated.municipality, 'Túquerres');
      expect(updated.latitude, 1.0875);
      expect(updated.longitude, -77.6186);
    });

    test('12. FarmerProfileData maneja ubicación simulada y preserva datos geográficos', () {
      final profile = FarmerProfileData.fromMap(
        profileMap: {
          'id': 'user_farmer_1',
          'full_name': 'Carlos Campesino',
          'role': 'agricultor',
          'department': 'Nariño',
          'municipality': 'Sandoná',
          'latitude': 1.2883,
          'longitude': -77.4722,
        },
        settingsMap: {},
        stats: FarmerStatsData(published: 1, negotiating: 0, closed: 0),
      );

      expect(profile.department, 'Nariño');
      expect(profile.municipality, 'Sandoná');
      expect(profile.latitude, 1.2883);
      expect(profile.longitude, -77.4722);
      expect(profile.hasSimulatedLocation, isTrue);

      // Conservación en copyWith
      final updatedProfile = profile.copyWith(fullName: 'Carlos Campesino Actualizado');
      expect(updatedProfile.fullName, 'Carlos Campesino Actualizado');
      expect(updatedProfile.department, 'Nariño');
      expect(updatedProfile.municipality, 'Sandoná');
      expect(updatedProfile.latitude, 1.2883);
      expect(updatedProfile.longitude, -77.4722);
    });

    test('13. RegistrationService asigna ubicación simulada estable a profileData', () async {
      Map<String, dynamic>? capturedProfile;

      final regService = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          return AuthResponse(
            session: Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: User(
                id: 'new_registered_user_uuid',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
            ),
            user: User(
              id: 'new_registered_user_uuid',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        },
        profileUpserter: (profileData) async {
          capturedProfile = profileData;
        },
      );

      final result = await regService.registerUser(
        phone: '3151234567',
        firstName: 'María',
        lastName: 'Compradora',
        password: 'password123',
        role: 'comprador',
        municipality: 'Pasto',
      );

      expect(result.success, isTrue);
      expect(capturedProfile, isNotNull);
      expect(capturedProfile!['id'], 'new_registered_user_uuid');
      expect(capturedProfile!['department'], 'Nariño');
      expect(capturedProfile!['municipality'], 'Pasto');
      expect(capturedProfile!['latitude'], isNotNull);
      expect(capturedProfile!['longitude'], isNotNull);
      expect(
        GeoUtils.isWithinNarinoPilot(
          capturedProfile!['latitude'] as double,
          capturedProfile!['longitude'] as double,
        ),
        isTrue,
      );
    });
  });
}
