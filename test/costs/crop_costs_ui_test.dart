import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/costs/data/simulated_regional_price_references.dart';
import 'package:agricultural_marketplace/features/costs/models/crop_cost_model.dart';
import 'package:agricultural_marketplace/features/costs/screens/costs_screen.dart';
import 'package:agricultural_marketplace/features/costs/screens/crop_costs_detail_screen.dart';
import 'package:agricultural_marketplace/features/costs/screens/crop_profitability_screen.dart';
import 'package:agricultural_marketplace/features/costs/services/crop_cost_calculator.dart';
import 'package:agricultural_marketplace/features/costs/services/crop_cost_service.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/publish_crop_screen.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';

class FakeCropCostService extends CropCostService {
  FakeCropCostService({Map<String, List<CropCostModel>>? costs})
    : _costs = costs ?? <String, List<CropCostModel>>{};

  final Map<String, List<CropCostModel>> _costs;
  bool failLoad = false;
  bool failCreate = false;
  bool failUpdate = false;
  bool failDelete = false;
  int loadCalls = 0;
  int _nextId = 1;

  List<CropCostModel> costsFor(String cropId) =>
      List<CropCostModel>.from(_costs[cropId] ?? const []);

  void seed(String cropId, List<CropCostModel> costs) {
    _costs[cropId] = List<CropCostModel>.from(costs);
  }

  @override
  Future<List<CropCostModel>> getCostsByCropId(String cropId) async {
    loadCalls++;
    if (failLoad) throw Exception('LOAD_ERROR');
    return costsFor(cropId);
  }

  @override
  Future<double> getTotalCostByCropId(String cropId) async {
    loadCalls++;
    if (failLoad) throw Exception('LOAD_ERROR');
    return CropCostCalculator.totalOf(_costs[cropId] ?? const []);
  }

  @override
  Future<CropCostModel> createCost(CropCostModel cost) async {
    if (failCreate) throw Exception('CREATE_ERROR');
    final created = CropCostModel(
      id: cost.id.isEmpty ? 'generated-${_nextId++}' : cost.id,
      cropId: cost.cropId,
      category: cost.category,
      description: cost.description,
      amount: cost.amount,
      createdAt: cost.createdAt,
    );
    _costs.putIfAbsent(created.cropId, () => []).insert(0, created);
    return created;
  }

  @override
  Future<CropCostModel> updateCost(CropCostModel cost) async {
    if (failUpdate) throw Exception('UPDATE_ERROR');
    final list = _costs[cost.cropId] ?? <CropCostModel>[];
    final index = list.indexWhere((item) => item.id == cost.id);
    if (index >= 0) {
      list[index] = cost;
    }
    return cost;
  }

  @override
  Future<void> deleteCost(String costId) async {
    if (failDelete) throw Exception('DELETE_ERROR');
    for (final list in _costs.values) {
      list.removeWhere((cost) => cost.id == costId);
    }
  }
}

class FakeCropServiceForCosts extends CropService {
  FakeCropServiceForCosts(this.crops);

  final List<CropModel> crops;
  int saveCalls = 0;

  @override
  Future<List<CropModel>> getCropsByFarmerId(String farmerId) async => crops;

  @override
  String getPublicImageUrl(String imagePath) => imagePath;

  @override
  Future<CropModel> saveCrop(
    CropModel crop, {
    List<File>? newImages,
    List<String>? removedImages,
  }) async {
    saveCalls++;
    return crop;
  }
}

