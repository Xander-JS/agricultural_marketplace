/// Utilidades compartidas por los flujos de registro y verificación documental.
///
/// Mantener el tipo MIME alineado con el contenido real evita que un bucket con
/// restricciones de tipo rechace una imagen válida, y permite que el
/// almacenamiento entregue el archivo con el `Content-Type` correcto.
library;

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
