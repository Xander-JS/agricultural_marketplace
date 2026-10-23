import 'package:flutter/material.dart';

import '../models/crop_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/badges/media_capsule.dart';

/// Lot status pill.
///
/// The default form uses the semantic triads (soft ground, 1px border,
/// AA text). [CropStatusBadge.overlay] draws the same status as a
/// [MediaCapsule] for use over crop photography, with a colored dot that
/// keeps the status hue visible on the dark scrim.
class CropStatusBadge extends StatelessWidget {
  final CropStatus status;
  final bool overlay;

  const CropStatusBadge({super.key, required this.status}) : overlay = false;

  const CropStatusBadge.overlay({super.key, required this.status})
    : overlay = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (AppSemanticTriad triad, String label, Color dot) = switch (status) {
      CropStatus.borrador => (
        context.appNeutralTriad,
        l10n.crop_status_draft,
        AppColors.darkTextSecondary,
      ),
      CropStatus.activa => (
        context.appSuccessTriad,
        l10n.crop_status_active,
        AppColors.successFgDark,
      ),
      CropStatus.pausada => (
        context.appWarningTriad,
        l10n.crop_status_paused,
        AppColors.warningFgDark,
      ),
      CropStatus.agotada => (
        context.appErrorTriad,
        l10n.crop_status_exhausted,
        AppColors.errorFgDark,
      ),
    };

    if (overlay) {
      return MediaCapsule.custom(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: triad.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: triad.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
