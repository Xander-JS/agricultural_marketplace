/// Diagnóstico seguro para fallos de autenticación, base de datos y Storage.
///
/// Los mensajes que se construyen aquí se usan únicamente para depuración
/// (logs en modo debug y el campo `debugReason` de los resultados). Nunca deben
/// mostrarse al usuario ni incluir documentos, credenciales, rutas de archivos,
/// identificadores de usuario, correos o teléfonos.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int _maxDiagnosticLength = 320;

/// Elimina datos personales y rutas de un texto antes de registrarlo.
String sanitizeDiagnostic(String input, {Iterable<String?> redact = const []}) {
  var output = input.replaceAll(RegExp(r'\s+'), ' ').trim();

  for (final value in redact) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) continue;
    output = output.replaceAll(raw, '<redacted>');
  }

  output = output
      // URLs completas (p. ej. URLs firmadas de Storage).
      .replaceAll(RegExp(r'https?://[^\s]+', caseSensitive: false), '<url>')
      // Correos electrónicos.
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<email>')
      // UUID / identificadores de usuario.
      .replaceAll(
        RegExp(
          r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
          r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
        ),
        '<id>',
      )
      // Teléfonos (7 a 15 dígitos, con prefijo internacional opcional).
      .replaceAll(RegExp(r'\+?\d{7,15}'), '<phone>')
      // Rutas absolutas de Unix, Windows o UNC. La condición evita convertir
      // tipos MIME como `image/jpeg` en una ruta.
      .replaceAll(
        RegExp(
          r'(?<![\w:])(?:[A-Za-z]:[\\/]|//|/|\\\\)'
          r'[^\s,;:()\[\]{}]+',
        ),
        '<path>',
      )
      // Nombres de archivo sueltos.
      .replaceAll(
        RegExp(
          r'\b[\w-]+\.(?:jpe?g|png|heic|heif|webp|pdf)\b',
          caseSensitive: false,
        ),
        '<file>',
      );

  if (output.length > _maxDiagnosticLength) {
    output = '${output.substring(0, _maxDiagnosticLength)}…';
  }
  return output;
}

/// Construye una descripción estable y segura de una excepción.
///
/// Incluye la etapa, el tipo de excepción y los códigos/estados que aporta el
/// proveedor. No incluye cuerpos de documentos ni credenciales.
String describeException(
  Object error, {
  required String stage,
  Iterable<String?> redact = const [],
  Map<String, String?> context = const {},
}) {
  final parts = <String>['stage=$stage'];

  void add(String key, String? value) {
    if (value == null) return;
    final clean = sanitizeDiagnostic(value, redact: redact);
    if (clean.isEmpty) return;
    parts.add('$key=$clean');
  }

  String? hint;

  if (error is StorageException) {
    parts.add('type=StorageException');
    add('status', error.statusCode);
    add('code', error.error);
    add('message', error.message);

    final signal = '${error.message} ${error.error ?? ''}'.toLowerCase();
    if (signal.contains('bucket not found') ||
        signal.contains('nosuchbucket')) {
      hint = 'storage_bucket_missing';
    } else if (signal.contains('row-level security') ||
        signal.contains('row level security') ||
        signal.contains('rls')) {
      hint = 'storage_rls_denied';
    } else if (signal.contains('signature verification failed') ||
        signal.contains('jwt') ||
        signal.contains('invalid token')) {
      hint = 'storage_invalid_session';
    } else if (error.statusCode == '401' || error.statusCode == '403') {
      hint = 'storage_permission_denied';
    } else if (signal.contains('mime') ||
        signal.contains('content type') ||
        signal.contains('content-type')) {
      hint = 'storage_content_type_rejected';
    } else if (signal.contains('payload too large') ||
        signal.contains('entity too large') ||
        error.statusCode == '413') {
      hint = 'storage_file_too_large';
    }
  } else if (error is PostgrestException) {
    parts.add('type=PostgrestException');
    add('code', error.code);
    add('message', error.message);
    if (error.code == '42501') {
      hint = 'database_permission_denied';
    } else if (error.code == '23505') {
      hint = 'duplicate';
    }
  } else if (error is AuthException) {
    parts.add('type=AuthException');
    add('code', error.code);
    add('message', error.message);
  } else if (error is FileSystemException) {
    parts.add('type=FileSystemException');
    add('osError', error.osError?.toString());
    add('message', error.message);
  } else if (error is TimeoutException) {
    parts.add('type=TimeoutException');
    add('message', error.message);
  } else if (error is SocketException) {
    parts.add('type=SocketException');
    add('osError', error.osError?.toString());
    add('message', error.message);
  } else {
    parts.add('type=${error.runtimeType}');
    add('message', error.toString());
  }

  for (final entry in context.entries) {
    add(entry.key, entry.value);
  }

  if (hint != null) parts.add('hint=$hint');
  return parts.join('; ');
}

/// Registra un diagnóstico solo en compilaciones de depuración.
void logAuthDiagnostic(String scope, String reason) {
  if (!kDebugMode) return;
  debugPrint('[auth][$scope] $reason');
}
