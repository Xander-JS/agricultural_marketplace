import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agricultural_marketplace/features/ai_assistant/models/voice_crop_draft.dart';
import 'package:agricultural_marketplace/features/ai_assistant/services/voice_crop_assistant_service.dart';
import 'package:agricultural_marketplace/features/ai_assistant/widgets/voice_crop_assistant_sheet.dart';

class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({
    this.availability = SpeechRecognitionAvailability.available,
  });

  SpeechRecognitionAvailability availability;
  String? transcriptOnStop;

  SpeechTranscriptCallback? _onTranscript;
  SpeechErrorCallback? _onError;
  SpeechStatusCallback? _onStatus;

  bool started = false;
  bool stopped = false;
  bool canceled = false;
  bool disposed = false;

  @override
  bool get isListening => started && !stopped && !canceled;

  @override
  Future<SpeechRecognitionAvailability> initialize({
    required SpeechTranscriptCallback onTranscript,
    required SpeechErrorCallback onError,
    required SpeechStatusCallback onStatus,
  }) async {
    _onTranscript = onTranscript;
    _onError = onError;
    _onStatus = onStatus;
    return availability;
  }

  @override
  Future<void> start() async {
    started = true;
    _onStatus?.call(SpeechCaptureStatus.listening);
  }

  @override
  Future<void> stop() async {
    stopped = true;
    final text = transcriptOnStop;
    if (text != null) {
      _onTranscript?.call(text, true);
    }
    _onStatus?.call(SpeechCaptureStatus.done);
  }

  @override
  Future<void> cancel() async {
    canceled = true;
    _onStatus?.call(SpeechCaptureStatus.notListening);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void emitPartial(String text) {
    _onTranscript?.call(text, false);
  }

  void emitError(String message) {
    _onError?.call(message);
  }
}

class FakeAiCropExtractionService implements AiCropExtractionService {
  FakeAiCropExtractionService({
    this.configured = true,
    this.draft,
    List<Object>? results,
  }) : results = results ?? <Object>[];

