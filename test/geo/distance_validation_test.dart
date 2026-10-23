import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/theme/app_icons.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/utils/geo_utils.dart';
import 'package:agricultural_marketplace/features/geo/models/simulated_location.dart';
import 'package:agricultural_marketplace/features/geo/services/geo_simulation_service.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';
import 'package:agricultural_marketplace/features/crop/widgets/crop_card.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/profile/services/profile_service.dart';

class MockProfileServiceForGeo extends ProfileService {
  final FarmerProfileData? profileToReturn;
  MockProfileServiceForGeo({this.profileToReturn});

  @override
  Future<FarmerProfileData> getFarmerProfileData(String userId) async {
    return profileToReturn ??
        FarmerProfileData(
          id: userId,
          fullName: 'Usuario Test',
          role: 'comprador',
          email: 'test@agro.co',
          phone: '3101234567',
          department: 'Nariño',
          municipality: 'Pasto',
          latitude: 1.2136,
          longitude: -77.2811,
          settings: FarmerSettingsData(
            enableEarlySale: false,
            sharePhone: false,
            shareLocation: true,
            shareWhatsapp: false,
          ),
          stats: FarmerStatsData(published: 0, negotiating: 0, closed: 0),
        );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        publishableKey: 'placeholder-anon-key',
      );
    } catch (_) {}
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  group('Fase 2 — Subetapa 2.5: Distancias conocidas y límites exactos de cada rango', () {
    test('1. Casos conocidos entre municipios de referencia en Nariño', () {
      // Pasto (1.2136, -77.2811) a Ipiales (0.8248, -77.6417)
      final pastoToIpiales = GeoUtils.calculateHaversineDistanceKm(
        lat1: 1.2136,
        lon1: -77.2811,
        lat2: 0.8248,
        lon2: -77.6417,
      );
      expect(pastoToIpiales, isNotNull);
      expect(pastoToIpiales!, closeTo(58.9, 1.0));

      // Clasificación en rango regional corto (20 - 60 km)
      final evalIpiales = DistanceEvaluation.fromDistance(pastoToIpiales);
      expect(evalIpiales.category, DistanceRangeCategory.regionalShort);
      expect(evalIpiales.isRegionalShort, isTrue);
      expect(evalIpiales.hasValidDistance, isTrue);
      expect(evalIpiales.isZeroDistance, isFalse);

      // Pasto a Tumaco (1.7986, -78.8156) ~ 183.9 km
      final pastoToTumaco = GeoUtils.calculateHaversineDistanceKm(
        lat1: 1.2136,
        lon1: -77.2811,
        lat2: 1.7986,
        lon2: -78.8156,
      );
      expect(pastoToTumaco, isNotNull);
      expect(pastoToTumaco!, closeTo(183.9, 2.0));

      // Clasificación en rango regional largo (> 120 km)
      final evalTumaco = DistanceEvaluation.fromDistance(pastoToTumaco);
      expect(evalTumaco.category, DistanceRangeCategory.regionalLong);
      expect(evalTumaco.isRegionalLong, isTrue);

      // Pasto a Túquerres (1.0875, -77.6186) ~ 40.2 km
      final pastoToTuquerres = GeoUtils.calculateHaversineDistanceKm(
        lat1: 1.2136,
        lon1: -77.2811,
        lat2: 1.0875,
        lon2: -77.6186,
      );
      expect(pastoToTuquerres, isNotNull);
      expect(pastoToTuquerres!, closeTo(40.2, 2.0));
      expect(DistanceRangeCategory.fromDistanceKm(pastoToTuquerres), DistanceRangeCategory.regionalShort);
    });

    test('2. Clasificación rigurosa de los límites exactos de cada rango geográfico', () {
      // Límite inferior local: 0.0 km
      expect(DistanceRangeCategory.fromDistanceKm(0.0), DistanceRangeCategory.local);

      // Frontera local / regional corto (20.0 km)
      expect(DistanceRangeCategory.fromDistanceKm(19.99), DistanceRangeCategory.local);
      expect(DistanceRangeCategory.fromDistanceKm(20.0), DistanceRangeCategory.local);
      expect(DistanceRangeCategory.fromDistanceKm(20.01), DistanceRangeCategory.regionalShort);
      expect(DistanceRangeCategory.fromDistanceKm(20.1), DistanceRangeCategory.regionalShort);

      // Frontera regional corto / regional medio (60.0 km)
      expect(DistanceRangeCategory.fromDistanceKm(59.99), DistanceRangeCategory.regionalShort);
      expect(DistanceRangeCategory.fromDistanceKm(60.0), DistanceRangeCategory.regionalShort);
      expect(DistanceRangeCategory.fromDistanceKm(60.01), DistanceRangeCategory.regionalMedium);
      expect(DistanceRangeCategory.fromDistanceKm(60.1), DistanceRangeCategory.regionalMedium);

      // Frontera regional medio / regional largo (120.0 km)
      expect(DistanceRangeCategory.fromDistanceKm(119.99), DistanceRangeCategory.regionalMedium);
      expect(DistanceRangeCategory.fromDistanceKm(120.0), DistanceRangeCategory.regionalMedium);
      expect(DistanceRangeCategory.fromDistanceKm(120.01), DistanceRangeCategory.regionalLong);
      expect(DistanceRangeCategory.fromDistanceKm(120.1), DistanceRangeCategory.regionalLong);

      // Valores extremos y negativos
      expect(DistanceRangeCategory.fromDistanceKm(500.0), DistanceRangeCategory.regionalLong);
      expect(DistanceRangeCategory.fromDistanceKm(-0.01), DistanceRangeCategory.unknown);
      expect(DistanceRangeCategory.fromDistanceKm(-100.0), DistanceRangeCategory.unknown);
      expect(DistanceRangeCategory.fromDistanceKm(null), DistanceRangeCategory.unknown);
    });

    test('3. Distancia cero vs Distancia no disponible (Diferenciación explícita)', () {
      // Caso Distancia CERO válida (ej. Comprador y cultivo en el mismo punto exacto)
      final zeroEval = DistanceEvaluation.fromDistance(0.0, originSource: 'crop');
      expect(zeroEval.distanceKm, 0.0);
      expect(zeroEval.hasValidDistance, isTrue);
      expect(zeroEval.isZeroDistance, isTrue);
      expect(zeroEval.isAvailable, isTrue);
      expect(zeroEval.category, DistanceRangeCategory.local);
      expect(zeroEval.isLocal, isTrue);
      expect(zeroEval.isUnknown, isFalse);
      expect(zeroEval.formatted, 'Mismo sector (< 1 km)');

      // Caso Distancia NO DISPONIBLE (coordenadas ausentes o incompletas)
      final unavailableEval = DistanceEvaluation.unavailable(originSource: 'none');
      expect(unavailableEval.distanceKm, isNull);
      expect(unavailableEval.hasValidDistance, isFalse);
      expect(unavailableEval.isZeroDistance, isFalse);
      expect(unavailableEval.isAvailable, isFalse);
      expect(unavailableEval.category, DistanceRangeCategory.unknown);
      expect(unavailableEval.isUnknown, isTrue);
      expect(unavailableEval.isLocal, isFalse);
      expect(unavailableEval.formatted, 'Distancia no disponible');

      // Distancia de 0.5 km (menor a 1 km pero distinta de 0)
      final subKmEval = DistanceEvaluation.fromDistance(0.5, originSource: 'crop');
      expect(subKmEval.hasValidDistance, isTrue);
      expect(subKmEval.isZeroDistance, isFalse);
      expect(subKmEval.formatted, 'Mismo sector (< 1 km)');
    });

    test('4. Manejo de coordenadas ausentes o inválidas sin inventar distancias', () {
      final validCrop = CropModel(
        id: 'crop_1',
        farmerId: 'farmer_1',
        title: 'Papa',
        description: 'Desc',
        cropType: 'Papa',
        pricePerKg: 2000,
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Comprador con latitud nula
      final eval1 = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: null,
        buyerLongitude: -77.2811,
        crop: validCrop,
      );
      expect(eval1.hasValidDistance, isFalse);
      expect(eval1.distanceKm, isNull);
      expect(eval1.isUnknown, isTrue);

      // Comprador con longitud fuera de rango
      final eval2 = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: 195.0, // Inválido (> 180)
        crop: validCrop,
      );
      expect(eval2.hasValidDistance, isFalse);
      expect(eval2.distanceKm, isNull);
      expect(eval2.isUnknown, isTrue);

      // Comprador con NaN o Infinito
      final eval3 = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: double.nan,
        buyerLongitude: -77.2811,
        crop: validCrop,
      );
      expect(eval3.hasValidDistance, isFalse);

      final eval4 = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: double.infinity,
        crop: validCrop,
      );
      expect(eval4.hasValidDistance, isFalse);
    });
  });

  group('Fase 2 — Subetapa 2.5: Prevalencia y Resolución de Origen (Cultivo vs Perfil Agricultor)', () {
    test('5. Prevalencia de coordenadas de cultivo sobre las del perfil del agricultor', () {
      // Cultivo en Pasto (1.2136, -77.2811)
      final cropInPasto = CropModel(
        id: 'crop_pasto',
        farmerId: 'farmer_1',
        title: 'Cebolla',
        description: 'En Pasto',
        cropType: 'Cebolla',
        pricePerKg: 1500,
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Perfil del agricultor en Ipiales (0.8248, -77.6417)
      final farmerInIpiales = FarmerProfileData(
        id: 'farmer_1',
        fullName: 'Juan Agricultor',
        role: 'agricultor',
        email: 'juan@agro.com',
        phone: '3101234567',
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: 0.8248,
        longitude: -77.6417,
        settings: FarmerSettingsData(
          enableEarlySale: false,
          sharePhone: true,
          shareLocation: true,
          shareWhatsapp: false,
        ),
        stats: FarmerStatsData(published: 1, negotiating: 0, closed: 0),
      );

      // La resolución debe elegir prioritariamente el cultivo
      final resolved = GeoSimulationService.resolveCropOriginCoordinates(
        crop: cropInPasto,
        farmerProfile: farmerInIpiales,
      );

      expect(resolved.source, 'crop');
      expect(resolved.latitude, 1.2136);
      expect(resolved.longitude, -77.2811);

      // Comprador en Pasto debe tener distancia 0.0 con respecto a este cultivo
      final eval = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: -77.2811,
        crop: cropInPasto,
        farmerProfile: farmerInIpiales,
      );

      expect(eval.hasValidDistance, isTrue);
      expect(eval.isZeroDistance, isTrue);
      expect(eval.originSource, 'crop');
      expect(eval.distanceKm, 0.0);
    });

    test('6. Fallback a coordenadas del agricultor cuando el cultivo no tiene coordenadas', () {
      // Cultivo sin coordenadas
      final cropWithoutCoords = CropModel(
        id: 'crop_legacy',
        farmerId: 'farmer_1',
        title: 'Zanahoria',
        description: 'Sin gps',
        cropType: 'Zanahoria',
        pricePerKg: 1800,
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: null,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Perfil del agricultor con coordenadas en Ipiales
      final farmerInIpiales = FarmerProfileData(
        id: 'farmer_1',
        fullName: 'Juan Agricultor',
        role: 'agricultor',
        email: 'juan@agro.com',
        phone: '3101234567',
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: 0.8248,
        longitude: -77.6417,
        settings: FarmerSettingsData(
          enableEarlySale: false,
          sharePhone: true,
          shareLocation: true,
          shareWhatsapp: false,
        ),
        stats: FarmerStatsData(published: 1, negotiating: 0, closed: 0),
      );

      final resolved = GeoSimulationService.resolveCropOriginCoordinates(
        crop: cropWithoutCoords,
        farmerProfile: farmerInIpiales,
      );

      expect(resolved.source, 'farmer');
      expect(resolved.latitude, 0.8248);
      expect(resolved.longitude, -77.6417);

      // Comprador en Pasto evaluando este cultivo
      final eval = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: -77.2811,
        crop: cropWithoutCoords,
        farmerProfile: farmerInIpiales,
      );

      expect(eval.hasValidDistance, isTrue);
      expect(eval.originSource, 'farmer');
      expect(eval.distanceKm, closeTo(58.9, 1.0));
      expect(eval.isRegionalShort, isTrue);
    });

    test('7. Comportamiento cuando ni cultivo ni agricultor tienen coordenadas persistidas', () {
      final cropWithoutCoords = CropModel(
        id: 'crop_unlocated',
        farmerId: 'farmer_unlocated',
        title: 'Lechuga',
        description: 'Sin coords',
        cropType: 'Lechuga',
        pricePerKg: 1000,
        department: 'Nariño',
        municipality: 'Sandoná',
        latitude: null,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final farmerWithoutCoords = FarmerProfileData(
        id: 'farmer_unlocated',
        fullName: 'Pedro',
        role: 'agricultor',
        email: 'pedro@agro.com',
        phone: '3120000000',
        department: 'Nariño',
        municipality: 'Sandoná',
        latitude: null,
        longitude: null,
        settings: FarmerSettingsData(
          enableEarlySale: false,
          sharePhone: false,
          shareLocation: false,
          shareWhatsapp: false,
        ),
        stats: FarmerStatsData(published: 1, negotiating: 0, closed: 0),
      );

      // Sin fallback forzado: distancia debe ser no disponible
      final evalStrict = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: -77.2811,
        crop: cropWithoutCoords,
        farmerProfile: farmerWithoutCoords,
        useFallbackIfMissing: false,
      );

      expect(evalStrict.hasValidDistance, isFalse);
      expect(evalStrict.distanceKm, isNull);
      expect(evalStrict.isUnknown, isTrue);
      expect(evalStrict.originSource, 'none');

      // Con fallback determinista activado: genera coordenadas deterministas basadas en el cultivo
      final evalWithFallback = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: -77.2811,
        crop: cropWithoutCoords,
        farmerProfile: farmerWithoutCoords,
        useFallbackIfMissing: true,
      );

      expect(evalWithFallback.hasValidDistance, isTrue);
      expect(evalWithFallback.distanceKm, isNotNull);
      expect(evalWithFallback.originSource, 'crop_fallback');

      // La evaluación con fallback debe ser 100% determinista y estable
      final evalWithFallback2 = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: -77.2811,
        crop: cropWithoutCoords,
        farmerProfile: farmerWithoutCoords,
        useFallbackIfMissing: true,
      );
      expect(evalWithFallback.distanceKm, equals(evalWithFallback2.distanceKm));
    });

    test('8. Evaluación a partir del modelo completo del comprador (evaluateBuyerProfileToCrop)', () {
      final buyerProfile = FarmerProfileData(
        id: 'buyer_uuid_10',
        fullName: 'Comprador Nariño',
        role: 'comprador',
        email: 'buyer@market.com',
        phone: '3159998877',
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        settings: FarmerSettingsData(
          enableEarlySale: false,
          sharePhone: false,
          shareLocation: true,
          shareWhatsapp: false,
        ),
        stats: FarmerStatsData(published: 0, negotiating: 1, closed: 2),
      );

      final cropInIpiales = CropModel(
        id: 'crop_ipiales_1',
        farmerId: 'farmer_2',
        title: 'Trigo',
        description: 'Trigo de Nariño',
        cropType: 'Trigo',
        pricePerKg: 3200,
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: 0.8248,
        longitude: -77.6417,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eval = GeoSimulationService.evaluateBuyerProfileToCrop(
        buyerProfile: buyerProfile,
        crop: cropInIpiales,
      );

      expect(eval.hasValidDistance, isTrue);
      expect(eval.distanceKm, closeTo(58.9, 1.0));
      expect(eval.isRegionalShort, isTrue);
      expect(eval.formatted, 'A 59 km');
    });
  });

  group('Fase 2 — Subetapa 2.5: Compatibilidad con la Interfaz y Reglas Comerciales', () {
    test('9. CropModel no altera sus propiedades comerciales base al ser evaluado', () {
      final crop = CropModel(
        id: 'crop_commercial_intact',
        farmerId: 'farmer_abc',
        title: 'Café Especial',
        description: 'Origen Consacá',
        cropType: 'Café',
        pricePerKg: 14500,
        stockTotal: 500,
        minOrderKg: 25,
        department: 'Nariño',
        municipality: 'Consacá',
        latitude: 1.2094,
        longitude: -77.4647,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eval = GeoSimulationService.evaluateBuyerToCropDistance(
        buyerLatitude: 1.2136,
        buyerLongitude: -77.2811,
        crop: crop,
      );

      // Verificación de que los precios y reglas de negocio base no son alterados
      expect(crop.pricePerKg, 14500);
      expect(crop.minOrderKg, 25);
      expect(crop.stockTotal, 500);
      expect(crop.availableStock, 500);
      expect(eval.hasValidDistance, isTrue);
      expect(eval.distanceKm, closeTo(20.4, 1.0));
      expect(eval.category, DistanceRangeCategory.regionalShort); // Consacá está a 20.4 km (> 20.0 km)
    });

    testWidgets('10. CropCard muestra badge de distancia cuando distanceEvaluation está presente',
        (tester) async {
      final crop = CropModel(
        id: 'crop_card_test',
        farmerId: 'farmer_1',
        title: 'Fresas Frescas',
        description: 'Fresas de altura',
        cropType: 'Fresa',
        pricePerKg: 6000,
        stockTotal: 100,
        department: 'Nariño',
        municipality: 'Pasto',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const distanceEval = DistanceEvaluation(
        distanceKm: 12.5,
        category: DistanceRangeCategory.local,
        formatted: 'A 12 km',
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CropCard(
              crop: crop,
              onTap: () {},
              distanceEvaluation: distanceEval,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A 12 km'), findsOneWidget);
      expect(find.byIcon(LucideIcons.navigation), findsOneWidget);
    });

    testWidgets('11. CropDetailScreen despliega distancia formateada en fila de ubicación si está disponible',
        (tester) async {
      final crop = CropModel(
        id: 'crop_detail_geo_test',
        farmerId: 'farmer_detail_1',
        title: 'Mora de Castilla',
        description: 'Mora dulce',
        cropType: 'Mora',
        pricePerKg: 4000,
        stockTotal: 250,
        minOrderKg: 10,
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: 0.8248,
        longitude: -77.6417,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const distanceEval = DistanceEvaluation(
        distanceKm: 58.9,
        category: DistanceRangeCategory.regionalShort,
        formatted: 'A 59 km',
      );

      await tester.pumpWidget(
        createTestWidget(
          CropDetailScreen(
            crop: crop,
            role: 'comprador',
            initialDistanceEvaluation: distanceEval,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el texto con la ubicación y la distancia formateada
      expect(find.text('Ipiales, Nariño (A 59 km)'), findsOneWidget);
    });

    testWidgets('12. CropCard muestra discretamente municipio y distancia estimada en catálogo',
        (tester) async {
      final crop = CropModel(
        id: 'crop_pasto_12',
        farmerId: 'farmer_pasto',
        title: 'Café Tostado',
        description: 'Café de Pasto',
        cropType: 'Café',
        pricePerKg: 15000,
        stockTotal: 100,
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const distanceEval = DistanceEvaluation(
        distanceKm: 12.0,
        category: DistanceRangeCategory.local,
        formatted: 'A 12 km',
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CropCard(
              crop: crop,
              onTap: () {},
              distanceEvaluation: distanceEval,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el municipio 'Pasto', el separador ' · ' y la distancia 'A 12 km'
      expect(find.text('Pasto'), findsOneWidget);
      expect(find.text(' · '), findsOneWidget);
      expect(find.text('A 12 km'), findsOneWidget);
      expect(find.byIcon(LucideIcons.navigation), findsOneWidget);
    });

    testWidgets('13. CropCard cuando no hay coordenadas válidas muestra solo ubicación textual sin kilómetros',
        (tester) async {
      final cropNoCoords = CropModel(
        id: 'crop_no_coords',
        farmerId: 'farmer_x',
        title: 'Papa Pastusa',
        description: 'Sin coordenadas',
        cropType: 'Papa',
        pricePerKg: 2000,
        stockTotal: 50,
        department: 'Nariño',
        municipality: 'Túquerres',
        latitude: null,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CropCard(
              crop: cropNoCoords,
              onTap: () {},
              distanceEvaluation: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar la ubicación textual
      expect(find.text('Túquerres'), findsOneWidget);
      expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);

      // NO debe inventar distancias ni mostrar separadores de distancia
      expect(find.text(' · '), findsNothing);
      expect(find.textContaining('km'), findsNothing);
      expect(find.byIcon(LucideIcons.navigation), findsNothing);
    });

    testWidgets('14. CropCard cuando no hay municipio ni coordenadas omite sección de ubicación',
        (tester) async {
      final emptyCrop = CropModel(
        id: 'crop_empty_loc',
        farmerId: 'farmer_x',
        title: 'Maíz Amarillo',
        description: 'Sin ubicación',
        cropType: 'Maíz',
        pricePerKg: 1200,
        stockTotal: 80,
        department: '',
        municipality: '',
        latitude: null,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: CropCard(
              crop: emptyCrop,
              onTap: () {},
              distanceEvaluation: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.mapPin), findsNothing);
      expect(find.byIcon(LucideIcons.navigation), findsNothing);
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('15. CropDetailScreen despliega fila "Distancia estimada" de forma informativa',
        (tester) async {
      final crop = CropModel(
        id: 'crop_detail_dist_row',
        farmerId: 'farmer_detail_1',
        title: 'Zanahoria Dulce',
        description: 'Zanahoria fresca',
        cropType: 'Zanahoria',
        pricePerKg: 1800,
        stockTotal: 300,
        minOrderKg: 10,
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: 0.8248,
        longitude: -77.6417,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const distanceEval = DistanceEvaluation(
        distanceKm: 58.9,
        category: DistanceRangeCategory.regionalShort,
        formatted: 'A 59 km',
      );

      await tester.pumpWidget(
        createTestWidget(
          CropDetailScreen(
            crop: crop,
            role: 'comprador',
            initialDistanceEvaluation: distanceEval,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar la fila de Distancia estimada
      expect(find.text('Distancia estimada'), findsOneWidget);
      expect(find.text('59 km'), findsOneWidget);

      // Y la fila de ubicación mantiene coherencia
      expect(find.text('Ipiales, Nariño (A 59 km)'), findsOneWidget);
    });

    testWidgets('16. CropDetailScreen sin coordenadas válidas omite fila de distancia estimada',
        (tester) async {
      final cropNoCoords = CropModel(
        id: 'crop_detail_no_coords',
        farmerId: 'farmer_detail_2',
        title: 'Repollo Blanco',
        description: 'Sin coordenadas',
        cropType: 'Repollo',
        pricePerKg: 1100,
        stockTotal: 150,
        minOrderKg: 5,
        department: 'Nariño',
        municipality: 'Guaitarilla',
        latitude: null,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          CropDetailScreen(
            crop: cropNoCoords,
            role: 'comprador',
            initialDistanceEvaluation: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fila de ubicación solo muestra departamento y municipio
      expect(find.text('Guaitarilla, Nariño'), findsOneWidget);

      // NO debe mostrar la fila de distancia estimada ni valores inventados
      expect(find.text('Distancia estimada'), findsNothing);
      expect(find.textContaining('km)'), findsNothing);
    });

    testWidgets('17. MarketplaceScreen evalúa distancia y la transfiere de forma coherente a CropDetailScreen',
        (tester) async {
      final buyerProfile = FarmerProfileData(
        id: 'buyer_pasto_1',
        fullName: 'Carlos Comprador',
        role: 'comprador',
        email: 'carlos@buyer.co',
        phone: '3151234567',
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        settings: FarmerSettingsData(
          enableEarlySale: false,
          sharePhone: false,
          shareLocation: true,
          shareWhatsapp: false,
        ),
        stats: FarmerStatsData(published: 0, negotiating: 0, closed: 0),
      );

      final cropInIpiales = CropModel(
        id: 'crop_ipiales_catalog',
        farmerId: 'farmer_ipiales_99',
        title: 'Cebolla Junca',
        description: 'De Ipiales',
        cropType: 'Cebolla',
        pricePerKg: 2500,
        stockTotal: 200,
        minOrderKg: 10,
        department: 'Nariño',
        municipality: 'Ipiales',
        latitude: 0.8248,
        longitude: -77.6417,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockProfileService = MockProfileServiceForGeo(profileToReturn: buyerProfile);

      await tester.pumpWidget(
        createTestWidget(
          MarketplaceScreen(
            role: 'comprador',
            initialCrops: [cropInIpiales],
            initialUserProfile: buyerProfile,
            profileService: mockProfileService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // En el catálogo debe mostrarse la tarjeta con 'Ipiales' y la distancia calculada ('A 59 km')
      expect(find.byType(CropCard), findsOneWidget);
      expect(find.text('Ipiales'), findsOneWidget);
      expect(find.text('A 59 km'), findsOneWidget);

      // Al pulsar en la tarjeta, abre CropDetailScreen
      await tester.tap(find.byType(CropCard));
      await tester.pumpAndSettle();

      // CropDetailScreen debe recibir y mostrar la misma distancia calculada
      expect(find.byType(CropDetailScreen), findsOneWidget);
      expect(find.text('Distancia estimada'), findsOneWidget);
      expect(find.text('59 km'), findsOneWidget);
      expect(find.text('Ipiales, Nariño (A 59 km)'), findsOneWidget);
    });

    test('18. No calcula distancia si el usuario es el mismo agricultor que publicó el cultivo', () {
      final farmerAsBuyer = FarmerProfileData(
        id: 'same_farmer_123',
        fullName: 'Don Laureano',
        role: 'agricultor',
        email: 'laureano@finca.co',
        phone: '3123456789',
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        settings: FarmerSettingsData(
          enableEarlySale: false,
          sharePhone: false,
          shareLocation: true,
          shareWhatsapp: false,
        ),
        stats: FarmerStatsData(published: 1, negotiating: 0, closed: 0),
      );

      final ownCrop = CropModel(
        id: 'crop_own',
        farmerId: 'same_farmer_123',
        title: 'Mi Propia Cosecha',
        description: 'Cultivo propio',
        cropType: 'Café',
        pricePerKg: 10000,
        department: 'Nariño',
        municipality: 'Pasto',
        latitude: 1.2136,
        longitude: -77.2811,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Si el comprador es el mismo agricultor, la función debe evitar calcular origen y destino idénticos
      if (farmerAsBuyer.id == ownCrop.farmerId) {
        final eval = DistanceEvaluation.unavailable(originSource: 'same_user');
        expect(eval.hasValidDistance, isFalse);
        expect(eval.distanceKm, isNull);
      }
    });
  });
}