CropModel buildCrop({
  String id = 'crop-1',
  String title = 'Tomate Chonto',
  String cropType = 'Tomate',
  double pricePerKg = 3000,
  double stockTotal = 1000,
  double stockCommitted = 0,
  double stockSold = 0,
  double? estimatedYieldKg,
  bool isEarlySale = false,
}) {
  return CropModel(
    id: id,
    farmerId: 'farmer-1',
    title: title,
    description: 'Cultivo de prueba',
    cropType: cropType,
    pricePerKg: pricePerKg,
    stockTotal: stockTotal,
    stockCommitted: stockCommitted,
    stockSold: stockSold,
    minOrderKg: 1,
    estimatedYieldKg: estimatedYieldKg,
    department: 'Cundinamarca',
    municipality: 'Fusagasugá',
    isEarlySale: isEarlySale,
    status: CropStatus.activa,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

CropCostModel buildCost({
  required String id,
  String cropId = 'crop-1',
  double amount = 1000,
  CostCategory category = CostCategory.jornales,
  String description = 'Mano de obra',
}) {
  return CropCostModel(
    id: id,
    cropId: cropId,
    category: category,
    description: description,
    amount: amount,
    createdAt: DateTime(2026, 1, 1),
  );
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
      darkTheme: AppTheme.darkTheme,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  String totalText(WidgetTester tester) {
    return tester.widget<Text>(find.byKey(const Key('crop_cost_total'))).data ??
        '';
  }

  String textOfKey(WidgetTester tester, String key) {
    return tester.widget<Text>(find.byKey(Key(key))).data ?? '';
  }

  CropCostPerKgResult calculatedCostResult({double costPerKg = 8000}) {
    return CropCostPerKgResult(
      status: CropCostPerKgStatus.calculated,
      costPerKg: costPerKg,
      denominator: 1,
      denominatorSource: CropCostDenominatorSource.stockTotal,
      message: 'Costo estimado por kg',
    );
  }

  group('Pantalla de costos del cultivo', () {
    testWidgets('16. presenta el total y el costo por kg de cosecha regular', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [
            buildCost(id: 'a', amount: 1000, description: 'Mano de obra'),
            buildCost(
              id: 'b',
              amount: 2500,
              category: CostCategory.fertilizantes,
              description: 'Fertilizante',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crop_cost_crop_title')), findsOneWidget);
      expect(find.text('Tomate Chonto'), findsWidgets);
      expect(totalText(tester), r'$ 3.500');
      expect(find.text(r'$ 3,50 / kg'), findsOneWidget);
      expect(
        find.textContaining('Cantidad usada: 1.000 kg (stock total)'),
        findsOneWidget,
      );
      expect(find.text('Jornales'), findsOneWidget);
      expect(find.text('Fertilizantes'), findsOneWidget);
      expect(find.text('Mano de obra'), findsOneWidget);
      expect(find.text('Fertilizante'), findsOneWidget);
    });

    testWidgets('17. presenta el costo por kg de una venta anticipada', (
      tester,
    ) async {
      final crop = buildCrop(
        stockTotal: 1000,
        estimatedYieldKg: 400,
        isEarlySale: true,
      );
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 2000)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$ 5 / kg'), findsOneWidget);
      expect(
        find.textContaining('Cantidad usada: 400 kg (rendimiento estimado)'),
        findsOneWidget,
      );
      expect(find.textContaining('Campo: estimated_yield_kg'), findsOneWidget);
    });

    testWidgets('18. informa un denominador inválido sin inventar un valor', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 0);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crop_cost_per_kg_value')), findsNothing);
      expect(find.byKey(const Key('crop_cost_per_kg_message')), findsOneWidget);
      expect(find.textContaining('denominador no es válida'), findsOneWidget);
      expect(
        find.textContaining('Cantidad usada: 0 kg (stock total)'),
        findsOneWidget,
      );
    });

    testWidgets('19. venta anticipada sin rendimiento no usa stock_total', (
      tester,
    ) async {
      final crop = buildCrop(
        stockTotal: 1000,
        estimatedYieldKg: null,
        isEarlySale: true,
      );
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'la venta anticipada no tiene rendimiento estimado',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Cantidad usada: No disponible (rendimiento estimado)',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('1.000 kg'), findsNothing);
    });

    testWidgets('20. cultivo sin costos muestra un estado explícito', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService();

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(totalText(tester), r'$ 0');
      expect(
        find.textContaining('Aún no hay costos registrados'),
        findsWidgets,
      );
      expect(
        find.textContaining('Cantidad usada: 1.000 kg (stock total)'),
        findsOneWidget,
      );
    });

    testWidgets('21. distingue un error de carga de una lista vacía', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService()..failLoad = true;

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ocurrió un error'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(
        find.textContaining('Aún no hay costos registrados'),
        findsNothing,
      );

      service.failLoad = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ocurrió un error'), findsNothing);
      expect(
        find.textContaining('Aún no hay costos registrados'),
        findsWidgets,
      );
    });

    testWidgets('22. actualiza el total y el costo por kg al agregar', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar costo'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar Costo'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Fertilizante adicional');
      await tester.enterText(fields.at(1), '500');
      await tester.ensureVisible(find.text('Guardar costo'));
      await tester.tap(find.text('Guardar costo'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar Costo'), findsNothing);
      expect(totalText(tester), r'$ 1.500');
      expect(find.text(r'$ 1,50 / kg'), findsOneWidget);
      expect(find.text('Fertilizante adicional'), findsOneWidget);
    });

    testWidgets('23. actualiza el total y el costo por kg al editar', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Costo'), findsOneWidget);
      final amountField = find.byType(TextFormField).at(1);
      expect(
        tester.widget<TextFormField>(amountField).controller?.text,
        '1000',
      );

      await tester.enterText(amountField, '2500');
      await tester.ensureVisible(find.text('Actualizar costo'));
      await tester.tap(find.text('Actualizar costo'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Costo'), findsNothing);
      expect(totalText(tester), r'$ 2.500');
      expect(find.text(r'$ 2,50 / kg'), findsOneWidget);
    });

    testWidgets('24. actualiza el total y el costo por kg al eliminar', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [
            buildCost(id: 'a', amount: 1000, description: 'Mano de obra'),
            buildCost(
              id: 'b',
              amount: 500,
              category: CostCategory.transporte,
              description: 'Flete',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(totalText(tester), r'$ 500');
      expect(find.text(r'$ 0,50 / kg'), findsOneWidget);
      expect(find.text('Mano de obra'), findsNothing);
      expect(find.text('Flete'), findsOneWidget);
    });

    testWidgets('25. un fallo al guardar no altera el total', (tester) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService()..failCreate = true;

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar costo'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Costo fallido');
      await tester.enterText(fields.at(1), '900');
      await tester.ensureVisible(find.text('Guardar costo'));
      await tester.tap(find.text('Guardar costo'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar Costo'), findsOneWidget);
      expect(find.textContaining('Error al guardar'), findsOneWidget);
      expect(service.costsFor('crop-1'), isEmpty);
    });

    testWidgets('26. un fallo al editar conserva el importe original', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      )..failUpdate = true;

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      final amountField = find.byType(TextFormField).at(1);
      await tester.enterText(amountField, '2500');
      await tester.ensureVisible(find.text('Actualizar costo'));
      await tester.tap(find.text('Actualizar costo'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Costo'), findsOneWidget);
      expect(find.textContaining('Error al guardar'), findsOneWidget);
      expect(service.costsFor('crop-1').single.amount, 1000);
    });

    testWidgets('27. un fallo al eliminar conserva el registro y el total', (
      tester,
    ) async {
      final crop = buildCrop(stockTotal: 1000);
      final service = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      )..failDelete = true;

      await tester.pumpWidget(
        createTestWidget(
          CropCostsDetailScreen(crop: crop, costService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error al eliminar'), findsOneWidget);
      expect(totalText(tester), r'$ 1.000');
      expect(service.costsFor('crop-1'), hasLength(1));
    });
  });

  group('Índice de costos y reactividad', () {
    testWidgets('28. muestra totales y costo por kg por cultivo', (
      tester,
    ) async {
      final crop1 = buildCrop(id: 'crop-1', title: 'Tomate Chonto');
      final crop2 = buildCrop(
        id: 'crop-2',
        title: 'Papa Pastusa',
        cropType: 'Papa',
        stockTotal: 2000,
      );
      final cropService = FakeCropServiceForCosts([crop1, crop2]);
      final costService = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', cropId: 'crop-1', amount: 1000)],
          'crop-2': [buildCost(id: 'b', cropId: 'crop-2', amount: 500)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CostsScreen(
            cropService: cropService,
            costService: costService,
            currentUserIdForTesting: 'farmer-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Costos'), findsOneWidget);
      expect(find.text('Tomate Chonto'), findsOneWidget);
      expect(find.text('Papa Pastusa'), findsOneWidget);
      expect(find.text(r'Costo por kg: $ 1 / kg'), findsOneWidget);
      expect(find.text(r'Costo por kg: $ 0,25 / kg'), findsOneWidget);
      expect(find.text('Ver costos'), findsNWidgets(2));
      expect(find.textContaining('1.000 kg · stock total'), findsOneWidget);
      expect(find.textContaining('2.000 kg · stock total'), findsOneWidget);
    });

    testWidgets('29. recarga el índice después de modificar un costo', (
      tester,
    ) async {
      final crop = buildCrop(id: 'crop-1', title: 'Tomate Chonto');
      final cropService = FakeCropServiceForCosts([crop]);
      final costService = FakeCropCostService(
        costs: {
          'crop-1': [buildCost(id: 'a', amount: 1000)],
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          CostsScreen(
            cropService: cropService,
            costService: costService,
            currentUserIdForTesting: 'farmer-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'Costo por kg: $ 1 / kg'), findsOneWidget);

      await tester.tap(find.text('Ver costos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar costo'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Costo adicional');
      await tester.enterText(fields.at(1), '500');
      await tester.ensureVisible(find.text('Guardar costo'));
      await tester.tap(find.text('Guardar costo'));
      await tester.pumpAndSettle();

      final detailContext = tester.element(find.byType(CropCostsDetailScreen));
      Navigator.of(detailContext).pop();
      await tester.pumpAndSettle();

      expect(find.text('Costos'), findsOneWidget);
      expect(find.text(r'$ 1.500'), findsOneWidget);
      expect(find.text(r'Costo por kg: $ 1,50 / kg'), findsOneWidget);
    });

    testWidgets('30. distingue un error de carga de una lista sin cultivos', (
      tester,
    ) async {
      final cropService = FakeCropServiceForCosts([buildCrop()]);
      final costService = FakeCropCostService()..failLoad = true;

      await tester.pumpWidget(
        createTestWidget(
          CostsScreen(
            cropService: cropService,
            costService: costService,
            currentUserIdForTesting: 'farmer-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ocurrió un error'), findsOneWidget);
      expect(find.text('Primero debes crear una cosecha'), findsNothing);

      costService.failLoad = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ocurrió un error'), findsNothing);
      expect(find.text('Tomate Chonto'), findsOneWidget);
    });
  });

  testWidgets('31. el comprador no ve información de costos', (tester) async {
    await tester.pumpWidget(
      createTestWidget(const MainDashboardScreen(role: 'comprador')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CostsScreen, skipOffstage: false), findsNothing);
    expect(find.text('Costos'), findsNothing);
    expect(find.textContaining('Total de costos'), findsNothing);
    expect(find.textContaining('Costo estimado por kg'), findsNothing);
  });

  testWidgets('32. el flujo de edición de cultivos sigue disponible', (
    tester,
  ) async {
    final crop = buildCrop(
      id: 'crop-edit-1',
      title: 'Café existente',
      cropType: 'Café',
    );
    final cropService = FakeCropServiceForCosts([crop]);

    await tester.pumpWidget(
      createTestWidget(
        PublishCropScreen(
          cropToEdit: crop,
          cropService: cropService,
          currentUserIdForTesting: 'farmer-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar Cosecha'), findsOneWidget);
    final titleField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(titleField.controller?.text, 'Café existente');
  });

  group('Margen y precio sugerido', () {
    testWidgets(
      '33. carga el costo por kg de la Fase 3.2 y abre rentabilidad',
      (tester) async {
        final crop = buildCrop(stockTotal: 1, pricePerKg: 10000);
        final costService = FakeCropCostService(
          costs: {
            'crop-1': [buildCost(id: 'a', amount: 8000)],
          },
        );

        await tester.pumpWidget(
          createTestWidget(
            CropCostsDetailScreen(crop: crop, costService: costService),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(r'$ 8.000 / kg'), findsOneWidget);

        await tester.tap(find.byKey(const Key('crop_profitability_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CropProfitabilityScreen), findsOneWidget);
        expect(textOfKey(tester, 'profit_cost_per_kg'), r'$ 8.000 / kg');
        expect(textOfKey(tester, 'profit_current_price'), r'$ 10.000 / kg');
        expect(textOfKey(tester, 'profit_margin_value'), '20 %');
        expect(textOfKey(tester, 'profit_suggested_price'), r'$ 9.411,76 / kg');
      },
    );

    testWidgets(
      '34. actualiza reactivamente el precio sugerido al cambiar el margen',
      (tester) async {
        final crop = buildCrop(pricePerKg: 10000);
        await tester.pumpWidget(
          createTestWidget(
            CropProfitabilityScreen(
              crop: crop,
              costPerKgResult: calculatedCostResult(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(textOfKey(tester, 'profit_suggested_price'), r'$ 9.411,76 / kg');

        final targetField = find.byKey(const Key('profit_target_margin_field'));
        await tester.ensureVisible(targetField);
        await tester.enterText(targetField, '20');
        await tester.pump();

        expect(textOfKey(tester, 'profit_suggested_price'), r'$ 10.000 / kg');

        await tester.enterText(targetField, '0');
        await tester.pump();

        expect(textOfKey(tester, 'profit_suggested_price'), r'$ 8.000 / kg');

        await tester.enterText(targetField, '100');
        await tester.pump();

        expect(
          find.byKey(const Key('profit_target_margin_error')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('profit_suggested_price')), findsNothing);
      },
    );

    testWidgets('35. evalúa un precio temporal, ganancia, pérdida y alerta', (
      tester,
    ) async {
      final crop = buildCrop(pricePerKg: 10000);
      await tester.pumpWidget(
        createTestWidget(
          CropProfitabilityScreen(
            crop: crop,
            costPerKgResult: calculatedCostResult(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(textOfKey(tester, 'profit_margin_value'), '20 %');
      expect(textOfKey(tester, 'profit_amount_value'), r'$ 2.000 / kg');

      final priceField = find.byKey(const Key('profit_selling_price_field'));
      await tester.ensureVisible(priceField);
      await tester.enterText(priceField, '9000');
      await tester.pump();

      expect(textOfKey(tester, 'profit_margin_value'), '11,11 %');
      expect(textOfKey(tester, 'profit_amount_value'), r'$ 1.000 / kg');
      expect(
        find.byKey(const Key('profit_low_margin_warning')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profit_temporary_price_note')),
        findsOneWidget,
      );

      await tester.enterText(priceField, '7000');
      await tester.pump();

      expect(textOfKey(tester, 'profit_margin_value'), '-14,29 %');
      expect(textOfKey(tester, 'profit_amount_value'), r'-$ 1.000 / kg');
      expect(find.byKey(const Key('profit_loss_message')), findsOneWidget);
      expect(find.byKey(const Key('profit_low_margin_warning')), findsNothing);
    });

    testWidgets(
      '36. consultar la recomendación no modifica el precio publicado',
      (tester) async {
        final crop = buildCrop(stockTotal: 1, pricePerKg: 10000);
        final cropService = FakeCropServiceForCosts([crop]);
        final costService = FakeCropCostService(
          costs: {
            'crop-1': [buildCost(id: 'a', amount: 8000)],
          },
        );

        await tester.pumpWidget(
          createTestWidget(
            CropCostsDetailScreen(
              crop: crop,
              cropService: cropService,
              costService: costService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('crop_profitability_button')));
        await tester.pumpAndSettle();

        final priceField = find.byKey(const Key('profit_selling_price_field'));
        final targetField = find.byKey(const Key('profit_target_margin_field'));
        await tester.ensureVisible(priceField);
        await tester.enterText(priceField, '12000');
        await tester.ensureVisible(targetField);
        await tester.enterText(targetField, '20');
        await tester.pump();

        final profitabilityContext = tester.element(
          find.byType(CropProfitabilityScreen),
        );
        Navigator.of(profitabilityContext).pop();
        await tester.pumpAndSettle();

        expect(find.byType(CropProfitabilityScreen), findsNothing);
        expect(crop.pricePerKg, 10000);
        expect(cropService.saveCalls, 0);
      },
    );

    testWidgets(
      '37. el comprador no ve costos, margen ni referencias privadas',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(const MainDashboardScreen(role: 'comprador')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(CropProfitabilityScreen, skipOffstage: false),
          findsNothing,
        );
        expect(find.textContaining('Margen sobre el precio'), findsNothing);
        expect(find.textContaining('Ganancia estimada'), findsNothing);
        expect(find.textContaining('Precio sugerido'), findsNothing);
        expect(
          find.byKey(
            const Key('simulated_reference_notice'),
            skipOffstage: false,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      '38. muestra que no hay referencia para un cultivo sin configurar',
      (tester) async {
        final crop = buildCrop(
          title: 'Quinua',
          cropType: 'Quinua',
          pricePerKg: 10000,
        );

        await tester.pumpWidget(
          createTestWidget(
            CropProfitabilityScreen(
              crop: crop,
              costPerKgResult: calculatedCostResult(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(SimulatedRegionalPriceReferences.notice),
          findsNothing,
        );
        expect(
          find.byKey(const Key('simulated_reference_missing')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('simulated_reference_price')),
          findsNothing,
        );
      },
    );

    testWidgets('39. sin costo por kg no inventa margen ni precio sugerido', (
      tester,
    ) async {
      final crop = buildCrop(pricePerKg: 10000);
      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 0,
      );

      await tester.pumpWidget(
        createTestWidget(
          CropProfitabilityScreen(crop: crop, costPerKgResult: result),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profit_cost_unavailable_message')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'No se puede calcular el margen ni el precio sugerido',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profit_margin_value')), findsNothing);
      expect(find.byKey(const Key('profit_suggested_price')), findsNothing);
      expect(
        find.byKey(const Key('simulated_reference_notice')),
        findsNothing,
      );
    });

    testWidgets('40. compara el precio evaluado con la referencia simulada', (
      tester,
    ) async {
      final crop = buildCrop(
        title: 'Tomate Chonto',
        cropType: 'Tomate',
        pricePerKg: 10000,
      );

      await tester.pumpWidget(
        createTestWidget(
          CropProfitabilityScreen(
            crop: crop,
            costPerKgResult: calculatedCostResult(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(SimulatedRegionalPriceReferences.notice),
        findsNothing,
      );
      expect(textOfKey(tester, 'simulated_reference_price'), r'$ 3.200 / kg');
      expect(
        textOfKey(tester, 'simulated_reference_difference'),
        r'$ 6.800 / kg',
      );
      expect(find.text('PROYECCIÓN IA'), findsOneWidget);
      expect(find.text('Proyección de mercado KUS AI'), findsOneWidget);
      expect(find.textContaining('Fuente:'), findsNothing);
    });

    testWidgets(
      '41. permite un precio temporal si el precio actual no es válido',
      (tester) async {
        final crop = buildCrop(pricePerKg: 0);

        await tester.pumpWidget(
          createTestWidget(
            CropProfitabilityScreen(
              crop: crop,
              costPerKgResult: calculatedCostResult(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(textOfKey(tester, 'profit_current_price'), 'No disponible');
        final priceField = find.byKey(const Key('profit_selling_price_field'));
        expect(
          tester.widget<TextFormField>(priceField).controller?.text,
          isEmpty,
        );

        await tester.ensureVisible(priceField);
        await tester.enterText(priceField, '10000');
        await tester.pump();

        expect(textOfKey(tester, 'profit_margin_value'), '20 %');
        expect(textOfKey(tester, 'profit_amount_value'), r'$ 2.000 / kg');
        expect(
          find.byKey(const Key('profit_temporary_price_note')),
          findsOneWidget,
        );
      },
    );
  });
}
