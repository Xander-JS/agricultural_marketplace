import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/utils/app_formatters.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/widgets/crop_card.dart';
import 'package:agricultural_marketplace/features/crop/widgets/unit_equivalences_sheet.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    DateFormatters.ensureInitialized();
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
    ThemeData? theme,
    Locale locale = const Locale('es', 'CO'),
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: locale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  final testCropWithHarvest = CropModel(
    id: 'crop-test-eq-01',
    farmerId: 'farmer-uuid-99',
    title: 'Papa Pastusa Especial',
    description: 'Papa seleccionada de primera calidad.',
    cropType: 'Papa',
    pricePerKg: 2800.0,
    stockTotal: 1000.0,
    stockCommitted: 100.0,
    stockSold: 100.0,
    minOrderKg: 50.0,
    department: 'Nariño',
    municipality: 'Pasto',
    isEarlySale: false,
    estimatedHarvestDate: DateTime(2026, 12, 15),
    status: CropStatus.activa,
    createdAt: DateTime(2026, 10, 10),
    updatedAt: DateTime(2026, 10, 11),
  );

  final testCropWithoutHarvest = CropModel(
    id: 'crop-test-eq-02',
    farmerId: 'farmer-uuid-99',
    title: 'Cebolla Junca de Ipiales',
    description: 'Cebolla fresca cosechada lista para entrega.',
    cropType: 'Cebolla',
    pricePerKg: 3200.0,
    stockTotal: 500.0,
    stockCommitted: 0.0,
    stockSold: 0.0,
    minOrderKg: 20.0,
    department: 'Nariño',
    municipality: 'Ipiales',
    isEarlySale: false,
    estimatedHarvestDate: null,
    status: CropStatus.activa,
    createdAt: DateTime(2026, 10, 5),
    updatedAt: DateTime(2026, 10, 6),
  );

  group('Fase 2 — Prompt 3: Lógica y Formateo de Equivalencias', () {
    test('1. Conversión matemática fiel con unidades tradicionales colombianas', () {
      // Bulto = 50 kg
      expect(UnitFormatters.formatEquivalence(50, TraditionalUnit.bulto), equals('≈ 1 bulto'));
      expect(UnitFormatters.formatEquivalence(100, TraditionalUnit.bulto), equals('≈ 2 bultos'));
      expect(UnitFormatters.formatEquivalence(75, TraditionalUnit.bulto), equals('≈ 1,5 bultos'));

      // Arroba = 12.5 kg
      expect(UnitFormatters.formatEquivalence(12.5, TraditionalUnit.arroba), equals('≈ 1 arroba'));
      expect(UnitFormatters.formatEquivalence(25, TraditionalUnit.arroba), equals('≈ 2 arrobas'));
      expect(UnitFormatters.formatEquivalence(50, TraditionalUnit.arroba), equals('≈ 4 arrobas'));

      // Canastilla = 25 kg
      expect(UnitFormatters.formatEquivalence(25, TraditionalUnit.canastilla), equals('≈ 1 canastilla'));
      expect(UnitFormatters.formatEquivalence(50, TraditionalUnit.canastilla), equals('≈ 2 canastillas'));

      // Caja = 20 kg
      expect(UnitFormatters.formatEquivalence(20, TraditionalUnit.caja), equals('≈ 1 caja'));
      expect(UnitFormatters.formatEquivalence(60, TraditionalUnit.caja), equals('≈ 3 cajas'));

      // Tonelada = 1000 kg
      expect(UnitFormatters.formatEquivalence(1000, TraditionalUnit.tonelada), equals('≈ 1 tonelada'));
      expect(UnitFormatters.formatEquivalence(2500, TraditionalUnit.tonelada), equals('≈ 2,5 toneladas'));
    });

    test('2. Manejo seguro de cantidades nulas, cero y negativas en equivalencias', () {
      expect(UnitFormatters.formatEquivalence(null, TraditionalUnit.bulto), isNull);
      expect(UnitFormatters.formatEquivalence(0, TraditionalUnit.bulto), isNull);
      expect(UnitFormatters.formatEquivalence(-50, TraditionalUnit.bulto), isNull);
      expect(UnitFormatters.formatBestTraditionalEquivalence(null), isNull);
      expect(UnitFormatters.formatBestTraditionalEquivalence(0), isNull);
    });

    test('3. No mutación del inventario ni stock del modelo CropModel', () {
      final initialStock = testCropWithHarvest.stockTotal;
      final initialAvailable = testCropWithHarvest.availableStock;

      final eq = UnitFormatters.formatKgWithEquivalence(testCropWithHarvest.stockTotal);
      expect(eq, contains('1.000 kg'));

      // Verificamos inmutabilidad estricta
      expect(testCropWithHarvest.stockTotal, equals(initialStock));
      expect(testCropWithHarvest.availableStock, equals(initialAvailable));
      expect(testCropWithHarvest.stockTotal, equals(1000.0));
      expect(testCropWithHarvest.availableStock, equals(800.0));
    });
  });

  group('Fase 2 — Prompt 3: Widget UnitEquivalencesSheet', () {
    testWidgets('4. UnitEquivalencesSheet presenta existencias de referencia y todas las unidades tradicionales', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const UnitEquivalencesSheet(
            referenceKg: 800.0,
            cropTitle: 'Papa Pastusa Especial',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Título y título del cultivo
      expect(find.text('Equivalencias de Unidades'), findsOneWidget);
      expect(find.text('Papa Pastusa Especial'), findsOneWidget);

      // Cantidad de referencia
      expect(find.text('800 kg'), findsWidgets);

      // Equivalencias calculadas:
      // 800 kg / 50 = 16 bultos
      expect(find.text('≈ 16 bultos'), findsOneWidget);
      // 800 kg / 12.5 = 64 arrobas
      expect(find.text('≈ 64 arrobas'), findsOneWidget);
      // 800 kg / 25 = 32 canastillas
      expect(find.text('≈ 32 canastillas'), findsOneWidget);
      // 800 kg / 20 = 40 cajas
      expect(find.text('≈ 40 cajas'), findsOneWidget);
      // 800 kg / 1000 = 0.8 toneladas
      expect(find.text('≈ 0,8 toneladas'), findsOneWidget);

      // Nota informativa de no mutación
      expect(
        find.text(
          'Conversiones aproximadas de carácter exclusivamente informativo. No modifican el inventario, los precios ni los pedidos.',
        ),
        findsOneWidget,
      );

      // Botón Entendido
      expect(find.byKey(const Key('crop_detail_equivalences_close_button')), findsOneWidget);
    });

    testWidgets('5. UnitEquivalencesSheet permite consultar otra cantidad interactivamente en memoria', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const UnitEquivalencesSheet(
            referenceKg: 100.0,
            cropTitle: 'Papa Pastusa',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('≈ 2 bultos'), findsOneWidget);

      // Ingresamos 250 kg en el calculador
      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, '250');
      await tester.pumpAndSettle();

      // 250 / 50 = 5 bultos
      expect(find.text('≈ 5 bultos'), findsOneWidget);
      // 250 / 12.5 = 20 arrobas
      expect(find.text('≈ 20 arrobas'), findsOneWidget);
      // 250 / 25 = 10 canastillas
      expect(find.text('≈ 10 canastillas'), findsOneWidget);
      // 250 / 1000 = 0.25 toneladas -> formateado con 1 decimal ≈ 0,3 o 0,25
      expect(find.textContaining('tonelada'), findsWidgets);
    });

    testWidgets('6. UnitEquivalencesSheet maneja cantidades cero, vacías o inválidas sin NaN ni excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const UnitEquivalencesSheet(
            referenceKg: 0.0,
            cropTitle: 'Cultivo Agotado',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 bultos'), findsOneWidget);
      expect(find.text('0 arrobas'), findsOneWidget);
      expect(find.text('0 canastillas'), findsOneWidget);
      expect(find.text('0 cajas'), findsOneWidget);
      expect(find.text('0 toneladas'), findsOneWidget);

      // Ingresamos texto inválido
      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, 'abc');
      await tester.pumpAndSettle();

      expect(find.text('0 bultos'), findsOneWidget);
    });
  });

  group('Fase 2 — Prompt 3: Visibilidad por Rol de Equivalencias en CropDetailScreen', () {
    testWidgets('7. Comprador ve botón "Ver equivalencias" y abre modal informativo', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: testCropWithHarvest,
            role: 'comprador',
            isOwner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El comprador ve el botón "Ver equivalencias"
      final eqButton = find.byKey(const Key('crop_detail_equivalences_button'));
      expect(eqButton, findsOneWidget);

      // Al pulsar el botón, se abre el modal bottom sheet de equivalencias
      await tester.tap(eqButton);
      await tester.pumpAndSettle();

      expect(find.byType(UnitEquivalencesSheet), findsOneWidget);
      expect(find.text('Equivalencias de Unidades'), findsOneWidget);

      // Al pulsar el icono de cierre, se cierra el modal
      final closeIcon = find.byIcon(Icons.close);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(find.byType(UnitEquivalencesSheet), findsNothing);
    });

    testWidgets('8. Agricultor NO ve botón "Ver equivalencias"', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: testCropWithHarvest,
            role: 'agricultor',
            isOwner: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El agricultor no debe ver la opción de equivalencias
      expect(find.byKey(const Key('crop_detail_equivalences_button')), findsNothing);
      expect(find.text('Ver equivalencias'), findsNothing);
    });

    testWidgets('9. Moderador NO ve botón "Ver equivalencias"', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: testCropWithHarvest,
            role: 'moderador',
            isOwner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crop_detail_equivalences_button')), findsNothing);
      expect(find.text('Ver equivalencias'), findsNothing);
    });
  });

  group('Fase 2 — Prompt 3: Diferenciación de Fechas', () {
    testWidgets('10. CropDetailScreen despliega Fecha de publicación y Fecha est. de cosecha de manera independiente', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: testCropWithHarvest,
            role: 'comprador',
            isOwner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fecha de publicación claramente identificada
      expect(find.text('Fecha de publicación'), findsOneWidget);
      // Formato medio en español de createdAt (10 oct 2026)
      expect(find.text('10 oct 2026'), findsOneWidget);

      // Fecha estimada de cosecha claramente identificada
      expect(find.text('Fecha est. de cosecha'), findsOneWidget);
      // Formato extendido de harvestDate (15 de diciembre, 2026)
      expect(find.text('15 de diciembre, 2026'), findsOneWidget);
    });

    testWidgets('11. CropDetailScreen omite Fecha est. de cosecha cuando esta es nula', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: testCropWithoutHarvest,
            role: 'comprador',
            isOwner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fecha de publicación debe estar presente
      expect(find.text('Fecha de publicación'), findsOneWidget);
      expect(find.text('05 oct 2026'), findsOneWidget);

      // Fecha estimada de cosecha NO debe estar presente
      expect(find.text('Fecha est. de cosecha'), findsNothing);
    });

    testWidgets('12. CropCard en catálogo muestra existencias y precio sin confundir fechas', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropCard(
            crop: testCropWithHarvest,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica que no haya confusión en la tarjeta
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('1.000 kg'), findsOneWidget);
      expect(find.text(r'$ 2.800'), findsOneWidget);
      // La tarjeta no confunde ni muestra fechas erróneas
      expect(find.text('15 de diciembre, 2026'), findsNothing);
    });

    testWidgets('13. Soporte de modo oscuro y localización en inglés sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          theme: AppTheme.darkTheme,
          locale: const Locale('en'),
          child: CropDetailScreen(
            crop: testCropWithHarvest,
            role: 'buyer',
            isOwner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publication date'), findsOneWidget);
      expect(find.text('View equivalences'), findsOneWidget);

      // Abrir modal en inglés y tema oscuro
      await tester.tap(find.byKey(const Key('crop_detail_equivalences_button')));
      await tester.pumpAndSettle();

      expect(find.text('Unit Equivalences'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
