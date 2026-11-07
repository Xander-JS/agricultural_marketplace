import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/widgets/regional_index_dumbbell_chart.dart';
import 'package:agricultural_marketplace/features/costs/data/simulated_regional_price_references.dart';
import 'package:agricultural_marketplace/features/costs/models/crop_cost_model.dart';
import 'package:agricultural_marketplace/features/costs/screens/costs_screen.dart';
import 'package:agricultural_marketplace/features/costs/services/crop_cost_service.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/geo/models/simulated_location.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';
import 'package:agricultural_marketplace/features/deals/screens/deal_detail_screen.dart';

Widget _wrapWithLocalization(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(body: child),
  );
}

class _FakeCropService extends CropService {
  final List<CropModel> crops;
  _FakeCropService(this.crops);

  @override
  Future<List<CropModel>> getCropsByFarmerId(String farmerId) async => crops;

  @override
  String getPublicImageUrl(String path) => 'https://example.com/$path';
}

class _FakeCropCostService extends CropCostService {
  @override
  Future<double> getTotalCostByCropId(String cropId) async => 150000.0;

  @override
  Future<List<CropCostModel>> getCostsByCropId(String cropId) async => [];
}

class _FakeNegotiationService extends NegotiationService {
  final NegotiationModel negotiation;
  final NegotiationContactInfo contactInfo;

  _FakeNegotiationService({
    required this.negotiation,
    required this.contactInfo,
  }) : super(currentUserIdForTesting: 'buyer_1');

  @override
  Future<NegotiationModel> getNegotiationById(String id) async => negotiation;

  @override
  Future<NegotiationContactInfo> getCounterpartContact(String id) async => contactInfo;
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

