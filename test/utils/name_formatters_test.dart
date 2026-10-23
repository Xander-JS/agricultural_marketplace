import 'package:flutter_test/flutter_test.dart';

import 'package:agricultural_marketplace/core/utils/name_formatters.dart';

void main() {
  group('NameFormatters.firstNameAndSurname', () {
    test('dos nombres y dos apellidos: primer nombre y primer apellido', () {
      expect(
        NameFormatters.firstNameAndSurname('Juan Carlos Pérez Gómez'),
        'Juan Pérez',
      );
    });

    test('un nombre y dos apellidos', () {
      expect(
        NameFormatters.firstNameAndSurname('Jaime Pérez Gómez'),
        'Jaime Pérez',
      );
    });

    test('conserva partículas unidas al nombre o apellido siguiente', () {
      expect(
        NameFormatters.firstNameAndSurname(
          'María de los Ángeles Rosero Pantoja',
        ),
        'María Rosero',
      );
      expect(
        NameFormatters.firstNameAndSurname('Ana Lucía de la Cruz Erazo'),
        'Ana de la Cruz',
      );
    });

    test('los tratamientos de cortesía acompañan al nombre', () {
      expect(
        NameFormatters.firstNameAndSurname('Don Jaime Cafetero'),
        'Don Jaime Cafetero',
      );
    });

    test('nombres de una o dos partes se devuelven completos', () {
      expect(NameFormatters.firstNameAndSurname('Rosa'), 'Rosa');
      expect(
        NameFormatters.firstNameAndSurname('Andrés Mercader'),
        'Andrés Mercader',
      );
    });

    test('normaliza espacios y tolera valores vacíos', () {
      expect(
        NameFormatters.firstNameAndSurname('  Luis   Alberto  Bravo  Ortiz '),
        'Luis Bravo',
      );
      expect(NameFormatters.firstNameAndSurname(null), '');
      expect(NameFormatters.firstNameAndSurname('   '), '');
    });
  });
}
