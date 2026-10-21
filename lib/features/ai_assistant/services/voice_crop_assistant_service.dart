import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/voice_crop_draft.dart';
import 'voice_crop_parser.dart';

enum SpeechRecognitionAvailability { available, permissionDenied, unavailable }

enum SpeechCaptureStatus { listening, notListening, done }

typedef SpeechTranscriptCallback = void Function(String text, bool isFinal);
typedef SpeechErrorCallback = void Function(String userMessage);
typedef SpeechStatusCallback = void Function(SpeechCaptureStatus status);

/// Pequeña abstracción del reconocimiento de voz para poder probar la UI sin
/// invocar canales de plataforma reales.
abstract class SpeechRecognitionService {
  Future<SpeechRecognitionAvailability> initialize({
    required SpeechTranscriptCallback onTranscript,
    required SpeechErrorCallback onError,
    required SpeechStatusCallback onStatus,
  });

  Future<void> start();

  Future<void> stop();

  Future<void> cancel();

  bool get isListening;

  Future<void> dispose();
}

/// Implementación real basada en el reconocimiento de voz del sistema
/// operativo (`speech_to_text`). En Android/iOS el audio es gestionado por el
/// servicio del dispositivo; la aplicación no sube archivos de audio a un
/// proveedor propio.
class DeviceSpeechRecognitionService implements SpeechRecognitionService {
  DeviceSpeechRecognitionService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  bool _listening = false;

  SpeechTranscriptCallback? _onTranscript;
  SpeechErrorCallback? _onError;
  SpeechStatusCallback? _onStatus;

  @override
  bool get isListening => _listening;

  @override
  Future<SpeechRecognitionAvailability> initialize({
    required SpeechTranscriptCallback onTranscript,
    required SpeechErrorCallback onError,
    required SpeechStatusCallback onStatus,
  }) async {
    _onTranscript = onTranscript;
    _onError = onError;
    _onStatus = onStatus;

    if (_initialized) {
      return SpeechRecognitionAvailability.available;
    }

    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isMacOS &&
        !Platform.isWindows) {
      return SpeechRecognitionAvailability.unavailable;
    }

    bool available;
    try {
      available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        options: [SpeechToText.androidNoBluetooth],
      );
    } catch (_) {
      return SpeechRecognitionAvailability.unavailable;
    }

    if (!available) {
      var hasPermission = false;
      try {
        hasPermission = await _speech.hasPermission;
      } catch (_) {}
      return hasPermission
          ? SpeechRecognitionAvailability.unavailable
          : SpeechRecognitionAvailability.permissionDenied;
    }

    _initialized = true;
    return SpeechRecognitionAvailability.available;
  }

  @override
  Future<void> start() async {
    if (!_initialized) {
      throw StateError('El reconocimiento de voz no está inicializado.');
    }
    if (_listening) return;

    final localeId = await _selectSpanishLocale();
    await _speech.listen(
      onResult: (result) {
        _onTranscript?.call(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        listenMode: ListenMode.dictation,
      ),
    );
    _listening = true;
  }

  @override
  Future<void> stop() async {
    if (!_initialized) return;
    await _speech.stop();
    _listening = false;
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    if (!_initialized) return;
    await _speech.cancel();
  }

  @override
  Future<void> dispose() async {
    await cancel();
    _onTranscript = null;
    _onError = null;
    _onStatus = null;
  }

  Future<String?> _selectSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      const preferred = ['es_CO', 'es-CO', 'es_ES', 'es-ES', 'es_MX', 'es-MX'];
      for (final localeId in preferred) {
        if (locales.any((locale) => locale.localeId == localeId)) {
          return localeId;
        }
      }
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('es')) {
          return locale.localeId;
        }
      }
    } catch (_) {}
    return null;
  }

  void _handleStatus(String status) {
    switch (status) {
      case SpeechToText.listeningStatus:
        _listening = true;
        _onStatus?.call(SpeechCaptureStatus.listening);
        break;
      case SpeechToText.notListeningStatus:
        _listening = false;
        _onStatus?.call(SpeechCaptureStatus.notListening);
        break;
      case SpeechToText.doneStatus:
        _listening = false;
        _onStatus?.call(SpeechCaptureStatus.done);
        break;
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _listening = false;
    _onError?.call(_friendlySpeechError(error.errorMsg));
    _onStatus?.call(SpeechCaptureStatus.notListening);
  }

  String _friendlySpeechError(String code) {
    switch (code) {
      case 'error_permission':
        return 'El permiso de micrófono fue denegado. Habilítalo en los ajustes del sistema o continúa manualmente.';
      case 'error_no_match':
      case 'error_speech_timeout':
        return 'No se reconoció voz. Intenta hablar más cerca del micrófono o continúa manualmente.';
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
      case 'error_server_disconnected':
        return 'El servicio de reconocimiento de voz no tiene conexión. Revisa tu red o continúa manualmente.';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'El idioma español no está disponible en el reconocimiento de este dispositivo. Puedes continuar manualmente.';
      case 'error_busy':
      case 'error_too_many_requests':
        return 'El reconocimiento de voz está ocupado. Espera un momento y vuelve a intentarlo.';
      default:
        return 'No se pudo completar el reconocimiento de voz. Intenta de nuevo o continúa manualmente.';
    }
  }
}

