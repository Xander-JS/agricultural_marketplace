import 'package:flutter_test/flutter_test.dart';

import 'package:agricultural_marketplace/features/costs/services/profit_margin_calculator.dart';

void main() {
  group('Margen sobre el precio de venta', () {
    test(
      '1. costo 8.000 y precio 10.000 producen margen 20 % y ganancia 2.000',
      () {
        final result = ProfitMarginCalculator.calculateMargin(
          costPerKg: 8000,
          sellingPricePerKg: 10000,
        );

        expect(result.status, ProfitMarginStatus.calculated);
        expect(result.profitPerKg, closeTo(2000, 0.000001));
        expect(result.marginPercentage, closeTo(20, 0.000001));
        expect(result.isLoss, isFalse);
      },
    );

    test('2. precio inferior al costo produce pérdida y margen negativo', () {
      final result = ProfitMarginCalculator.calculateMargin(
        costPerKg: 8000,
        sellingPricePerKg: 7000,
      );

      expect(result.status, ProfitMarginStatus.calculated);
      expect(result.profitPerKg, closeTo(-1000, 0.000001));
      expect(result.marginPercentage, closeTo(-14.285714, 0.000001));
      expect(result.isLoss, isTrue);
    });

    test('3. precio igual al costo produce margen 0 %', () {
      final result = ProfitMarginCalculator.calculateMargin(
        costPerKg: 8000,
        sellingPricePerKg: 8000,
      );

      expect(result.status, ProfitMarginStatus.calculated);
      expect(result.profitPerKg, 0);
      expect(result.marginPercentage, 0);
      expect(result.isLoss, isFalse);
    });

    test('4. precio de venta igual a cero no es válido', () {
      final result = ProfitMarginCalculator.calculateMargin(
        costPerKg: 8000,
        sellingPricePerKg: 0,
      );

      expect(result.status, ProfitMarginStatus.invalidSellingPrice);
      expect(result.marginPercentage, isNull);
      expect(result.profitPerKg, isNull);
    });

    test('5. costo negativo o no finito no se calcula', () {
      final negative = ProfitMarginCalculator.calculateMargin(
        costPerKg: -1,
        sellingPricePerKg: 10000,
      );
      final infinite = ProfitMarginCalculator.calculateMargin(
        costPerKg: double.infinity,
        sellingPricePerKg: 10000,
      );
      final nan = ProfitMarginCalculator.calculateMargin(
        costPerKg: double.nan,
        sellingPricePerKg: 10000,
      );

      expect(negative.status, ProfitMarginStatus.invalidCost);
      expect(infinite.status, ProfitMarginStatus.invalidCost);
      expect(nan.status, ProfitMarginStatus.invalidCost);
      expect(negative.marginPercentage, isNull);
      expect(infinite.marginPercentage, isNull);
      expect(nan.marginPercentage, isNull);
    });

    test('6. precio no finito no se calcula', () {
      final infinite = ProfitMarginCalculator.calculateMargin(
        costPerKg: 8000,
        sellingPricePerKg: double.infinity,
      );
      final nan = ProfitMarginCalculator.calculateMargin(
        costPerKg: 8000,
        sellingPricePerKg: double.nan,
      );

      expect(infinite.status, ProfitMarginStatus.invalidSellingPrice);
      expect(nan.status, ProfitMarginStatus.invalidSellingPrice);
    });

    test('7. costo no disponible devuelve un estado explícito', () {
      final result = ProfitMarginCalculator.calculateMargin(
        costPerKg: null,
        sellingPricePerKg: 10000,
      );

      expect(result.status, ProfitMarginStatus.costUnavailable);
      expect(result.marginPercentage, isNull);
      expect(result.profitPerKg, isNull);
    });

    test('un costo cero es válido para el margen matemático', () {
      final result = ProfitMarginCalculator.calculateMargin(
        costPerKg: 0,
        sellingPricePerKg: 10000,
      );

      expect(result.status, ProfitMarginStatus.calculated);
      expect(result.profitPerKg, 10000);
      expect(result.marginPercentage, 100);
    });
  });

  group('Precio sugerido por margen objetivo', () {
    test('8. costo 8.000 con margen 15 % produce 9.411,76 aproximadamente', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 8000,
        targetMarginPercentage: 15,
      );

      expect(result.status, SuggestedPriceStatus.calculated);
      expect(result.suggestedPricePerKg, closeTo(9411.764705882353, 0.000001));
      expect(result.message, contains('margen objetivo'));
    });

    test('9. margen objetivo de 0 % deja el precio igual al costo', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 8000,
        targetMarginPercentage: 0,
      );

      expect(result.status, SuggestedPriceStatus.calculated);
      expect(result.suggestedPricePerKg, closeTo(8000, 0.000001));
    });

    test('10. margen objetivo negativo no es válido', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 8000,
        targetMarginPercentage: -1,
      );

      expect(result.status, SuggestedPriceStatus.invalidTargetMargin);
      expect(result.suggestedPricePerKg, isNull);
    });

    test('11. margen objetivo de 100 % no produce precio', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 8000,
        targetMarginPercentage: 100,
      );

      expect(result.status, SuggestedPriceStatus.invalidTargetMargin);
      expect(result.suggestedPricePerKg, isNull);
    });

    test('12. margen objetivo superior a 100 % no produce precio', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 8000,
        targetMarginPercentage: 120,
      );

      expect(result.status, SuggestedPriceStatus.invalidTargetMargin);
      expect(result.suggestedPricePerKg, isNull);
    });

    test('13. costo no disponible no produce precio sugerido', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: null,
        targetMarginPercentage: 15,
      );

      expect(result.status, SuggestedPriceStatus.costUnavailable);
      expect(result.suggestedPricePerKg, isNull);
    });

    test('14. costo igual a cero no produce recomendación engañosa', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 0,
        targetMarginPercentage: 15,
      );

      expect(result.status, SuggestedPriceStatus.invalidCost);
      expect(result.suggestedPricePerKg, isNull);
    });

    test('costo no finito no produce precio sugerido', () {
      final infinite = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: double.infinity,
        targetMarginPercentage: 15,
      );
      final nan = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: double.nan,
        targetMarginPercentage: 15,
      );

      expect(infinite.status, SuggestedPriceStatus.invalidCost);
      expect(nan.status, SuggestedPriceStatus.invalidCost);
    });

    test('margen objetivo ausente no produce precio sugerido', () {
      final result = ProfitMarginCalculator.calculateSuggestedPrice(
        costPerKg: 8000,
        targetMarginPercentage: null,
      );

      expect(result.status, SuggestedPriceStatus.invalidTargetMargin);
      expect(result.suggestedPricePerKg, isNull);
    });

    test('parsea márgenes válidos y rechaza valores fuera de rango', () {
      expect(ProfitMarginCalculator.parseMarginPercentage('15'), 15);
      expect(ProfitMarginCalculator.parseMarginPercentage('0'), 0);
      expect(ProfitMarginCalculator.parseMarginPercentage('15,5'), 15.5);
      expect(ProfitMarginCalculator.parseMarginPercentage('15.5'), 15.5);
      expect(ProfitMarginCalculator.parseMarginPercentage('100'), isNull);
      expect(ProfitMarginCalculator.parseMarginPercentage('120'), isNull);
      expect(ProfitMarginCalculator.parseMarginPercentage('-1'), isNull);
      expect(ProfitMarginCalculator.parseMarginPercentage(''), isNull);
      expect(ProfitMarginCalculator.parseMarginPercentage('abc'), isNull);
    });
  });

  group('Comparación con referencia', () {
    test('17. compara correctamente dos precios', () {
      final above = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: 10000,
        referencePricePerKg: 9000,
      );
      final below = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: 8000,
        referencePricePerKg: 9000,
      );

      expect(above.status, PriceComparisonStatus.calculated);
      expect(above.differencePerKg, 1000);
      expect(above.percentageDifference, closeTo(11.111111, 0.000001));
      expect(above.isAboveReference, isTrue);

      expect(below.status, PriceComparisonStatus.calculated);
      expect(below.differencePerKg, -1000);
      expect(below.percentageDifference, closeTo(-11.111111, 0.000001));
      expect(below.isAboveReference, isFalse);
    });

    test('maneja un precio evaluado faltante o inválido', () {
      final missing = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: null,
        referencePricePerKg: 9000,
      );
      final zero = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: 0,
        referencePricePerKg: 9000,
      );
      final infinite = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: double.infinity,
        referencePricePerKg: 9000,
      );

      expect(missing.status, PriceComparisonStatus.invalidEvaluatedPrice);
      expect(zero.status, PriceComparisonStatus.invalidEvaluatedPrice);
      expect(infinite.status, PriceComparisonStatus.invalidEvaluatedPrice);
      expect(missing.differencePerKg, isNull);
    });

    test('maneja una referencia inválida sin inventar diferencias', () {
      final zero = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: 10000,
        referencePricePerKg: 0,
      );
      final nan = ProfitMarginCalculator.compareToReference(
        evaluatedPricePerKg: 10000,
        referencePricePerKg: double.nan,
      );

      expect(zero.status, PriceComparisonStatus.invalidReferencePrice);
      expect(nan.status, PriceComparisonStatus.invalidReferencePrice);
      expect(zero.differencePerKg, isNull);
      expect(nan.differencePerKg, isNull);
    });
  });
}
