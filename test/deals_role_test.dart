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
import 'package:agricultural_marketplace/features/deals/screens/counter_offer_screen.dart';
import 'package:agricultural_marketplace/features/deals/screens/deal_detail_screen.dart';
import 'package:agricultural_marketplace/features/deals/screens/deals_screen.dart';

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
    id: 'crop-100',
    farmerId: 'farmer-001',
    title: 'Café Especial Castillo',
    description: 'Café de altura con notas florales y frutales.',
    cropType: 'Café',
    pricePerKg: 15000.0,
    stockTotal: 500.0,
    department: 'Huila',
    municipality: 'Pitalito',
    status: CropStatus.activa,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleOffer = NegotiationOfferModel(
    id: 'offer-1',
    negotiationId: 'neg-1',
    senderId: 'buyer-001',
    quantityKg: 200.0,
    proposedPricePerKg: 14500.0,
    deliveryMethod: 'En finca',
    message: 'Recojo directamente en el beneficio.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final negotiationFarmerTurn = NegotiationModel(
    id: 'neg-1',
    cropId: 'crop-100',
    buyerId: 'buyer-001',
    status: NegotiationStatus.propuesta,
    currentResponder: 'farmer',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    crop: sampleCrop,
    buyerProfile: {'full_name': 'Andrés Mercader'},
    farmerProfile: {'full_name': 'Don Jaime Cafetero'},
    offers: [sampleOffer],
  );

  final negotiationBuyerTurn = NegotiationModel(
    id: 'neg-2',
    cropId: 'crop-100',
    buyerId: 'buyer-001',
    status: NegotiationStatus.contraofertada,
    currentResponder: 'buyer',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    crop: sampleCrop,
    buyerProfile: {'full_name': 'Andrés Mercader'},
    farmerProfile: {'full_name': 'Don Jaime Cafetero'},
    offers: [
      sampleOffer,
      NegotiationOfferModel(
        id: 'offer-2',
        negotiationId: 'neg-2',
        senderId: 'farmer-001',
        quantityKg: 200.0,
        proposedPricePerKg: 14800.0,
        deliveryMethod: 'Punto de acopio',
        message: 'Puedo dejártelo en el acopio municipal.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  );

  group('Etapa 5 — DealsScreen por Rol y Turnos', () {
    testWidgets('Agricultor ve "Comprador: Andrés Mercader" y "Tu turno" cuando responder es farmer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealsScreen(
            role: 'agricultor',
            initialNegotiations: [negotiationFarmerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Café Especial Castillo'), findsOneWidget);
      expect(find.text('Comprador: Andrés Mercader'), findsOneWidget);
      expect(find.text('Tu turno'), findsOneWidget);
      expect(find.text('Esperando respuesta'), findsNothing);
    });

    testWidgets('Agricultor ve "Esperando respuesta" cuando responder es buyer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealsScreen(
            role: 'agricultor',
            initialNegotiations: [negotiationBuyerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comprador: Andrés Mercader'), findsOneWidget);
      expect(find.text('Esperando respuesta'), findsOneWidget);
      expect(find.text('Tu turno'), findsNothing);
    });

    testWidgets('Comprador ve "Productor: Don Jaime Cafetero" y "Tu turno" cuando responder es buyer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealsScreen(
            role: 'comprador',
            initialNegotiations: [negotiationBuyerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Café Especial Castillo'), findsOneWidget);
      expect(find.text('Productor: Don Jaime Cafetero'), findsOneWidget);
      expect(find.text('Tu turno'), findsOneWidget);
      expect(find.text('Esperando respuesta'), findsNothing);
    });

    testWidgets('Comprador ve "Esperando respuesta" cuando responder es farmer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealsScreen(
            role: 'comprador',
            initialNegotiations: [negotiationFarmerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productor: Don Jaime Cafetero'), findsOneWidget);
      expect(find.text('Esperando respuesta'), findsOneWidget);
      expect(find.text('Tu turno'), findsNothing);
    });

    testWidgets('Comprador con lista vacía ve estado vacío adaptado y botón "Explorar mercado"', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const DealsScreen(
            role: 'comprador',
            initialNegotiations: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes tratos'), findsWidgets);
      expect(find.text('Explorar mercado'), findsOneWidget);
      expect(find.text('Ver mis cosechas'), findsNothing);
    });

    testWidgets('Agricultor con lista vacía ve estado vacío adaptado y botón "Ver mis cosechas"', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const DealsScreen(
            role: 'agricultor',
            initialNegotiations: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes tratos'), findsWidgets);
      expect(find.text('Ver mis cosechas'), findsOneWidget);
      expect(find.text('Explorar mercado'), findsNothing);
    });

    testWidgets('DealsScreen soporta modo oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: DealsScreen(
            role: 'comprador',
            initialNegotiations: [negotiationBuyerTurn],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Café Especial Castillo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Etapa 5 — DealDetailScreen por Rol y Respuestas', () {
    testWidgets('Agricultor en su turno ve acciones de Aceptar, Contraofertar y Rechazar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealDetailScreen(
            negotiationId: 'neg-1',
            role: 'agricultor',
            initialNegotiation: negotiationFarmerTurn,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Contraparte
      expect(find.text('Comprador'), findsWidgets);
      expect(find.text('Andrés Mercader'), findsOneWidget);

      // Botones de acción disponibles porque es su turno
      expect(find.text('Aceptar oferta'), findsOneWidget);
      expect(find.text('Contraofertar'), findsOneWidget);
      expect(find.text('Rechazar trato'), findsOneWidget);
    });

    testWidgets('Comprador en su turno ve acciones de Aceptar, Contraofertar y Rechazar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealDetailScreen(
            negotiationId: 'neg-2',
            role: 'comprador',
            initialNegotiation: negotiationBuyerTurn,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Contraparte
      expect(find.text('Productor'), findsWidgets);
      expect(find.text('Don Jaime Cafetero'), findsOneWidget);

      // Botones de acción disponibles para el comprador
      expect(find.text('Aceptar oferta'), findsOneWidget);
      expect(find.text('Contraofertar'), findsOneWidget);
      expect(find.text('Rechazar trato'), findsOneWidget);
    });

    testWidgets('Comprador esperando respuesta del productor ve banner informativo', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: DealDetailScreen(
            negotiationId: 'neg-1',
            role: 'comprador',
            initialNegotiation: negotiationFarmerTurn,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No debe ver botones de responder
      expect(find.text('Aceptar oferta'), findsNothing);
      expect(find.text('Contraofertar'), findsNothing);

      // Debe ver aviso de espera del productor
      expect(find.text('Esperando respuesta del productor'), findsOneWidget);
      expect(find.text('Cancelar propuesta'), findsOneWidget);
    });

    testWidgets('DealDetailScreen soporta modo oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: DealDetailScreen(
            negotiationId: 'neg-2',
            role: 'comprador',
            initialNegotiation: negotiationBuyerTurn,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detalle del trato'), findsOneWidget);
      expect(find.text('Don Jaime Cafetero'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Etapa 5 — CounterOfferScreen', () {
    testWidgets('CounterOfferScreen inicializa con datos de la última oferta y calcula subtotal', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CounterOfferScreen(
            negotiation: negotiationBuyerTurn,
            latestOffer: negotiationBuyerTurn.offers!.last,
            role: 'comprador',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contraoferta'), findsOneWidget);
      // Cantidad inicial 200, precio 14800 -> total 2960000
      expect(find.text('200'), findsOneWidget);
      expect(find.text('14800'), findsOneWidget);
      expect(find.text('\$ 2960000'), findsOneWidget);

      expect(find.text('Enviar contraoferta'), findsOneWidget);
    });
  });
}
