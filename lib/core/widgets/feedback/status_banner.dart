import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../misc/app_entrance.dart';

/// Semantic tones shared by banners and snack bars.
enum StatusTone { success, error, warning, info, brand, neutral }

extension StatusToneTriad on BuildContext {
  AppSemanticTriad triadFor(StatusTone tone) => switch (tone) {
    StatusTone.success => appSuccessTriad,
    StatusTone.error => appErrorTriad,
    StatusTone.warning => appWarningTriad,
    StatusTone.info => appInfoTriad,
    StatusTone.brand => appBrandTriad,
    StatusTone.neutral => appNeutralTriad,
  };
}

/// Inline status message drawn with the high-contrast triad: soft ground,
/// 1px border and strong text/icon of the same hue.
///
/// Settles in with a short fade and rise the first time it appears, since it
/// always reports the result of something the user just did.
class StatusBanner extends StatelessWidget {
  final StatusTone tone;
  final String message;
  final String? title;
  final IconData? icon;
  final Key? messageKey;

  const StatusBanner({
    super.key,
    required this.tone,
    required this.message,
    this.title,
    this.icon,
    this.messageKey,
  });

  static IconData defaultIcon(StatusTone tone) => switch (tone) {
    StatusTone.success => LucideIcons.circleCheck,
    StatusTone.error => LucideIcons.circleAlert,
    StatusTone.warning => LucideIcons.triangleAlert,
    StatusTone.info => LucideIcons.info,
    StatusTone.brand => LucideIcons.shieldCheck,
    StatusTone.neutral => LucideIcons.info,
  };

  @override
  Widget build(BuildContext context) {
    final triad = context.triadFor(tone);

    return AppEntrance(
      duration: AppMotion.standard,
      offsetY: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space12,
          AppDimensions.space12,
          AppDimensions.space16,
          AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: triad.background,
          borderRadius: AppDimensions.borderRadiusControl,
          border: Border.all(color: triad.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? defaultIcon(tone),
              size: AppDimensions.iconSM,
              color: triad.foreground,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: triad.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space2),
                  ],
                  Text(
                    message,
                    key: messageKey,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: title == null
                          ? triad.text
                          : context.appTextPrimary,
                      fontWeight: title == null
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