  bool configured;
  VoiceCropDraft? draft;
  final List<Object> results;
  int calls = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<VoiceCropDraft> extract(String transcript) async {
    calls++;
    final result = results.isNotEmpty
        ? results.removeAt(0)
        : (draft ?? VoiceCropDraft(transcript: transcript));
    if (result is AiCropExtractionException) throw result;
    return result as VoiceCropDraft;
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  Widget buildHarness({
    required FakeSpeechRecognitionService speech,
    required FakeAiCropExtractionService ai,
    required void Function(VoiceCropAssistantResult?) onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final result =
                    await showModalBottomSheet<VoiceCropAssistantResult>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => VoiceCropAssistantSheet(
                        speechService: speech,
                        aiService: ai,
                        playCue: () async {},
                      ),
                    );
                onResult(result);
              },
              child: const Text('Abrir asistente'),
            ),
          ),
        ),
      ),
    );
  }

  VoiceCropDraft completeDraft(String transcript) {
    return VoiceCropDraft(
      transcript: transcript,
      cropType: 'Papa',
      quantity: 10,
      unit: VoiceCropUnit.kilogram,
      quantityKg: 10,
      pricePerKg: 2000,
    );
  }

  testWidgets('1. Flujo completo: escucha, transcripción, IA y borrador', (
    tester,
  ) async {
    final speech = FakeSpeechRecognitionService()
      ..transcriptOnStop = 'Tengo 10 kilos de papa a 2000 pesos el kilo';
    final ai = FakeAiCropExtractionService(
      draft: completeDraft(speech.transcriptOnStop!),
    );
    VoiceCropAssistantResult? result;

    await tester.pumpWidget(
      buildHarness(speech: speech, ai: ai, onResult: (value) => result = value),
    );
    await tapVisible(tester, find.text('Abrir asistente'));

    await tapVisible(tester, find.byKey(const Key('voice_crop_start_button')));
    expect(find.text('Escuchando...'), findsOneWidget);

    speech.emitPartial('Tengo 10 kilos de papa');
    await tester.pump();
    expect(find.textContaining('Tengo 10 kilos de papa'), findsWidgets);

    await tapVisible(tester, find.byKey(const Key('voice_crop_stop_button')));
    expect(
      find.byKey(const Key('voice_crop_transcript_field')),
      findsOneWidget,
    );
    expect(
      find.text('Tengo 10 kilos de papa a 2000 pesos el kilo'),
      findsOneWidget,
    );

    await tapVisible(
      tester,
      find.byKey(const Key('voice_crop_interpret_button')),
    );
    expect(find.text('Datos reconocidos'), findsOneWidget);
    expect(find.text('Papa'), findsOneWidget);
    expect(find.text('10 kg'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const Key('voice_crop_continue_button')),
    );

    expect(result, isNotNull);
    expect(result!.draft, isNotNull);
    expect(result!.draft!.cropType, equals('Papa'));
    expect(result!.draft!.quantityKg, equals(10));
    expect(result!.draft!.pricePerKg, equals(2000));
    expect(ai.calls, equals(1));
  });

  testWidgets('2. Permiso denegado informa y permite continuar manualmente', (
    tester,
  ) async {
    final speech = FakeSpeechRecognitionService(
      availability: SpeechRecognitionAvailability.permissionDenied,
    );
    final ai = FakeAiCropExtractionService();
    VoiceCropAssistantResult? result;

    await tester.pumpWidget(
      buildHarness(speech: speech, ai: ai, onResult: (value) => result = value),
    );
    await tapVisible(tester, find.text('Abrir asistente'));

    await tapVisible(tester, find.byKey(const Key('voice_crop_start_button')));
    expect(find.text('Permiso de micrófono denegado'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('voice_crop_manual_button')));
    expect(result, isNotNull);
    expect(result!.openManual, isTrue);
    expect(result!.draft, isNull);
  });

  testWidgets(
    '3. Servicio no disponible informa y permite continuar manualmente',
    (tester) async {
      final speech = FakeSpeechRecognitionService(
        availability: SpeechRecognitionAvailability.unavailable,
      );
      final ai = FakeAiCropExtractionService();

      await tester.pumpWidget(
        buildHarness(speech: speech, ai: ai, onResult: (_) {}),
      );
      await tapVisible(tester, find.text('Abrir asistente'));

      await tapVisible(
        tester,
        find.byKey(const Key('voice_crop_start_button')),
      );
      expect(find.text('Reconocimiento de voz no disponible'), findsOneWidget);
      expect(find.byKey(const Key('voice_crop_manual_button')), findsOneWidget);
    },
  );

  testWidgets(
    '4. Clave de IA ausente muestra aviso y conserva el flujo manual',
    (tester) async {
      final speech = FakeSpeechRecognitionService()
        ..transcriptOnStop = 'Tengo 10 kilos de papa a 2000 pesos';
      final ai = FakeAiCropExtractionService(configured: false);

      await tester.pumpWidget(
        buildHarness(speech: speech, ai: ai, onResult: (_) {}),
      );
      await tapVisible(tester, find.text('Abrir asistente'));
      expect(find.textContaining('falta AI_API_KEY'), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const Key('voice_crop_start_button')),
      );
      await tapVisible(tester, find.byKey(const Key('voice_crop_stop_button')));
      await tapVisible(
        tester,
        find.byKey(const Key('voice_crop_interpret_button')),
      );

      expect(find.textContaining('AI_API_KEY'), findsWidgets);
      expect(find.byKey(const Key('voice_crop_manual_button')), findsOneWidget);
      expect(ai.calls, isZero);
    },
  );

  testWidgets('5. Error del proveedor permite reintentar y luego continuar', (
    tester,
  ) async {
    final transcript = 'Tengo 10 kilos de papa a 2000 pesos';
    final speech = FakeSpeechRecognitionService()
      ..transcriptOnStop = transcript;
    final ai = FakeAiCropExtractionService(
      results: [
        const AiProviderException(
          'No se pudo conectar con el proveedor de IA. Revisa tu conexión.',
        ),
        completeDraft(transcript),
      ],
    );
    VoiceCropAssistantResult? result;

    await tester.pumpWidget(
      buildHarness(speech: speech, ai: ai, onResult: (value) => result = value),
    );
    await tapVisible(tester, find.text('Abrir asistente'));
    await tapVisible(tester, find.byKey(const Key('voice_crop_start_button')));
    await tapVisible(tester, find.byKey(const Key('voice_crop_stop_button')));
    await tapVisible(
      tester,
      find.byKey(const Key('voice_crop_interpret_button')),
    );

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('voice_crop_retry_button')));
    expect(find.text('Datos reconocidos'), findsOneWidget);

    await tapVisible(
      tester,
      find.byKey(const Key('voice_crop_continue_button')),
    );
    expect(result?.draft?.cropType, equals('Papa'));
    expect(ai.calls, equals(2));
  });

  testWidgets(
    '6. Captura sin voz reconocida presenta error y alternativa manual',
    (tester) async {
      final speech = FakeSpeechRecognitionService()..transcriptOnStop = '';
      final ai = FakeAiCropExtractionService();

      await tester.pumpWidget(
        buildHarness(speech: speech, ai: ai, onResult: (_) {}),
      );
      await tapVisible(tester, find.text('Abrir asistente'));
      await tapVisible(
        tester,
        find.byKey(const Key('voice_crop_start_button')),
      );
      await tapVisible(tester, find.byKey(const Key('voice_crop_stop_button')));

      expect(find.textContaining('No se reconoció voz'), findsOneWidget);
      expect(find.byKey(const Key('voice_crop_manual_button')), findsOneWidget);
      expect(ai.calls, isZero);
    },
  );

  testWidgets(
    '7. Cancelar cierra sin devolver un borrador y detiene la captura',
    (tester) async {
      final speech = FakeSpeechRecognitionService();
      final ai = FakeAiCropExtractionService();
      VoiceCropAssistantResult? result;
      var completed = false;

      await tester.pumpWidget(
        buildHarness(
          speech: speech,
          ai: ai,
          onResult: (value) {
            result = value;
            completed = true;
          },
        ),
      );
      await tapVisible(tester, find.text('Abrir asistente'));
      await tapVisible(
        tester,
        find.byKey(const Key('voice_crop_start_button')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('voice_crop_cancel_button')),
      );

      expect(completed, isTrue);
      expect(result, isNull);
      expect(speech.canceled, isTrue);
    },
  );

  testWidgets('8. Error de transcripción ofrece reintento y flujo manual', (
    tester,
  ) async {
    final speech = FakeSpeechRecognitionService();
    final ai = FakeAiCropExtractionService();

    await tester.pumpWidget(
      buildHarness(speech: speech, ai: ai, onResult: (_) {}),
    );
    await tapVisible(tester, find.text('Abrir asistente'));
    await tapVisible(tester, find.byKey(const Key('voice_crop_start_button')));

    speech.emitError(
      'El servicio de reconocimiento de voz no tiene conexión. Revisa tu red o continúa manualmente.',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('no tiene conexión'), findsOneWidget);
    expect(find.byKey(const Key('voice_crop_retry_button')), findsOneWidget);
    expect(find.byKey(const Key('voice_crop_manual_button')), findsOneWidget);
    expect(ai.calls, isZero);
  });
}
