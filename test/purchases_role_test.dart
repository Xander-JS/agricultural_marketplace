import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_offer_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/purchases/screens/purchases_screen.dart';
import 'package:agricultural_marketplace/features/purchases/widgets/purchase_card.dart';

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

  Widget createTestWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  final sampleCrop = CropModel(
    id: 'crop-coffee-01',
    farmerId: 'farmer-uuid-01',
    title: 'Café Especial Huila Supremo',
    description: 'Café de altura pergamino seco.',
    cropType: 'Café',
    pricePerKg: 14000.0,
    stockTotal: 1000.0,
    department: 'Huila',
    municipality: 'San Agustín',
    status: CropStatus.activa,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  final sampleCropAvocado = CropModel(
    id: 'crop-avo-02',
    farmerId: 'farmer-uuid-02',
    title: 'Aguacate Hass Exportación',
    description: 'Aguacate calibre 18-22 certificado.',
    cropType: 'Aguacate',
    pricePerKg: 6500.0,
    stockTotal: 2500.0,
    department: 'Antioquia',
    municipality: 'Urrao',
    status: CropStatus.activa,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  final offerAgreed = NegotiationOfferModel(
    id: 'offer-agreed-1',
    negotiationId: 'neg-agreed-1',
    senderId: 'farmer-uuid-01',
    quantityKg: 300.0,
    proposedPricePerKg: 13500.0,
    deliveryMethod: 'Transporte a bodega',
    message: 'Trato cerrado con flete incluido.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  final offerCompleted = NegotiationOfferModel(
    id: 'offer-comp-2',
    negotiationId: 'neg-comp-2',
    senderId: 'buyer-uuid-01',
    quantityKg: 500.0,
    proposedPricePerKg: 6200.0,
    deliveryMethod: 'Recogida en finca',
    message: 'Pago y entrega completada satisfactoriamente.',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
  );

  final sampleAgreedPurchase = NegotiationModel(
    id: 'neg-agreed-1',
    cropId: 'crop-coffee-01',
    buyerId: 'buyer-uuid-01',
    status: NegotiationStatus.acordada,
    currentResponder: 'farmer',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    crop: sampleCrop,
    farmerProfile: {'full_name': 'Don Pedro Albornoz'},
    offers: [offerAgreed],
  );

  final sampleCompletedPurchase = NegotiationModel(
    id: 'neg-comp-2',
    cropId: 'crop-avo-02',
    buyerId: 'buyer-uuid-01',
    status: NegotiationStatus.completada,
    currentResponder: 'buyer',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    updatedAt: DateTime.now().subtract(const Duration(days: 6)),
    crop: sampleCropAvocado,
    farmerProfile: {'full_name': 'María Santos'},
    offers: [offerCompleted],
  );

  group('Etapa 6 — Módulo Compras: Pantalla PurchasesScreen', () {
    testWidgets('Muestra pestañas, resumen de métricas y tarjetas de compras en modo claro', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: PurchasesScreen(
            initialPurchases: [sampleAgreedPurchase, sampleCompletedPurchase],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pestañas
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Acordadas'), findsOneWidget);
      expect(find.text('Completadas'), findsOneWidget);

      // Banner resumen de métricas
      expect(find.text('Acuerdos vigentes'), findsOneWidget);
      expect(find.text('Total pactado'), findsWidgets);
      expect(find.text('Volumen total'), findsOneWidget);

      // Valores métricos calculados:
      // Acuerdos vigentes: 1
      expect(find.text('1'), findsOneWidget);
      // Volumen total: 300 + 500 = 800 kg
      expect(find.text('800 kg'), findsOneWidget);

      // Tarjetas de compras renderizadas en pestaña "Todas"
      expect(find.text('Café Especial Huila Supremo'), findsOneWidget);
      expect(find.text('Aguacate Hass Exportación'), findsOneWidget);
      expect(find.text('Don Pedro Albornoz'), findsOneWidget);
      expect(find.text('María Santos'), findsOneWidget);
      expect(find.text('Acordada'), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);
    });

    testWidgets('Filtrado por pestañas muestra únicamente las compras de cada estado', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: PurchasesScreen(
            initialPurchases: [sampleAgreedPurchase, sampleCompletedPurchase],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // En "Todas" se ven ambos cultivos
      expect(find.text('Café Especial Huila Supremo'), findsOneWidget);
      expect(find.text('Aguacate Hass Exportación'), findsOneWidget);

      // Cambiar a pestaña "Acordadas"
      await tester.tap(find.text('Acordadas'));
      await tester.pumpAndSettle();

      expect(find.text('Café Especial Huila Supremo'), findsOneWidget);
      expect(find.text('Aguacate Hass Exportación'), findsNothing);

      // Cambiar a pestaña "Completadas"
      await tester.tap(find.text('Completadas'));
      await tester.pumpAndSettle();

      expect(find.text('Aguacate Hass Exportación'), findsOneWidget);
      expect(find.text('Café Especial Huila Supremo'), findsNothing);
    });

    testWidgets('Estado vacío muestra mensaje descriptivo y botón para explorar mercado', (tester) async {
      bool exploreMarketCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          child: PurchasesScreen(
            initialPurchases: const [],
            onExploreMarket: () {
              exploreMarketCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No tienes compras aún'), findsOneWidget);
      expect(find.text('Módulo de Compras'), findsOneWidget);
      expect(find.text('Rol Comerciante'), findsOneWidget);
      expect(find.text('Explorar mercado'), findsOneWidget);

      // Probar callback del botón
      await tester.tap(find.text('Explorar mercado'));
      await tester.pumpAndSettle();

      expect(exploreMarketCalled, isTrue);
    });

    testWidgets('PurchasesScreen soporta modo oscuro sin excepciones visuales', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: PurchasesScreen(
            initialPurchases: [sampleAgreedPurchase],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Café Especial Huila Supremo'), findsOneWidget);
      expect(find.text('Don Pedro Albornoz'), findsOneWidget);
      expect(find.text('Acordada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Etapa 6 — Módulo Compras: Widget PurchaseCard', () {
    testWidgets('PurchaseCard renderiza datos del productor, entrega y valores calculados', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: PurchaseCard(purchase: sampleAgreedPurchase),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Café Especial Huila Supremo'), findsOneWidget);
      expect(find.text('Don Pedro Albornoz'), findsOneWidget);
      expect(find.text('San Agustín, Huila'), findsOneWidget);
      expect(find.text('300 kg'), findsOneWidget);
      expect(find.text('Entrega: Transporte a bodega'), findsOneWidget);
      expect(find.text('Acordada'), findsOneWidget);
      expect(find.text('Ver detalle del acuerdo →'), findsOneWidget);
    });

    testWidgets('PurchaseCard maneja fallback cuando farmerProfile es nulo', (tester) async {
      final purchaseWithoutProfile = NegotiationModel(
        id: 'neg-fallback',
        cropId: 'crop-coffee-01',
        buyerId: 'buyer-uuid-01',
        status: NegotiationStatus.acordada,
        currentResponder: 'farmer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        crop: sampleCrop,
        farmerProfile: null,
        offers: [offerAgreed],
      );

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: PurchaseCard(purchase: purchaseWithoutProfile),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productor (San Agustín)'), findsOneWidget);
    });

    testWidgets('PurchaseCard soporta modo oscuro sin errores', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: Scaffold(
            body: PurchaseCard(purchase: sampleCompletedPurchase),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aguacate Hass Exportación'), findsOneWidget);
      expect(find.text('María Santos'), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Etapa 6 — Deserialización de NegotiationModel para Compras', () {
    test('NegotiationModel deserializa correctamente crops con profiles anidados', () {
      final jsonMap = {
        'id': 'neg-deser-01',
        'crop_id': 'crop-deser-01',
        'buyer_id': 'buyer-deser-01',
        'status': 'acordada',
        'current_responder': 'buyer',
        'created_at': '2026-10-14T05:00:00Z',
        'updated_at': '2026-10-14T07:00:00Z',
        'crops': {
          'id': 'crop-deser-01',
          'farmer_id': 'farmer-deser-01',
          'title': 'Plátano Hartón',
          'description': 'Plátano de excelente calidad.',
          'crop_type': 'Plátano',
          'price_per_kg': 3500.0,
          'stock_total': 1200.0,
          'stock_committed': 0.0,
          'stock_sold': 0.0,
          'min_order_kg': 50.0,
          'department': 'Quindío',
          'municipality': 'Armenia',
          'status': 'activa',
          'created_at': '2026-10-10T00:00:00Z',
          'updated_at': '2026-10-10T00:00:00Z',
          'profiles': {
            'id': 'farmer-deser-01',
            'full_name': 'Gustavo Campesino',
          },
        },
        'negotiation_offers': [
          {
            'id': 'offer-deser-01',
            'negotiation_id': 'neg-deser-01',
            'sender_id': 'farmer-deser-01',
            'quantity_kg': 400.0,
            'proposed_price_per_kg': 3200.0,
            'delivery_method': 'Recogida en finca',
            'message': 'Acordado',
            'created_at': '2026-10-14T06:00:00Z',
          }
        ],
      };

      final model = NegotiationModel.fromJson(jsonMap);
      expect(model.id, 'neg-deser-01');
      expect(model.status, NegotiationStatus.acordada);
      expect(model.farmerProfile?['full_name'], 'Gustavo Campesino');
      expect(model.crop?.title, 'Plátano Hartón');
      expect(model.offers?.length, 1);
      expect(model.offers?.first.quantityKg, 400.0);
    });
  });
}
