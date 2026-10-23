import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Permite inyectar un selector de imágenes alternativo en pruebas o en
/// integraciones futuras sin acoplar las pantallas directamente al plugin.
typedef DocumentImageSelector = Future<File?> Function(
  ImageSource source, {
  CameraDevice preferredCameraDevice,
});

/// Selector por defecto basado en `image_picker`.
///
/// La cámara trasera se usa para documentos y la frontal para la selfie.
///
/// `image_picker` entrega la captura en el directorio de caché del sistema,
/// que el dispositivo puede vaciar mientras el usuario completa los demás
/// pasos. Por eso los bytes se leen de inmediato y se copian a un directorio
/// propio de la aplicación; el archivo devuelto sigue disponible al subirlo.
Future<File?> defaultDocumentImageSelector(
  ImageSource source, {
  CameraDevice preferredCameraDevice = CameraDevice.rear,
}) async {
  final photo = await ImagePicker().pickImage(
    source: source,
    preferredCameraDevice: preferredCameraDevice,
    // Mantiene el documento legible y evita cargas de varios MB que fallan
    // con conexiones rurales inestables.
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 85,
  );
  if (photo == null) return null;

  final bytes = await photo.readAsBytes();
  if (bytes.isEmpty) {
    throw const FileSystemException('La imagen seleccionada está vacía.');
  }
  return persistDocumentImageBytes(bytes, photo.name);
}

const String _persistedDocumentsFolder = 'pending_verification_documents';

Future<Directory> _persistedDocumentsDirectory() async {
  final base = await getApplicationSupportDirectory();
  return Directory('${base.path}/$_persistedDocumentsFolder');
}

/// Copia los bytes de una imagen de verificación a un archivo que no depende
/// de la caché temporal del sistema.
Future<File> persistDocumentImageBytes(List<int> bytes, String name) async {
  final dot = name.lastIndexOf('.');
  final extension = dot >= 0 && dot < name.length - 1
      ? name.substring(dot + 1).toLowerCase()
      : 'jpg';
  final directory = await _persistedDocumentsDirectory();
  await directory.create(recursive: true);
  final file = File(
    '${directory.path}/doc_${DateTime.now().microsecondsSinceEpoch}.$extension',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Elimina las copias locales de los documentos una vez enviados, para no
/// conservar imágenes de identidad en el dispositivo. Es de mejor esfuerzo.
Future<void> clearPersistedDocumentImages() async {
  try {
    final directory = await _persistedDocumentsDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  } catch (_) {}
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
      Widget option({
        required Key key,
        required IconData icon,
        required String label,
        required ImageSource value,
      }) {
        return ListTile(
          key: key,
          minTileHeight: 56,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
          ),
          leading: Icon(icon, size: 22, color: ctx.appPrimary),
          title: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: ctx.appTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: ctx.appTextMuted,
          ),
          onTap: () => Navigator.of(ctx).pop(value),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space16,
            0,
            AppDimensions.space16,
            AppDimensions.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.space4,
                  bottom: AppDimensions.space12,
                ),
                child: Text(
                  l10n.document_pick_sheet_title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: ctx.appTextPrimary,
                  ),
                ),
              ),
              Material(
                color: ctx.appBackground,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusLG,
                  side: BorderSide(color: ctx.appBorder),
                ),
                child: Column(
                  children: [
                    option(
                      key: const ValueKey('document_pick_camera_option'),
                      icon: LucideIcons.camera,
                      label: l10n.document_pick_camera,
                      value: ImageSource.camera,
                    ),
                    Divider(height: 1, indent: 54, color: ctx.appDivider),
                    option(
                      key: const ValueKey('document_pick_gallery_option'),
                      icon: LucideIcons.image,
                      label: l10n.document_pick_gallery,
                      value: ImageSource.gallery,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    AppDimensions.buttonHeightMedium,
                  ),
                ),
                child: Text(l10n.document_pick_cancel),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;

  final picker = selector ?? defaultDocumentImageSelector;
  return picker(source, preferredCameraDevice: preferredCameraDevice);
}