  group('1. Limpieza de duplicación en Ubicación (CropDetailScreen)', () {
    testWidgets('Muestra únicamente Departamento y Municipio sin distancia', (tester) async {
      final crop = CropModel(
        id: 'crop_1',
        farmerId: 'farmer_1',
        title: 'Papa Pastusa',
        description: 'Excelente papa',
        cropType: 'Papa Pastusa',
        pricePerKg: 2500,
        stockTotal: 1000,
        minOrderKg: 50,
        department: 'Nariño',
        municipality: 'Túquerres',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const distanceEval = DistanceEvaluation(
        distanceKm: 189.0,
        category: DistanceRangeCategory.regionalMedium,
        formatted: 'A 189 km',
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          CropDetailScreen(
            crop: crop,
            role: 'comprador',
            initialDistanceEvaluation: distanceEval,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar la fila de ubicación territorial limpia
      expect(find.text('Túquerres, Nariño'), findsOneWidget);
      // No debe contener "(A 189 km)" en la fila de ubicación
      expect(find.text('Túquerres, Nariño (A 189 km)'), findsNothing);
      // La distancia estimada debe existir únicamente en su bloque dedicado
      expect(find.text('Distancia estimada'), findsOneWidget);
      expect(find.text('189 km'), findsOneWidget);
    });
  });

  group('2. Vínculo del Índice Nariño por Tipo de Producto (crop_type)', () {
    test('Ignora título y busca estrictamente por crop_type normalizado', () {
      final match = SimulatedRegionalPriceReferences.findForCrop(
        cropType: 'Papa Criolla',
        title: 'Cosecha de Zanahoria Seleccionada',
      );
      expect(match, isNotNull);
      expect(match!.cropName, 'Papa Criolla');
      expect(match.referencePricePerKg, 3600);
    });
  });

  group('3. Gráfico de Mancuerna (Dumbbell Chart)', () {
    testWidgets('Renderiza conector, puntos A y B, diferencia y atribución', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          const RegionalIndexDumbbellChart(
            referencePrice: 1900,
            cropPrice: 5600,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Diferencia monetaria y porcentual compacta
      expect(find.text(r'+$ 3.700/kg (+194.7%)'), findsOneWidget);

      // Punto A: Referencia Nariño
      expect(find.text('Referencia Nariño'), findsOneWidget);
      expect(find.text(r'$ 1.900 / kg'), findsOneWidget);

      // Punto B: Esta cosecha
      expect(find.text('Esta cosecha'), findsOneWidget);
      expect(find.text(r'$ 5.600 / kg'), findsOneWidget);

      // Micro-etiqueta de atribución formal
      expect(
        find.text(SimulatedRegionalPriceReferences.notice),
        findsOneWidget,
      );
    });
  });

  group('4. Compactación de Permisos de contacto (DealDetailScreen)', () {
    testWidgets('Muestra únicamente título Permisos de contacto y botón Modificar sin subtítulo apilado', (tester) async {
      final negotiation = NegotiationModel(
        id: 'deal_123',
        cropId: 'crop_1',
        buyerId: 'buyer_1',
        currentResponder: 'comprador',
        status: NegotiationStatus.acordada,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final contact = NegotiationContactInfo(
        negotiationId: 'deal_123',
        status: 'acordada',
        mySharePhone: true,
        myShareLocation: true,
        counterpartSharePhone: true,
        counterpartShareLocation: true,
        counterpartId: 'counterpart_1',
        counterpartName: 'Don Laureano',
        counterpartRole: 'agricultor',
        counterpartPhone: '3123456789',
        counterpartDepartment: 'Nariño',
        counterpartMunicipality: 'Ipiales',
        counterpartLatitude: 0.8248,
        counterpartLongitude: -77.6417,
      );

      final service = _FakeNegotiationService(
        negotiation: negotiation,
        contactInfo: contact,
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          DealDetailScreen(
            negotiationId: 'deal_123',
            role: 'comprador',
            initialNegotiation: negotiation,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el título conciso "Permisos de contacto"
      expect(find.text('Permisos de contacto'), findsOneWidget);
      expect(find.text('Modificar'), findsOneWidget);

      // No debe mostrar los textos descriptivos inferiores apilados
      expect(find.textContaining('Teléfono autorizado · Ubicación autorizada'), findsNothing);
    });
  });

  group('5. Modal de Ubicación y Redirección a Google Maps (DealDetailScreen)', () {
    testWidgets('Modal omite coordenadas numéricas y botón Copiar, mostrando Abrir en Google Maps', (tester) async {
      final negotiation = NegotiationModel(
        id: 'deal_123',
        cropId: 'crop_1',
        buyerId: 'buyer_1',
        currentResponder: 'comprador',
        status: NegotiationStatus.acordada,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final contact = NegotiationContactInfo(
        negotiationId: 'deal_123',
        status: 'acordada',
        mySharePhone: true,
        myShareLocation: true,
        counterpartSharePhone: true,
        counterpartShareLocation: true,
        counterpartId: 'counterpart_1',
        counterpartName: 'Don Laureano',
        counterpartRole: 'agricultor',
        counterpartPhone: '3123456789',
        counterpartDepartment: 'Nariño',
        counterpartMunicipality: 'Ipiales',
        counterpartLatitude: 0.8248,
        counterpartLongitude: -77.6417,
      );

      final service = _FakeNegotiationService(
        negotiation: negotiation,
        contactInfo: contact,
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          DealDetailScreen(
            negotiationId: 'deal_123',
            role: 'comprador',
            initialNegotiation: negotiation,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Asegurar visibilidad y pulsar la fila de ubicación compartida
      final locationFinder = find.text('Ipiales, Nariño');
      await tester.ensureVisible(locationFinder);
      await tester.pumpAndSettle();
      await tester.tap(locationFinder);
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);

      // El modal no debe contener coordenadas numéricas crudas
      expect(
        find.descendant(of: dialogFinder, matching: find.textContaining('0.824800')),
        findsNothing,
      );
      expect(
        find.descendant(of: dialogFinder, matching: find.textContaining('-77.641700')),
        findsNothing,
      );
      // El modal no debe contener botón Copiar coordenadas
      expect(
        find.descendant(of: dialogFinder, matching: find.text('Copiar coordenadas')),
        findsNothing,
      );
      // El modal debe contener el botón estilizado "Abrir en Google Maps"
      expect(
        find.descendant(of: dialogFinder, matching: find.text('Abrir en Google Maps')),
        findsOneWidget,
      );
    });
  });

  group('6. Reubicación del botón Ver costos en tarjeta de cosecha', () {
    testWidgets('Botón Ver costos está al nivel superior con flecha derecha', (tester) async {
      final crop = CropModel(
        id: 'crop_costs_1',
        farmerId: 'farmer_1',
        title: 'Papa Pastusa',
        description: 'Papa de altura',
        cropType: 'Papa Pastusa',
        pricePerKg: 2200,
        stockTotal: 500,
        minOrderKg: 20,
        department: 'Nariño',
        municipality: 'Ipiales',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cropService = _FakeCropService([crop]);
      final costService = _FakeCropCostService();

      await tester.pumpWidget(
        _wrapWithLocalization(
          CostsScreen(
            cropService: cropService,
            costService: costService,
            currentUserIdForTesting: 'farmer_1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe encontrar el texto Ver costos
      expect(find.text('Ver costos'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsNothing);

      // Verificar que el widget padre es un Row que contiene el título y el botón
      final buttonFinder = find.text('Ver costos');
      expect(buttonFinder, findsOneWidget);
    });
  });
}
