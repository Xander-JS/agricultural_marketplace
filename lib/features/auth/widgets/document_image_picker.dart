import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_localizations.dart';

/// Permite inyectar un selector de imágenes alternativo en pruebas o en
/// integraciones futuras sin acoplar las pantallas directamente al plugin.
typedef DocumentImageSelector = Future<File?> Function(
  ImageSource source, {
  CameraDevice preferredCameraDevice,
});

/// Selector por defecto basado en `image_picker`.
///
/// La cámara trasera se usa para documentos y la frontal para la selfie.
Future<File?> defaultDocumentImageSelector(
  ImageSource source, {
  CameraDevice preferredCameraDevice = CameraDevice.rear,
}) async {
  final photo = await ImagePicker().pickImage(
    source: source,
    preferredCameraDevice: preferredCameraDevice,
  );
  if (photo == null) return null;
  return File(photo.path);
}

/// Abre una hoja inferior para elegir cámara o galería y devuelve el archivo
/// seleccionado. No solicita permisos adicionales fuera de los que ya usa la
/// aplicación mediante `image_picker`.
Future<File?> showDocumentImageSourceSheet(
  BuildContext context, {
  DocumentImageSelector? selector,
  CameraDevice preferredCameraDevice = CameraDevice.rear,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                l10n.document_pick_sheet_title,
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              key: const ValueKey('document_pick_camera_option'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.document_pick_camera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              key: const ValueKey('document_pick_gallery_option'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.document_pick_gallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.document_pick_cancel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (source == null) return null;

  final picker = selector ?? defaultDocumentImageSelector;
  return picker(source, preferredCameraDevice: preferredCameraDevice);
}
