import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
