/// Utilidades compartidas por los flujos de registro y verificación documental.
///
/// Mantener el tipo MIME alineado con el contenido real evita que un bucket con
/// restricciones de tipo rechace una imagen válida, y permite que el
/// almacenamiento entregue el archivo con el `Content-Type` correcto.
library;

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

const Set<String> _allowedExtensions = {
  'jpg',
  'jpeg',
  'png',
  'heic',
  'heif',
  'webp',
  'pdf',
};

/// Devuelve una extensión segura y normalizada para la ruta de almacenamiento.
///
/// Los archivos sin extensión conocida se guardan como `.jpg`, que es el
/// formato que entrega la cámara en la mayoría de los dispositivos.
String documentFileExtension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return 'jpg';

  final extension = path.substring(dot + 1).toLowerCase();
  if (!_allowedExtensions.contains(extension)) return 'jpg';
  return extension == 'jpeg' ? 'jpg' : extension;
}

/// Devuelve el `Content-Type` correspondiente a la extensión del archivo.
String documentContentType(String path) {
  switch (documentFileExtension(path)) {
    case 'png':
      return 'image/png';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    case 'webp':
      return 'image/webp';
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    default:
      return 'image/jpeg';
  }
}

/// Opciones de carga para los documentos de verificación.
///
/// Los documentos siempre se guardan con un nombre nuevo (incluye la marca de
/// tiempo), por lo que no se necesita sobrescribir objetos. `upsert: false`
/// mantiene la operación como un INSERT puro: el bucket `user_documents` solo
/// define políticas INSERT/SELECT/DELETE y su migración excluye UPDATE a
/// propósito. Enviar `x-upsert: true` obliga a Storage a ejecutar un
/// `INSERT ... ON CONFLICT DO UPDATE`, que exige además la política UPDATE y
/// hace fallar la carga aunque el objeto todavía no exista.
FileOptions documentUploadFileOptions(String path) {
  return FileOptions(upsert: false, contentType: documentContentType(path));
}

/// Reintentos con espera exponencial para cada documento.
///
/// En zonas rurales la red cae a mitad de una carga con frecuencia; sin
/// reintentos un solo corte abortaba el registro completo.
class UploadRetryPolicy {
  /// Intentos totales por archivo, incluido el primero.
  final int maxAttempts;

  /// Espera antes del segundo intento; se duplica en cada reintento.
  final Duration initialDelay;

  /// Permite sustituir la espera en pruebas.
  final Future<void> Function(Duration delay) wait;

  const UploadRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 600),
    this.wait = _delay,
  });

  static Future<void> _delay(Duration delay) => Future<void>.delayed(delay);

  static const UploadRetryPolicy standard = UploadRetryPolicy();
}

/// Ejecuta [upload] y lo reintenta solo ante fallos transitorios (red, tiempo
/// de espera, 408/429/5xx). Un error definitivo (permisos, bucket, tipo de
/// archivo) se propaga de inmediato porque repetirlo no cambia el resultado.
Future<void> uploadWithRetry(
  Future<void> Function() upload, {
  UploadRetryPolicy policy = UploadRetryPolicy.standard,
}) async {
  var delay = policy.initialDelay;
  var hadTransientFailure = false;
  for (var attempt = 1; ; attempt++) {
    try {
      await upload();
      return;
    } catch (error) {
      // Si la respuesta del intento anterior se perdió pero el objeto sí se
      // guardó, Storage responde 409 al repetir la misma ruta: ya está arriba.
      if (hadTransientFailure && isStorageObjectAlreadyExists(error)) return;
      if (attempt >= policy.maxAttempts || !isTransientUploadError(error)) {
        rethrow;
      }
      hadTransientFailure = true;
      await policy.wait(delay);
      delay *= 2;
    }
  }
}

const Set<String> _transientStatusCodes = {
  '408',
  '429',
  '500',
  '502',
  '503',
  '504',
};

/// Fallos de red o del servidor que pueden resolverse con solo repetir.
bool isTransientUploadError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return true;
  }
  if (error is StorageException) {
    return _transientStatusCodes.contains(error.statusCode);
  }
  final description = error.toString().toLowerCase();
  return description.contains('clientexception') ||
      description.contains('connection closed') ||
      description.contains('connection reset') ||
      description.contains('failed host lookup') ||
      description.contains('timed out');
}

bool isStorageObjectAlreadyExists(Object error) {
  if (error is! StorageException) return false;
  final message = error.message.toLowerCase();
  return error.statusCode == '409' ||
      message.contains('already exists') ||
      message.contains('duplicate');
}
