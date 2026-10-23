import 'package:flutter_test/flutter_test.dart';

import 'package:agricultural_marketplace/features/costs/data/simulated_regional_price_references.dart';

void main() {
  group('Referencias regionales simuladas', () {
    test('15. encuentra una referencia configurada para un cultivo', () {
      final reference = SimulatedRegionalPriceReferences.findForCrop(
        cropType: 'Tomate',
        title: 'Tomate Chonto',
      );

      expect(reference, isNotNull);
      expect(reference!.cropName, 'Tomate');
      expect(reference.region, 'Nariño, Colombia');
      expect(reference.referencePricePerKg, greaterThan(0));
      expect(reference.isSimulated, isTrue);
    });

    test('16. no inventa una referencia para un cultivo sin configuración', () {
      final reference = SimulatedRegionalPriceReferences.findForCrop(
        cropType: 'Quinua',
        title: 'Quinua',
      );

      expect(reference, isNull);
    });

    test('18. la referencia se identifica como índice regional proyectado', () {
      expect(
        SimulatedRegionalPriceReferences.notice,
        contains('Índice de referencia regional (Nariño)'),
      );
      expect(
        SimulatedRegionalPriceReferences.notice,
        contains('Proyección de mercado KUS AI'),
      );
      expect(
        SimulatedRegionalPriceReferences.notice.toLowerCase(),
        isNot(contains('simulad')),
      );

      for (final reference in SimulatedRegionalPriceReferences.all) {
        expect(reference.isSimulated, isTrue);
        expect(reference.region, contains('Nariño'));
        expect(reference.referencePricePerKg, greaterThan(0));
        expect(reference.aliases, isNotEmpty);
      }
    });

    test('19. no reutiliza la referencia de otro cultivo', () {
      final pastusa = SimulatedRegionalPriceReferences.findForCrop(
        cropType: 'Papa',
        title: 'Papa Pastusa',
      );
      final criolla = SimulatedRegionalPriceReferences.findForCrop(
        cropType: 'Papa',
        title: 'Papa Criolla',
      );
      final unknown = SimulatedRegionalPriceReferences.findForCrop(
        cropType: 'Papa',
        title: 'Papa Amarilla',
      );

      expect(pastusa?.cropName, 'Papa Pastusa');
      expect(criolla?.cropName, 'Papa Criolla');
      expect(unknown, isNull);
    });

    test('el conjunto no atribuye fuentes o fechas de observación reales', () {
      expect(
        SimulatedRegionalPriceReferences.notice,
        isNot(contains('Fuente:')),
      );
      expect(
        SimulatedRegionalPriceReferences.notice,
        isNot(contains('fecha de observación')),
      );
      expect(SimulatedRegionalPriceReferences.all, isNotEmpty);
    });
  });
}
