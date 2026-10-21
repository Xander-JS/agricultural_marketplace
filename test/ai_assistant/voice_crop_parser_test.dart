import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:agricultural_marketplace/features/ai_assistant/models/voice_crop_draft.dart';
import 'package:agricultural_marketplace/features/ai_assistant/services/voice_crop_parser.dart';

void main() {
  group('VoiceCropParser — extracción estructurada', () {
    test('1. Extrae los cuatro datos cuando la transcripción los contiene', () {
      final draft = VoiceCropParser.parse(
        jsonEncode({
          'cropType': 'Papa',
          'quantity': 100,
          'unit': 'bulto',
          'priceValue': 2000,
          'priceUnit': 'kg',
          'notes': null,
        }),
        transcript: 'Tengo 100 bultos de papa a 2000 pesos el kilo',
      );

      expect(draft.cropType, equals('Papa'));
      expect(draft.quantity, equals(100));
      expect(draft.unit, isNotNull);
      expect(draft.unit!.label, equals('bulto'));
      expect(draft.quantityKg, equals(5000));
      expect(draft.pricePerKg, equals(2000));
      expect(draft.missingFields, isEmpty);
      expect(draft.identifiedFields, contains(VoiceCropField.cropType));
      expect(draft.identifiedFields, contains(VoiceCropField.pricePerKg));
      expect(draft.reviewFields, contains(VoiceCropField.quantity));
      expect(draft.hasAnyUsableData, isTrue);
    });

    test('2. Transcripción incompleta deja los datos ausentes pendientes', () {
      final draft = VoiceCropParser.parse(
        jsonEncode({
          'cropType': 'Café',
          'quantity': null,
          'unit': null,
          'priceValue': null,
          'priceUnit': null,
        }),
        transcript: 'Quiero vender café',
      );

      expect(draft.cropType, equals('Café'));
      expect(draft.quantity, isNull);
      expect(draft.quantityKg, isNull);
      expect(draft.pricePerKg, isNull);
      expect(draft.missingFields, contains(VoiceCropField.quantity));
      expect(draft.missingFields, contains(VoiceCropField.unit));
      expect(draft.missingFields, contains(VoiceCropField.pricePerKg));
      expect(draft.missingFields, isNot(contains(VoiceCropField.cropType)));
      expect(draft.hasAnyUsableData, isTrue);
    });

    test(
      '3. Cantidad o precio inválidos se rechazan y generan advertencia',
      () {
        final draft = VoiceCropParser.parse(
          jsonEncode({
            'cropType': 'Papa',
            'quantity': -5,
            'unit': 'kg',
            'priceValue': 0,
            'priceUnit': 'kg',
          }),
          transcript: 'Tengo menos cinco kilos de papa a cero pesos',
        );

        expect(draft.quantity, isNull);
        expect(draft.quantityKg, isNull);
        expect(draft.pricePerKg, isNull);
        expect(draft.warnings, isNotEmpty);
        expect(draft.warnings.join(' '), contains('mayor que cero'));
        expect(draft.missingFields, contains(VoiceCropField.quantity));
        expect(draft.missingFields, contains(VoiceCropField.pricePerKg));
      },
    );

    test('4. Unidad desconocida o ambigua no se convierte silenciosamente', () {
      final draft = VoiceCropParser.parse(
        jsonEncode({
          'cropType': 'Papa',
          'quantity': 10,
          'unit': 'costal',
          'priceValue': 50000,
          'priceUnit': 'costal',
        }),
        transcript: 'Tengo 10 costales de papa a 50000 pesos el costal',
      );

      expect(draft.quantity, equals(10));
      expect(draft.unit, isNull);
      expect(draft.quantityKg, isNull);
      expect(draft.pricePerKg, isNull);
      expect(draft.missingFields, contains(VoiceCropField.quantity));
      expect(draft.missingFields, contains(VoiceCropField.unit));
      expect(draft.missingFields, contains(VoiceCropField.pricePerKg));
      expect(draft.warnings.join(' '), contains('no se reconoce'));
    });

    test('5. Precio sin unidad explícita queda pendiente y advierte', () {
      final draft = VoiceCropParser.parse(
        jsonEncode({
          'cropType': 'Papa',
          'quantity': 10,
          'unit': 'kg',
          'priceValue': 5000,
          'priceUnit': null,
        }),
        transcript: 'Tengo 10 kilos de papa a 5000 pesos',
      );

      expect(draft.pricePerKg, isNull);
      expect(draft.warnings.join(' '), contains('No se indicó'));
      expect(draft.missingFields, contains(VoiceCropField.pricePerKg));
    });

    test('6. JSON inválido o incompleto produce un error comprensible', () {
      expect(
        () => VoiceCropParser.parse(
          '{"cropType": "Papa"',
          transcript: 'Tengo papa',
        ),
        throwsA(
          isA<VoiceCropParseException>().having(
            (error) => error.message,
            'message',
            contains('Intenta de nuevo'),
          ),
        ),
      );

      expect(
        () => VoiceCropParser.parse(
          'No pude interpretar esto',
          transcript: 'Tengo papa',
        ),
        throwsA(isA<VoiceCropParseException>()),
      );
    });

    test('7. Precio por bulto se convierte y se marca para confirmación', () {
      final draft = VoiceCropParser.parse(
        jsonEncode({
          'cropType': 'Papa',
          'quantity': 2,
          'unit': 'bulto',
          'priceValue': 100000,
          'priceUnit': 'bulto',
        }),
        transcript: 'Dos bultos de papa a 100000 pesos el bulto',
      );

      expect(draft.quantityKg, equals(100));
      expect(draft.pricePerKg, equals(2000));
      expect(draft.reviewFields, contains(VoiceCropField.quantity));
      expect(draft.reviewFields, contains(VoiceCropField.pricePerKg));
      expect(draft.warnings.join(' '), contains('Confírmalo'));
    });

    test('8. Normaliza kilos y acepta precio por kg directo como respaldo', () {
      final draft = VoiceCropParser.parse(
        jsonEncode({
          'cropType': 'Cebolla',
          'quantity': 12.5,
          'unit': 'kilos',
          'pricePerKg': 3200,
        }),
        transcript: 'Doce kilos y medio de cebolla a 3200 el kilo',
      );

      expect(draft.unit, VoiceCropUnit.kilogram);
      expect(draft.quantityKg, equals(12.5));
      expect(draft.pricePerKg, equals(3200));
      expect(draft.reviewFields, contains(VoiceCropField.pricePerKg));
      expect(draft.warnings.join(' '), contains('Confírmalo'));
    });

    test('9. Respuesta vacía produce un borrador sin datos utilizables', () {
      final draft = VoiceCropParser.parse(
        '{}',
        transcript: 'No se entendió nada',
      );

      expect(draft.hasAnyUsableData, isFalse);
      expect(draft.missingFields.length, equals(4));
    });
  });
}