class AiCropExtractionException implements Exception {
  final String message;

  const AiCropExtractionException(this.message);

  @override
  String toString() => message;
}

class AiConfigurationException extends AiCropExtractionException {
  const AiConfigurationException(super.message);
}

class AiProviderException extends AiCropExtractionException {
  const AiProviderException(super.message);
}

/// Abstracción de extracción de datos para inyectar dobles en las pruebas.
abstract class AiCropExtractionService {
  bool get isConfigured;

  Future<VoiceCropDraft> extract(String transcript);
}

/// Extracción mediante un endpoint compatible con OpenAI Chat Completions.
///
/// La clave se lee de `AI_API_KEY` en dotenv. Esta integración es válida para
/// el prototipo, pero una clave incluida en una app Flutter puede extraerse;
/// para producción debe moverse a un backend o Edge Function.
class OpenAiCropExtractionService implements AiCropExtractionService {
  static const String defaultEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String defaultModel = 'gpt-4o-mini';

  final http.Client? _client;
  final String? _apiKeyOverride;
  final String endpoint;
  final String model;

  OpenAiCropExtractionService({
    http.Client? client,
    String? apiKey,
    this.endpoint = defaultEndpoint,
    this.model = defaultModel,
  }) : _client = client, // ignore: prefer_initializing_formals
       _apiKeyOverride = apiKey;

  String? get _apiKey {
    if (_apiKeyOverride != null) return _apiKeyOverride;
    if (!dotenv.isInitialized) return null;
    return dotenv.env['AI_API_KEY'];
  }

  @override
  bool get isConfigured {
    final key = _apiKey;
    return key != null && key.trim().isNotEmpty;
  }

  @override
  Future<VoiceCropDraft> extract(String transcript) async {
    final key = _apiKey?.trim();
    if (key == null || key.isEmpty) {
      throw const AiConfigurationException(
        'La interpretación con IA no está configurada. Falta AI_API_KEY. Puedes dictar y continuar manualmente.',
      );
    }
    if (transcript.trim().isEmpty) {
      throw const AiProviderException(
        'La transcripción está vacía. Graba de nuevo o escribe lo que deseas publicar.',
      );
    }

    final requestBody = jsonEncode(<String, dynamic>{
      'model': model,
      'temperature': 0,
      'max_tokens': 350,
      'response_format': <String, String>{'type': 'json_object'},
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': _systemPrompt},
        <String, String>{'role': 'user', 'content': transcript},
      ],
    });

    http.Response response;
    try {
      final uri = Uri.parse(endpoint);
      final headers = <String, String>{
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      };
      final request = _client == null
          ? http.post(uri, headers: headers, body: requestBody)
          : _client.post(uri, headers: headers, body: requestBody);
      response = await request.timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const AiProviderException(
        'El proveedor de IA tardó demasiado en responder. Revisa tu conexión e intenta de nuevo.',
      );
    } on http.ClientException {
      throw const AiProviderException(
        'No se pudo conectar con el proveedor de IA. Revisa tu conexión e intenta de nuevo.',
      );
    } on SocketException {
      throw const AiProviderException(
        'No se pudo conectar con el proveedor de IA. Revisa tu conexión e intenta de nuevo.',
      );
    } catch (_) {
      throw const AiProviderException(
        'No se pudo conectar con el proveedor de IA. Intenta de nuevo o continúa manualmente.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(
        'El proveedor de IA no pudo procesar la solicitud (código ${response.statusCode}). Intenta de nuevo o continúa manualmente.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const AiProviderException(
        'El proveedor de IA devolvió una respuesta inválida. Intenta de nuevo o continúa manualmente.',
      );
    }

    final content = _extractMessageContent(decoded);
    if (content == null || content.trim().isEmpty) {
      throw const AiProviderException(
        'El proveedor de IA devolvió una respuesta vacía o incompleta. Intenta de nuevo o continúa manualmente.',
      );
    }

    try {
      return VoiceCropParser.parse(content, transcript: transcript);
    } on VoiceCropParseException catch (error) {
      throw AiProviderException(error.message);
    }
  }

  String? _extractMessageContent(dynamic decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  static const String _systemPrompt =
      'Eres un asistente que extrae datos de una publicación agrícola en Colombia. '
      'Devuelve SOLO un objeto JSON, sin texto adicional, con exactamente estas claves: '
      '{"cropType": string|null, "quantity": number|null, "unit": string|null, '
      '"priceValue": number|null, "priceUnit": string|null, "notes": string|null}. '
      'Usa null cuando el agricultor no haya expresado el dato; nunca inventes ni completes datos. '
      'No calcules el precio por kilogramo: copia el valor y la unidad tal como se expresaron. '
      'Las unidades permitidas son kg, bulto, arroba, canastilla, caja y tonelada. '
      'Normaliza sinónimos de unidades y usa "kg" cuando el precio sea por kilogramo. '
      'Si el agricultor menciona una cantidad en bultos, arrobas, canastillas, cajas o toneladas, '
      'conserva esa unidad en "unit" y la cantidad numérica en "quantity". '
      'Si el precio es ambiguo o no se indica su unidad, deja "priceUnit" en null. '
      'No incluyas explicaciones fuera del JSON.';
}
