import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import 'status_banner.dart';

/// Shows a floating capsule on the theme's inverse surface with a tone icon.
///
/// The ground stays neutral so the message keeps full contrast in both
/// modes; the hue lives only in the icon, taken from the opposite mode's
/// triad because the inverse surface flips lightness.
void showAppSnackBar(
  BuildContext context,
  String message, {
  StatusTone tone = StatusTone.neutral,
}) {
  final onInverseIsLight = !context.appIsDark;
  final Color iconColor = switch (tone) {
    StatusTone.success =>
      onInverseIsLight ? AppColors.successFgDark : AppColors.successFgLight,
    StatusTone.error =>
      onInverseIsLight ? AppColors.errorFgDark : AppColors.errorFgLight,
    StatusTone.warning =>
      onInverseIsLight ? AppColors.warningFgDark : AppColors.warningFgLight,
    StatusTone.info =>
      onInverseIsLight ? AppColors.infoFgDark : AppColors.infoFgLight,
    StatusTone.brand => context.appColorScheme.inversePrimary,
    StatusTone.neutral => context.appColorScheme.onInverseSurface,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              StatusBanner.defaultIcon(tone),
              size: AppDimensions.iconSM,
              color: iconColor,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
