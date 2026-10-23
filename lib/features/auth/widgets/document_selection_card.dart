import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/badges/status_badge.dart';
import '../../../core/widgets/buttons/secondary_action_button.dart';
import '../../../core/widgets/cards/inset_group_card.dart';

/// Tarjeta reutilizable para seleccionar, previsualizar y reemplazar una imagen
/// de documento de identidad antes de enviarla.
///
/// Inset card with a status badge, a cropped 16px-radius preview (tap it to
/// pick or replace) and a quiet pick/replace action beside a remove control.
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

    return InsetGroupCard(
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 0, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                StatusBadge(
                  text: _hasFile
                      ? l10n.document_selected_label
                      : l10n.document_pending_label,
                  backgroundColor: AppColors.transparent,
                  textColor: AppColors.transparent,
                  icon: _hasFile ? LucideIcons.circleCheck : LucideIcons.clock,
                  tone: _hasFile
                      ? StatusBadgeTone.success
                      : StatusBadgeTone.warning,
                ),
              ],
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: AppDimensions.space4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                helperText!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space12),
          Semantics(
            button: enabled && onPick != null,
            label: _hasFile
                ? l10n.document_replace_label
                : l10n.document_pick_label,
            child: GestureDetector(
              onTap: enabled ? onPick : null,
              child: ClipRRect(
                borderRadius: AppDimensions.borderRadiusLG,
                child: Container(
                  height: 168,
                  width: double.infinity,
                  color: context.appSurfaceVariant,
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.standard),
                    switchInCurve: AppMotion.easeOut,
                    switchOutCurve: AppMotion.easeOut,
                    child: _hasFile
                        ? Image.file(
                            file!,
                            key: ValueKey(file!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 168,
                            errorBuilder: (_, _, _) => _placeholder(
                              context,
                              LucideIcons.imageOff,
                              l10n.document_preview_unavailable,
                            ),
                          )
                        : _placeholder(
                            context,
                            LucideIcons.imagePlus,
                            l10n.document_preview_pending,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: SecondaryActionButton(
                  key: pickButtonKey,
                  height: AppDimensions.buttonHeightMedium,
                  onPressed: enabled ? onPick : null,
                  icon: _hasFile ? LucideIcons.refreshCw : LucideIcons.upload,
                  text: _hasFile
                      ? l10n.document_replace_label
                      : l10n.document_pick_label,
                ),
              ),
              if (_hasFile && onRemove != null) ...[
                const SizedBox(width: AppDimensions.space8),
                IconButton(
                  tooltip: l10n.document_remove_label,
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(LucideIcons.trash2, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: context.appErrorText,
                    backgroundColor: context.appErrorContainer,
                    fixedSize: const Size.square(
                      AppDimensions.buttonHeightMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.borderRadiusControl,
                      side: BorderSide(color: context.appErrorBorder),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, IconData icon, String label) {
    return Center(
      key: ValueKey(icon),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: context.appTextSecondary),
            const SizedBox(height: AppDimensions.space8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
