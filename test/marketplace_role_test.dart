import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/crop/widgets/make_offer_sheet.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';

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
    id: 'crop-123',
    farmerId: 'farmer-456',
    title: 'Aguacate Hass de Exportación',
    description: 'Aguacate Hass de excelente calidad cultivado en Sonsón.',
    cropType: 'Aguacate',
    pricePerKg: 4500.0,
    stockTotal: 1000.0,
    stockCommitted: 100.0,
    stockSold: 50.0,
    minOrderKg: 100.0,
    department: 'Antioquia',
    municipality: 'Sonsón',
    status: CropStatus.activa,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleFarmerProfile = FarmerProfileData(
    id: 'farmer-456',
    fullName: 'Don Carlos Restrepo',
    role: 'agricultor',
    email: 'carlos@finca.co',
    phone: '+57 300 123 4567',
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: true,
      shareLocation: true,
      shareWhatsapp: true,
    ),
    stats: FarmerStatsData(
      published: 3,
      negotiating: 1,
      closed: 5,
    ),
  );

  group('Etapa 4 — MarketplaceScreen por Rol', () {
    testWidgets('Comprador ve título "Mercado", NO ve botón flotante "Publicar" y ve cosechas', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'comprador',
            initialCrops: [sampleCrop],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el título del comprador
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Mi Mercado'), findsNothing);

      // NO debe tener el FloatingActionButton de publicar
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Publicar'), findsNothing);

      // Debe mostrar la cosecha
      expect(find.text('Aguacate Hass de Exportación'), findsOneWidget);
      expect(find.text('Aguacate'), findsOneWidget);
    });

    testWidgets('Comerciante es sinónimo de comprador en MarketplaceScreen', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'comerciante',
            initialCrops: [sampleCrop],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Variantes buyer, mayúsculas y espacios no muestran accidentalmente interfaz de agricultor', (tester) async {
      final buyerVariants = ['buyer', ' BUYER ', '  comprador  ', '  Comerciante  '];
      for (final variant in buyerVariants) {
        await tester.pumpWidget(
          createTestWidget(
            child: MarketplaceScreen(
              role: variant,
              initialCrops: [sampleCrop],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mercado'), findsOneWidget, reason: 'Falló para variante: "$variant"');
        expect(find.text('Mi Mercado'), findsNothing, reason: 'Mostró Mi Mercado para variante: "$variant"');
        expect(find.byType(FloatingActionButton), findsNothing, reason: 'Mostró FAB para variante: "$variant"');
        expect(find.text('Publicar'), findsNothing, reason: 'Mostró Publicar para variante: "$variant"');
      }
    });

    testWidgets('Agricultor ve título "Mi Mercado" y SÍ ve botón flotante "Publicar"', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: MarketplaceScreen(
            role: 'agricultor',
            initialCrops: [sampleCrop],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el título del agricultor
      expect(find.text('Mi Mercado'), findsOneWidget);

      // SÍ debe mostrar el FloatingActionButton
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Publicar'), findsOneWidget);
    });

    testWidgets('Comprador con lista vacía ve estado vacío con botón Actualizar y sin Publicar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MarketplaceScreen(
            role: 'comprador',
            initialCrops: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay cosechas disponibles'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
      expect(find.text('Publicar mi primera cosecha'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Agricultor con lista vacía ve estado vacío para crear su primera publicación', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const MarketplaceScreen(
            role: 'agricultor',
            initialCrops: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes cosechas publicadas'), findsOneWidget);
      expect(find.text('Publicar mi primera cosecha'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('MarketplaceScreen soporta modo oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: MarketplaceScreen(
            role: 'comprador',
            initialCrops: [sampleCrop],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Aguacate Hass de Exportación'), findsOneWidget);
    });
  });

  group('Etapa 4 — CropDetailScreen por Rol', () {
    testWidgets('Comprador en CropDetailScreen NO ve botones Editar/Borrar y ve "Hacer oferta / Negociar"', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Título
      expect(find.text('Detalle de Cosecha'), findsOneWidget);

      // NO debe tener acciones de edición o borrado
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);

      // NO debe tener acciones de pausar cultivo
      expect(find.text('Pausar Publicación'), findsNothing);
      expect(find.text('Ver Negociaciones'), findsNothing);

      // SÍ debe mostrar el botón para hacer oferta / negociar
      expect(find.text('Hacer oferta / Negociar'), findsOneWidget);

      // SÍ debe mostrar la tarjeta con la información del productor
      expect(find.text('Información del Productor'), findsOneWidget);
      expect(find.text('Don Carlos Restrepo'), findsOneWidget);
      expect(find.text('+57 300 123 4567'), findsOneWidget);
    });

    testWidgets('Agricultor dueño en CropDetailScreen ve botones Editar/Borrar y Pausar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'agricultor',
            isOwner: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SÍ debe tener acciones de edición y borrado
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // SÍ debe tener acción para pausar
      expect(find.text('Pausar Publicación'), findsOneWidget);
      expect(find.text('Ver Negociaciones'), findsOneWidget);

      // NO debe tener botón de hacer oferta
      expect(find.text('Hacer oferta / Negociar'), findsNothing);
    });

    testWidgets('CropDetailScreen soporta modo oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aguacate Hass de Exportación'), findsOneWidget);
      expect(find.text('Hacer oferta / Negociar'), findsOneWidget);
    });
  });

  group('Etapa 4 — MakeOfferSheet Validación y Términos', () {
    testWidgets('MakeOfferSheet inicializa con pedido mínimo y precio base y calcula subtotal', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: MakeOfferSheet(crop: sampleCrop),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Título
      expect(find.text('Nueva Oferta'), findsOneWidget);
      expect(find.text('Aguacate Hass de Exportación — Aguacate'), findsOneWidget);

      // Campos inicializados con stock y pedido mínimo
      expect(find.text('100'), findsOneWidget); // minOrderKg = 100
      expect(find.text('4500'), findsOneWidget); // pricePerKg = 4500

      // Subtotal estimado inicial: 100 * 4500 = 450000 -> $ 450.000
      expect(find.text(r'$ 450.000'), findsOneWidget);

      // Opciones de método de entrega presentes
      expect(find.text('En finca'), findsOneWidget);
    });

    testWidgets('MakeOfferSheet valida pedido mínimo menor al requerido', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: MakeOfferSheet(crop: sampleCrop),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ingresar cantidad menor al pedido mínimo (50 < 100)
      final qtyFinder = find.widgetWithText(TextFormField, 'Cantidad (kg)');
      await tester.enterText(qtyFinder, '50');
      await tester.pumpAndSettle();

      // Tocar Enviar propuesta
      await tester.tap(find.text('Enviar propuesta'));
      await tester.pumpAndSettle();

      // Debe mostrar error de validación de pedido mínimo
      expect(find.text('La cantidad no cumple con el pedido mínimo'), findsOneWidget);
    });

    testWidgets('MakeOfferSheet valida cantidad mayor al stock disponible', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: MakeOfferSheet(crop: sampleCrop),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ingresar cantidad mayor al stock disponible (1500 > 1000)
      final qtyFinder = find.widgetWithText(TextFormField, 'Cantidad (kg)');
      await tester.enterText(qtyFinder, '1500');
      await tester.pumpAndSettle();

      // Tocar Enviar propuesta
      await tester.tap(find.text('Enviar propuesta'));
      await tester.pumpAndSettle();

      // Debe mostrar error de validación de stock
      expect(find.text('La cantidad supera el stock disponible'), findsOneWidget);
    });
  });
}
