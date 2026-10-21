import 'package:flutter_test/flutter_test.dart';

import 'package:agricultural_marketplace/features/costs/models/crop_cost_model.dart';
import 'package:agricultural_marketplace/features/costs/services/crop_cost_calculator.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';

CropModel buildCrop({
  String id = 'crop-1',
  String title = 'Tomate Chonto',
  double stockTotal = 1000,
  double stockCommitted = 100,
  double stockSold = 200,
  double? estimatedYieldKg,
  bool isEarlySale = false,
}) {
  return CropModel(
    id: id,
    farmerId: 'farmer-1',
    title: title,
    description: 'Cultivo de prueba',
    cropType: 'Tomate',
    pricePerKg: 3000,
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
  String id = 'cost-1',
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
  group('Total de costos', () {
    test('1. suma correctamente varios costos', () {
      final total = CropCostCalculator.totalOf([
        buildCost(id: 'a', amount: 1000),
        buildCost(id: 'b', amount: 2500.50),
        buildCost(id: 'c', amount: 499.50),
      ]);

      expect(total, closeTo(4000, 0.000001));
    });

    test('2. una lista vacía produce total cero', () {
      expect(CropCostCalculator.totalOf(const []), 0);
    });

    test('3. aísla los costos de cultivos diferentes', () {
      final costs = [
        buildCost(id: 'a', cropId: 'crop-1', amount: 100),
        buildCost(id: 'b', cropId: 'crop-2', amount: 900),
        buildCost(id: 'c', cropId: 'crop-1', amount: 250),
      ];

      expect(CropCostCalculator.totalForCrop(costs, 'crop-1'), 350);
      expect(CropCostCalculator.totalForCrop(costs, 'crop-2'), 900);
    });

    test('4. el total se actualiza al cambiar la colección de costos', () {
      final initial = [buildCost(id: 'a', amount: 1000)];
      expect(CropCostCalculator.totalOf(initial), 1000);

      final updated = [...initial, buildCost(id: 'b', amount: 750)];
      expect(CropCostCalculator.totalOf(updated), 1750);

      final edited = [
        buildCost(id: 'a', amount: 1200),
        buildCost(id: 'b', amount: 750),
      ];
      expect(CropCostCalculator.totalOf(edited), 1950);
    });

    test('5. no cuenta dos veces un registro con el mismo identificador', () {
      final duplicated = buildCost(id: 'same-id', amount: 500);

      expect(
        CropCostCalculator.totalForCrop([duplicated, duplicated], 'crop-1'),
        500,
      );
    });

    test('6. rechaza importes no finitos o negativos al sumar', () {
      expect(
        () => CropCostCalculator.totalFromAmounts([1000, double.infinity]),
        throwsFormatException,
      );
      expect(
        () => CropCostCalculator.totalFromAmounts([1000, double.nan]),
        throwsFormatException,
      );
      expect(
        () => CropCostCalculator.totalFromAmounts([1000, -1]),
        throwsFormatException,
      );
    });
  });

  group('Costo por kilogramo', () {
    test('7. cosecha regular usa stock_total como denominador', () {
      final crop = buildCrop(
        stockTotal: 1000,
        stockCommitted: 800,
        stockSold: 100,
        estimatedYieldKg: 50,
        isEarlySale: false,
      );

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 5000,
      );

      expect(result.status, CropCostPerKgStatus.calculated);
      expect(result.costPerKg, closeTo(5, 0.000001));
      expect(result.denominator, 1000);
      expect(result.denominatorSource, CropCostDenominatorSource.stockTotal);
      expect(result.denominatorSource.fieldName, 'stock_total');
    });

    test('8. venta anticipada usa estimated_yield_kg como denominador', () {
      final crop = buildCrop(
        stockTotal: 1000,
        estimatedYieldKg: 500,
        isEarlySale: true,
      );

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 5000,
      );

      expect(result.status, CropCostPerKgStatus.calculated);
      expect(result.costPerKg, closeTo(10, 0.000001));
      expect(result.denominator, 500);
      expect(
        result.denominatorSource,
        CropCostDenominatorSource.estimatedYieldKg,
      );
      expect(result.denominatorSource.fieldName, 'estimated_yield_kg');
    });

    test('9. venta anticipada sin rendimiento queda pendiente y no usa stock_total', () {
      final crop = buildCrop(
        stockTotal: 1000,
        estimatedYieldKg: null,
        isEarlySale: true,
      );

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 5000,
      );

      expect(result.status, CropCostPerKgStatus.estimatedYieldPending);
      expect(result.costPerKg, isNull);
      expect(result.denominator, isNull);
      expect(
        result.denominatorSource,
        CropCostDenominatorSource.estimatedYieldKg,
      );
    });

    test('10. denominador igual a cero no se calcula', () {
      final crop = buildCrop(stockTotal: 0, isEarlySale: false);

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 1000,
      );

      expect(result.status, CropCostPerKgStatus.invalidDenominator);
      expect(result.costPerKg, isNull);
      expect(result.denominator, 0);
    });

    test('11. denominador negativo no se calcula', () {
      final crop = buildCrop(stockTotal: -10, isEarlySale: false);

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 1000,
      );

      expect(result.status, CropCostPerKgStatus.invalidDenominator);
      expect(result.costPerKg, isNull);
      expect(result.denominator, -10);
    });

    test('12. denominador no finito no se calcula', () {
      final infiniteCrop = buildCrop(
        stockTotal: double.infinity,
        isEarlySale: false,
      );
      final infiniteResult = CropCostCalculator.calculatePerKg(
        crop: infiniteCrop,
        totalCost: 1000,
      );

      expect(infiniteResult.status, CropCostPerKgStatus.invalidDenominator);
      expect(infiniteResult.costPerKg, isNull);
      expect(infiniteResult.denominator, isNull);

      final nanCrop = buildCrop(
        stockTotal: 1000,
        estimatedYieldKg: double.nan,
        isEarlySale: true,
      );
      final nanResult = CropCostCalculator.calculatePerKg(
        crop: nanCrop,
        totalCost: 1000,
      );

      expect(nanResult.status, CropCostPerKgStatus.invalidDenominator);
      expect(nanResult.costPerKg, isNull);
      expect(nanResult.denominator, isNull);
    });

    test('13. cultivo sin costos muestra estado sin costos', () {
      final crop = buildCrop(stockTotal: 1000);

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 0,
      );

      expect(result.status, CropCostPerKgStatus.noCosts);
      expect(result.costPerKg, isNull);
      expect(result.denominator, 1000);
      expect(result.message, CropCostCalculator.noCostsMessage);
    });

    test('14. costos positivos con denominador inválido no producen un valor ficticio', () {
      final crop = buildCrop(stockTotal: 0);

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 1500,
      );

      expect(result.status, CropCostPerKgStatus.invalidDenominator);
      expect(result.costPerKg, isNull);
      expect(result.message, contains('denominador'));
    });

    test('15. no usa existencias disponibles, comprometidas ni vendidas', () {
      final crop = buildCrop(
        stockTotal: 1000,
        stockCommitted: 700,
        stockSold: 200,
        isEarlySale: false,
      );

      expect(crop.availableStock, 100);

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: 1000,
      );

      expect(result.denominator, 1000);
      expect(result.costPerKg, closeTo(1, 0.000001));
    });

    test('un total de costos inválido se informa de forma explícita', () {
      final crop = buildCrop(stockTotal: 1000);

      final result = CropCostCalculator.calculatePerKg(
        crop: crop,
        totalCost: double.infinity,
      );

      expect(result.status, CropCostPerKgStatus.invalidCostTotal);
      expect(result.costPerKg, isNull);
    });
  });

  group('Validación del importe', () {
    test('acepta importes numéricos positivos y formatos colombianos', () {
      expect(CropCostCalculator.parseAmount('1500'), 1500);
      expect(CropCostCalculator.parseAmount('1500.50'), 1500.50);
      expect(CropCostCalculator.parseAmount('1.500,50'), 1500.50);
      expect(CropCostCalculator.parseAmount('1,500.50'), 1500.50);
      expect(CropCostCalculator.parseAmount('1.500'), 1500);
      expect(CropCostCalculator.parseAmount('1,5'), 1.5);
    });

    test('rechaza vacío, cero, negativos, no finitos y texto inválido', () {
      expect(CropCostCalculator.parseAmount(null), isNull);
      expect(CropCostCalculator.parseAmount(''), isNull);
      expect(CropCostCalculator.parseAmount('   '), isNull);
      expect(CropCostCalculator.parseAmount('0'), isNull);
      expect(CropCostCalculator.parseAmount('0.00'), isNull);
      expect(CropCostCalculator.parseAmount('-1500'), isNull);
      expect(CropCostCalculator.parseAmount('Infinity'), isNull);
      expect(CropCostCalculator.parseAmount('NaN'), isNull);
      expect(CropCostCalculator.parseAmount('1e309'), isNull);
      expect(CropCostCalculator.parseAmount('abc'), isNull);
      expect(CropCostCalculator.parseAmount('1,2,3'), isNull);
    });
  });
}
