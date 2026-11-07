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

    test('7. Endpoint y modelo toman valores predeterminados de DeepSeek', () {
      final service = OpenAiCropExtractionService(apiKey: 'key');

      expect(
        service.endpoint,
        equals('https://api.deepseek.com/chat/completions'),
      );
      expect(service.model, equals('deepseek-chat'));
    });

    test('8. Endpoint y modelo permiten sobreescritura manual', () {
      final service = OpenAiCropExtractionService(
        apiKey: 'key',
        endpoint: 'https://custom-endpoint.com/v1',
        model: 'custom-model',
      );

      expect(service.endpoint, equals('https://custom-endpoint.com/v1'));
      expect(service.model, equals('custom-model'));
    });
  });

  group('VoiceTranscriptBuffer — acumulación de voz ante pausas', () {
    test('1. Acumula múltiples fragmentos separados por pausas sin perder datos', () {
      final buffer = VoiceTranscriptBuffer();
      expect(buffer.isEmpty, isTrue);

      // Primer fragmento en progreso
      buffer.onVoiceResult('Tengo 20 bultos', isFinal: false);
      expect(buffer.fullTranscript, equals('Tengo 20 bultos'));
      expect(buffer.committedText, isEmpty);
      expect(buffer.currentPartial, equals('Tengo 20 bultos'));

      // Pausa detectada: primer fragmento finalizado
      buffer.onVoiceResult('Tengo 20 bultos de cebolla', isFinal: true);
      expect(buffer.committedText, equals('Tengo 20 bultos de cebolla'));
      expect(buffer.currentPartial, isEmpty);
      expect(buffer.fullTranscript, equals('Tengo 20 bultos de cebolla'));

      // Segundo fragmento tras la pausa
      buffer.onVoiceResult('a 40000', isFinal: false);
      expect(
        buffer.fullTranscript,
        equals('Tengo 20 bultos de cebolla a 40000'),
      );

      // Segundo fragmento finalizado
      buffer.onVoiceResult('a 40000 la carga', isFinal: true);
      expect(
        buffer.committedText,
        equals('Tengo 20 bultos de cebolla a 40000 la carga'),
      );
      expect(buffer.currentPartial, isEmpty);
      expect(
        buffer.fullTranscript,
        equals('Tengo 20 bultos de cebolla a 40000 la carga'),
      );
    });

    test('2. Deduplica emisiones acumulativas completas enviadas por el motor', () {
      final buffer = VoiceTranscriptBuffer();

      // Primer segmento finalizado
      buffer.onVoiceResult('Tengo 20 bultos de cebolla', isFinal: true);
      expect(buffer.committedText, equals('Tengo 20 bultos de cebolla'));

      // Motor que reemite el acumulado completo con palabras nuevas
      buffer.onVoiceResult(
        'Tengo 20 bultos de cebolla a 40000 la carga',
        isFinal: false,
      );
      expect(
        buffer.fullTranscript,
        equals('Tengo 20 bultos de cebolla a 40000 la carga'),
      );

      buffer.onVoiceResult(
        'Tengo 20 bultos de cebolla a 40000 la carga',
        isFinal: true,
      );
      expect(
        buffer.committedText,
        equals('Tengo 20 bultos de cebolla a 40000 la carga'),
      );
      expect(
        buffer.fullTranscript,
        equals('Tengo 20 bultos de cebolla a 40000 la carga'),
      );
    });

    test('3. Ignora fragmentos vacíos o sólo con espacios sin borrar lo anterior', () {
      final buffer = VoiceTranscriptBuffer();
      buffer.onVoiceResult('Papa criolla', isFinal: true);

      buffer.onVoiceResult('   ', isFinal: false);
      expect(buffer.fullTranscript, equals('Papa criolla'));

      buffer.onVoiceResult('   ', isFinal: true);
      expect(buffer.committedText, equals('Papa criolla'));
      expect(buffer.fullTranscript, equals('Papa criolla'));
    });

    test('4. setText y clear manipulan el estado del buffer correctamente', () {
      final buffer = VoiceTranscriptBuffer(initialText: 'Texto inicial');
      expect(buffer.fullTranscript, equals('Texto inicial'));

      buffer.setText('Edición manual campesino');
      expect(buffer.committedText, equals('Edición manual campesino'));
      expect(buffer.fullTranscript, equals('Edición manual campesino'));

      buffer.onVoiceResult('a 1500 el kilo', isFinal: true);
      expect(
        buffer.fullTranscript,
        equals('Edición manual campesino a 1500 el kilo'),
      );

      buffer.clear();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.fullTranscript, isEmpty);
    });
  });
}

