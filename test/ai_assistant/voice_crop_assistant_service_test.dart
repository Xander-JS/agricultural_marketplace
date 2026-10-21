import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agricultural_marketplace/features/ai_assistant/services/voice_crop_assistant_service.dart';

void main() {
  group('OpenAiCropExtractionService — sin llamadas reales', () {
    test('1. Clave de IA ausente produce un error de configuración', () async {
      final service = OpenAiCropExtractionService(apiKey: '');

      expect(service.isConfigured, isFalse);
      await expectLater(
        service.extract('Tengo 10 bultos de papa a 2000 el kilo'),
        throwsA(
          isA<AiConfigurationException>().having(
            (error) => error.message,
            'message',
            contains('AI_API_KEY'),
          ),
        ),
      );
    });

    test(
      '2. Error HTTP del proveedor se comunica sin exponer la clave',
      () async {
        final client = MockClient((request) async {
          return http.Response('{"error":"provider failure"}', 500);
        });
        final service = OpenAiCropExtractionService(
          apiKey: 'test-placeholder-key',
          client: client,
        );

        await expectLater(
          service.extract('Tengo papa'),
          throwsA(
            isA<AiProviderException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('código 500'),
                isNot(contains('test-placeholder-key')),
              ),
            ),
          ),
        );
      },
    );

    test('3. Error de conexión se comunica de forma comprensible', () async {
      final client = MockClient((request) async {
        throw http.ClientException('network unavailable');
      });
      final service = OpenAiCropExtractionService(
        apiKey: 'test-placeholder-key',
        client: client,
      );

      await expectLater(
        service.extract('Tengo papa'),
        throwsA(
          isA<AiProviderException>().having(
            (error) => error.message,
            'message',
            contains('No se pudo conectar'),
          ),
        ),
      );
    });

    test(
      '4. Respuesta inválida del proveedor produce un error comprensible',
      () async {
        final client = MockClient((request) async {
          return http.Response('esto no es JSON', 200);
        });
        final service = OpenAiCropExtractionService(
          apiKey: 'test-placeholder-key',
          client: client,
        );

        await expectLater(
          service.extract('Tengo papa'),
          throwsA(
            isA<AiProviderException>().having(
              (error) => error.message,
              'message',
              contains('respuesta inválida'),
            ),
          ),
        );
      },
    );

    test(
      '5. Respuesta incompleta del proveedor produce un error comprensible',
      () async {
        final client = MockClient((request) async {
          return http.Response('{"choices":[]}', 200);
        });
        final service = OpenAiCropExtractionService(
          apiKey: 'test-placeholder-key',
          client: client,
        );

        await expectLater(
          service.extract('Tengo papa'),
          throwsA(
            isA<AiProviderException>().having(
              (error) => error.message,
              'message',
              contains('vacía o incompleta'),
            ),
          ),
        );
      },
    );

    test('6. Respuesta válida se convierte en un borrador tipado', () async {
      final content = jsonEncode({
        'cropType': 'Papa',
        'quantity': 10,
        'unit': 'bulto',
        'priceValue': 2000,
        'priceUnit': 'kg',
        'notes': 'Producto de primera calidad',
      });
      late Map<String, dynamic> requestBody;

      final client = MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': content},
              },
            ],
          }),
          200,
        );
      });
      final service = OpenAiCropExtractionService(
        apiKey: 'test-placeholder-key',
        client: client,
      );

      final draft = await service.extract(
        'Tengo 10 bultos de papa a 2000 pesos el kilo',
      );

      expect(draft.cropType, equals('Papa'));
      expect(draft.quantityKg, equals(500));
      expect(draft.pricePerKg, equals(2000));
      expect(requestBody['response_format'], equals({'type': 'json_object'}));
      expect((requestBody['messages'] as List).first['role'], equals('system'));
      expect(
        (requestBody['messages'] as List).last['content'],
        equals('Tengo 10 bultos de papa a 2000 pesos el kilo'),
      );
    });
  });
}
