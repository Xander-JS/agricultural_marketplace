import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/navigation/app_bottom_navigation.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/crop/widgets/make_offer_sheet.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_offer_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/screens/deal_detail_screen.dart';
import 'package:agricultural_marketplace/features/deals/screens/deals_screen.dart';
import 'package:agricultural_marketplace/features/purchases/screens/purchases_screen.dart';

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
    id: 'crop-integ-1',
    farmerId: 'farmer-integ-1',
    title: 'Cacao Fino de Aroma',
    description: 'Cacao fermentado y seco de alta calidad.',
    cropType: 'Cacao',
    pricePerKg: 18000.0,
    stockTotal: 1500.0,
    stockCommitted: 0.0,
    stockSold: 0.0,
    minOrderKg: 100.0,
    department: 'Santander',
    municipality: 'San Vicente de Chucurí',
    status: CropStatus.activa,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  final sampleOffer = NegotiationOfferModel(
    id: 'offer-integ-1',
    negotiationId: 'neg-integ-1',
    senderId: 'buyer-integ-1',
    quantityKg: 250.0,
    proposedPricePerKg: 17500.0,
    deliveryMethod: 'Entrega en bodega',
    message: 'Oferta seria con pago a la entrega.',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  );

  final sampleNegotiationFarmerTurn = NegotiationModel(
    id: 'neg-integ-1',
    cropId: 'crop-integ-1',
    buyerId: 'buyer-integ-1',
    status: NegotiationStatus.propuesta,
    currentResponder: 'farmer',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    crop: sampleCrop,
    buyerProfile: {'full_name': 'Comercializadora Andina'},
    farmerProfile: {'full_name': 'Hacienda La Fortuna'},
    offers: [sampleOffer],
  );

  final sampleNegotiationBuyerTurn = NegotiationModel(
    id: 'neg-integ-2',
    cropId: 'crop-integ-1',
    buyerId: 'buyer-integ-1',
    status: NegotiationStatus.contraofertada,
    currentResponder: 'buyer',
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    crop: sampleCrop,
    buyerProfile: {'full_name': 'Comercializadora Andina'},
    farmerProfile: {'full_name': 'Hacienda La Fortuna'},
    offers: [
      sampleOffer,
      NegotiationOfferModel(
        id: 'offer-integ-2',
        negotiationId: 'neg-integ-2',
        senderId: 'farmer-integ-1',
        quantityKg: 250.0,
        proposedPricePerKg: 17800.0,
        deliveryMethod: 'Recogida en finca',
        message: 'Acepto la cantidad pero el precio base es 17800.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
  );

  final sampleAgreedPurchase = NegotiationModel(
    id: 'neg-integ-3',
    cropId: 'crop-integ-1',
    buyerId: 'buyer-integ-1',
    status: NegotiationStatus.acordada,
    currentResponder: 'farmer',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    crop: sampleCrop,
    farmerProfile: {'full_name': 'Hacienda La Fortuna'},
    offers: [
      NegotiationOfferModel(
        id: 'offer-integ-3',
        negotiationId: 'neg-integ-3',
        senderId: 'farmer-integ-1',
        quantityKg: 500.0,
        proposedPricePerKg: 17500.0,
        deliveryMethod: 'Envío consolidado',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  );

  group('Etapa 7 — Integración: Navegación diferenciada por rol', () {
    testWidgets('Barra de navegación de Agricultor conserva estructura clásica (Mercado, Tratos, Costos, Mi Finca)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              role: 'agricultor',
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Costos'), findsOneWidget);
      expect(find.text('Mi Finca'), findsOneWidget);

      expect(find.text('Compras'), findsNothing);
      expect(find.text('Mi mercado'), findsNothing);
    });

    testWidgets('Barra de navegación de Comerciante/Comprador presenta estructura adaptada (Mi mercado, Tratos, Compras, Mi Finca)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              role: 'comprador',
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi mercado'), findsOneWidget);
      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Mi Finca'), findsOneWidget);

      expect(find.text('Costos'), findsNothing);
    });
  });

  group('Etapa 7 — Integración: Catálogo y flujo de negociación', () {
    testWidgets('Comprador en MarketplaceScreen no ve FAB de publicar y ve cosechas disponibles', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'comprador',
            initialCrops: [sampleCrop],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Cacao Fino de Aroma'), findsOneWidget);
      expect(find.text('Cacao'), findsOneWidget);
      expect(find.text('1.500 kg'), findsOneWidget);
    });

    testWidgets('Comprador en CropDetailScreen ve información del productor y botón Hacer oferta', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'comprador',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar Cosecha'), findsNothing);
      expect(find.text('Eliminar Cosecha'), findsNothing);
      expect(find.text('Hacer oferta / Negociar'), findsOneWidget);
    });

    testWidgets('MakeOfferSheet valida límites de pedido mínimo y stock disponible', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: MakeOfferSheet(crop: sampleCrop),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nueva Oferta'), findsOneWidget);
      expect(find.text('Cacao Fino de Aroma — Cacao'), findsOneWidget);
      expect(find.text('Enviar propuesta'), findsOneWidget);
    });
  });

  group('Etapa 7 — Integración: Dinámica de tratos y alternancia de turnos', () {
    testWidgets('Agricultor identifica comprador y su turno de respuesta', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealsScreen(
            role: 'agricultor',
            initialNegotiations: [sampleNegotiationFarmerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comprador: Comercializadora Andina'), findsOneWidget);
      expect(find.text('Tu turno'), findsOneWidget);
    });

    testWidgets('Comprador identifica productor y su turno de respuesta', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealsScreen(
            role: 'comprador',
            initialNegotiations: [sampleNegotiationBuyerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productor: Hacienda La Fortuna'), findsOneWidget);
      expect(find.text('Tu turno'), findsOneWidget);
    });

    testWidgets('DealDetailScreen muestra acciones según turno y rol participante', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealDetailScreen(
            negotiationId: 'neg-integ-2',
            role: 'comprador',
            initialNegotiation: sampleNegotiationBuyerTurn,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productor'), findsWidgets);
      expect(find.text('Hacienda La Fortuna'), findsOneWidget);
      expect(find.text('Aceptar oferta'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('deal_detail_more_actions_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Contraofertar'), findsOneWidget);
      expect(find.text('Rechazar trato'), findsOneWidget);
    });
  });

  group('Etapa 7 — Integración: Módulo Compras y Resiliencia', () {
    testWidgets('PurchasesScreen calcula métricas de acuerdos y enlaza con DealDetailScreen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: PurchasesScreen(
            initialPurchases: [sampleAgreedPurchase],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Acuerdos vigentes'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('500 kg'), findsWidgets);
      expect(find.text('Cacao Fino de Aroma'), findsOneWidget);
      expect(find.text('Hacienda La Fortuna'), findsOneWidget);
      expect(find.text('Acordada'), findsOneWidget);
      expect(find.text('Ver detalle del acuerdo →'), findsOneWidget);
    });

    testWidgets('Soporte completo de modo oscuro en todos los componentes integrados', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: PurchasesScreen(
            initialPurchases: [sampleAgreedPurchase],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Cacao Fino de Aroma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
