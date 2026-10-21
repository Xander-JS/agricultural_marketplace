import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Tarjeta reutilizable para seleccionar, previsualizar y reemplazar una imagen
/// de documento de identidad antes de enviarla.
class DocumentSelectionCard extends StatelessWidget {
  final String title;
  final String? helperText;
  final File? file;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  final bool enabled;
  final Key? pickButtonKey;

  const DocumentSelectionCard({
    super.key,
    required this.title,
    this.helperText,
    this.file,
    this.onPick,
    this.onRemove,
    this.enabled = true,
    this.pickButtonKey,
  });

  bool get _hasFile => file != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (_hasFile ? context.appSuccess : context.appWarning)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _hasFile
                        ? l10n.document_selected_label
                        : l10n.document_pending_label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _hasFile ? context.appSuccess : context.appWarning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              Text(
                helperText!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 170,
                width: double.infinity,
                color: context.appSurfaceVariant,
                child: _hasFile
                    ? Image.file(
                        file!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(
                          context,
                          Icons.broken_image_outlined,
                          l10n.document_preview_unavailable,
                        ),
                      )
                    : _placeholder(
                        context,
                        Icons.add_photo_alternate_outlined,
                        l10n.document_preview_pending,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: pickButtonKey,
                    onPressed: enabled ? onPick : null,
                    icon: Icon(
                      _hasFile
                          ? Icons.autorenew_outlined
                          : Icons.upload_file_outlined,
                    ),
                    label: Text(
                      _hasFile
                          ? l10n.document_replace_label
                          : l10n.document_pick_label,
                    ),
                  ),
                ),
                if (_hasFile && onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.document_remove_label,
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 42,
            color: context.appTextSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
