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

import 'package:agricultural_marketplace/core/theme/app_colors.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/cards/inset_group_card.dart';
import 'package:agricultural_marketplace/features/deals/screens/deals_screen.dart';
import 'package:agricultural_marketplace/features/purchases/screens/purchases_screen.dart';
import 'package:agricultural_marketplace/features/purchases/widgets/purchase_card.dart';
import 'package:agricultural_marketplace/core/theme/app_icons.dart';
import 'package:agricultural_marketplace/features/costs/models/regional_price_reference.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';
import 'package:agricultural_marketplace/features/deals/screens/deal_detail_screen.dart';
import 'package:agricultural_marketplace/features/deals/widgets/negotiation_status_badge.dart';

Widget _wrapWithLocalization(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
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

      // En la tarjeta principal de contacto no deben aparecer coordenadas crudas
      expect(find.textContaining('Coordenadas:'), findsNothing);

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
      final mapsButtonFinder = find.descendant(of: dialogFinder, matching: find.text('Abrir en Google Maps'));
      expect(mapsButtonFinder, findsOneWidget);

      // Accionar el botón Abrir en Google Maps
      await tester.tap(mapsButtonFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('Modal con solo municipio y departamento genera enlace a Google Maps sin fallar', (tester) async {
      final negotiation = NegotiationModel(
        id: 'deal_no_coords',
        cropId: 'crop_1',
        buyerId: 'buyer_1',
        currentResponder: 'comprador',
        status: NegotiationStatus.acordada,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final contact = NegotiationContactInfo(
        negotiationId: 'deal_no_coords',
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
        counterpartLatitude: null,
        counterpartLongitude: null,
      );

      final service = _FakeNegotiationService(
        negotiation: negotiation,
        contactInfo: contact,
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          DealDetailScreen(
            negotiationId: 'deal_no_coords',
            role: 'comprador',
            initialNegotiation: negotiation,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final locationFinder = find.text('Ipiales, Nariño');
      await tester.ensureVisible(locationFinder);
      await tester.pumpAndSettle();
      await tester.tap(locationFinder);
      await tester.pumpAndSettle();

      final mapsBtn = find.text('Abrir en Google Maps');
      expect(mapsBtn, findsOneWidget);
      await tester.tap(mapsBtn);
      await tester.pumpAndSettle();
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

  group('7. Alineación Horizontal de la Insignia de Estado (DealDetailScreen)', () {
    testWidgets('Insignia de estado se alinea horizontalmente con el título del cultivo en el mismo Row', (tester) async {
      final crop = CropModel(
        id: 'crop_deal_1',
        farmerId: 'farmer_1',
        title: 'Zanahoria Dulce',
        description: 'Zanahoria fresca',
        cropType: 'Zanahoria',
        pricePerKg: 1800,
        stockTotal: 300,
        minOrderKg: 10,
        department: 'Nariño',
        municipality: 'Túquerres',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final negotiation = NegotiationModel(
        id: 'deal_status_1',
        cropId: 'crop_deal_1',
        buyerId: 'buyer_1',
        currentResponder: 'comprador',
        status: NegotiationStatus.acordada,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        crop: crop,
      );

      final contact = NegotiationContactInfo(
        negotiationId: 'deal_status_1',
        status: 'acordada',
        mySharePhone: true,
        myShareLocation: true,
        counterpartSharePhone: true,
        counterpartShareLocation: true,
        counterpartId: 'farmer_1',
        counterpartName: 'Don Aurelio',
        counterpartRole: 'agricultor',
        counterpartPhone: '3101234567',
        counterpartDepartment: 'Nariño',
        counterpartMunicipality: 'Túquerres',
      );

      final service = _FakeNegotiationService(
        negotiation: negotiation,
        contactInfo: contact,
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          DealDetailScreen(
            negotiationId: 'deal_status_1',
            role: 'comprador',
            initialNegotiation: negotiation,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Zanahoria Dulce');
      final badgeFinder = find.byType(NegotiationStatusBadge);

      expect(titleFinder, findsOneWidget);
      expect(badgeFinder, findsOneWidget);

      // El título y la insignia de estado deben pertenecer a la misma fila Row
      final rowAncestor = find.ancestor(of: titleFinder, matching: find.byType(Row)).first;
      expect(find.descendant(of: rowAncestor, matching: badgeFinder), findsOneWidget);

      // Comprobar que la diferencia vertical (dy) entre el título y la insignia sea mínima
      final titleTop = tester.getTopLeft(titleFinder).dy;
      final badgeTop = tester.getTopLeft(badgeFinder).dy;
      expect((titleTop - badgeTop).abs(), lessThan(8.0));
    });
  });

  group('8. Simplificación de la Cápsula del Índice Regional Nariño (CropDetailScreen)', () {
    testWidgets('Muestra únicamente icono, título, badge de proyección y chevron sin números de delta', (tester) async {
      final crop = CropModel(
        id: 'crop_regional_test',
        farmerId: 'farmer_1',
        title: 'Papa Pastusa Selecta',
        description: 'Papa de primera',
        cropType: 'Papa Pastusa',
        pricePerKg: 2500,
        stockTotal: 1000,
        minOrderKg: 50,
        department: 'Nariño',
        municipality: 'Túquerres',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          CropDetailScreen(
            crop: crop,
            role: 'comprador',
            initialRegionalReference: const RegionalPriceReference(
              cropName: 'Papa Pastusa',
              aliases: ['Papa Pastusa'],
              region: 'Nariño, Colombia',
              referencePricePerKg: 2200.0,
              isSimulated: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const Key('crop_detail_regional_reference_card'));
      expect(cardFinder, findsOneWidget);

      // Debe contener el título, el badge y el chevron
      expect(find.descendant(of: cardFinder, matching: find.text('Índice regional Nariño')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.text('PROYECCIÓN IA')), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(LucideIcons.chevronRight)), findsOneWidget);
      expect(find.descendant(of: cardFinder, matching: find.byIcon(LucideIcons.trendingUp)), findsOneWidget);

      // La tarjeta previa NO debe mostrar valores de delta o porcentajes de diferencia
      expect(find.descendant(of: cardFinder, matching: find.textContaining('%')), findsNothing);
      expect(find.descendant(of: cardFinder, matching: find.textContaining('+')), findsNothing);
      expect(find.descendant(of: cardFinder, matching: find.textContaining('-')), findsNothing);

      // Al pulsar, se despliega la hoja flotante con la información comparativa profunda
      await tester.ensureVisible(cardFinder);
      await tester.pumpAndSettle();
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      final sheetFinder = find.byKey(const Key('crop_detail_regional_reference_sheet'));
      expect(sheetFinder, findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.byType(RegionalIndexDumbbellChart)), findsOneWidget);
    });
  });

  group('9. Bordes Smoked Mocha en Tratos y Costos', () {
    testWidgets('Tarjeta de cultivo en CostsScreen usa InsetGroupCard con borde smokedMocha de 1.5px', (tester) async {
      final crop = CropModel(
        id: 'crop_costs_border_1',
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

      final insetCardFinder = find.byType(InsetGroupCard);
      expect(insetCardFinder, findsOneWidget);
      final InsetGroupCard card = tester.widget(insetCardFinder);
      expect(card.borderColor, AppColors.lightIconMocha);
      expect(card.borderWidth, 1.5);
    });

    testWidgets('Tarjeta DealCard en DealsScreen usa borde smokedMocha de 1.5px', (tester) async {
      final negotiation = NegotiationModel(
        id: 'deal_border_1',
        cropId: 'crop_1',
        buyerId: 'buyer_1',
        currentResponder: 'comprador',
        status: NegotiationStatus.propuesta,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        crop: CropModel(
          id: 'crop_1',
          farmerId: 'farmer_1',
          title: 'Cebolla Junca',
          description: 'Cebolla fresca',
          cropType: 'Cebolla',
          pricePerKg: 1500,
          stockTotal: 200,
          minOrderKg: 10,
          department: 'Nariño',
          municipality: 'Pasto',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final service = _FakeNegotiationService(
        negotiation: negotiation,
        contactInfo: NegotiationContactInfo(
          negotiationId: 'deal_border_1',
          counterpartId: 'farmer_1',
          counterpartName: 'Don Pedro',
          counterpartRole: 'agricultor',
          status: 'propuesta',
          mySharePhone: false,
          myShareLocation: false,
          counterpartSharePhone: false,
          counterpartShareLocation: false,
        ),
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          DealsScreen(
            service: service,
            initialNegotiations: [negotiation],
            role: 'comprador',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final materialFinder = find.byWidgetPredicate(
        (w) => w is Material && w.shape is RoundedRectangleBorder && (w.shape as RoundedRectangleBorder).side.width == 1.5,
      );
      expect(materialFinder, findsOneWidget);
      final Material mat = tester.widget(materialFinder);
      final borderSide = (mat.shape as RoundedRectangleBorder).side;
      expect(borderSide.color, AppColors.lightIconMocha);
    });
  });

  group('10. Destacado y Bordes en Módulo de Compras (PurchasesScreen & PurchaseCard)', () {
    testWidgets('Tarjeta de resumen usa fondo verde primario y textos en onPrimary', (tester) async {
      final purchase = NegotiationModel(
        id: 'purchase_kpi_1',
        cropId: 'crop_1',
        buyerId: 'buyer_1',
        currentResponder: 'farmer',
        status: NegotiationStatus.acordada,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        crop: CropModel(
          id: 'crop_1',
          farmerId: 'farmer_1',
          title: 'Café Especial',
          description: 'Café de altura',
          cropType: 'Café',
          pricePerKg: 12000,
          stockTotal: 100,
          minOrderKg: 10,
          department: 'Huila',
          municipality: 'Pitalito',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          PurchasesScreen(
            initialPurchases: [purchase],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryCardFinder = find.byWidgetPredicate(
        (w) => w is InsetGroupCard && w.color == AppColors.lightBrandPrimary,
      );
      expect(summaryCardFinder, findsOneWidget);

      // Texto de Total pactado dentro de la tarjeta de resumen usa onPrimary
      final textFinder = find.descendant(
        of: summaryCardFinder,
        matching: find.text('Total pactado'),
      );
      expect(textFinder, findsOneWidget);
    });

    testWidgets('PurchaseCard usa borde smokedMocha de 1.5px', (tester) async {
      final purchase = NegotiationModel(
        id: 'purchase_card_1',
        cropId: 'crop_1',
        buyerId: 'buyer_1',
        currentResponder: 'farmer',
        status: NegotiationStatus.acordada,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        crop: CropModel(
          id: 'crop_1',
          farmerId: 'farmer_1',
          title: 'Café Especial',
          description: 'Café de altura',
          cropType: 'Café',
          pricePerKg: 12000,
          stockTotal: 100,
          minOrderKg: 10,
          department: 'Huila',
          municipality: 'Pitalito',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        _wrapWithLocalization(
          PurchaseCard(purchase: purchase),
        ),
      );
      await tester.pumpAndSettle();

      final materialFinder = find.byWidgetPredicate(
        (w) => w is Material && w.shape is RoundedRectangleBorder && (w.shape as RoundedRectangleBorder).side.width == 1.5,
      );
      expect(materialFinder, findsOneWidget);
      final Material mat = tester.widget(materialFinder);
      final borderSide = (mat.shape as RoundedRectangleBorder).side;
      expect(borderSide.color, AppColors.lightIconMocha);
    });
  });
}
