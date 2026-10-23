import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Semantic tones a [StatusBadge] can resolve from the active theme.
enum StatusBadgeTone { success, warning, error, info, brand }

/// Status pill, e.g. "Preventa" or "Listo para despacho".
///
/// Drawn with the semantic triad: soft fill, 1px border and a strong
/// foreground for text and icon. Factory badges resolve their triad from the
/// theme, so they stay legible in light and dark mode.
class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  /// Border color; defaults to [textColor] at low opacity.
  final Color? borderColor;

  /// When set, colors come from the theme triad instead of the fixed values.
  final StatusBadgeTone? tone;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.borderColor,
    this.tone,
  });

  /// 'Preventa' status (Harvest amber).
  factory StatusBadge.preventa({required String text}) {
    return StatusBadge(
      text: text,
      backgroundColor: AppColors.statusPreventaBackground,
      textColor: AppColors.statusPreventaText,
      icon: LucideIcons.clock,
      tone: StatusBadgeTone.warning,
    );
  }

  /// 'Listo para despacho' status (green).
  factory StatusBadge.ready({required String text}) {
    return StatusBadge(
      text: text,
      backgroundColor: AppColors.statusReadyBackground,
      textColor: AppColors.statusReadyText,
      icon: LucideIcons.packageCheck,
      tone: StatusBadgeTone.success,
    );
  }

  AppSemanticTriad _resolve(BuildContext context) {
    return switch (tone) {
      StatusBadgeTone.success => context.appSuccessTriad,
      StatusBadgeTone.warning => context.appWarningTriad,
      StatusBadgeTone.error => context.appErrorTriad,
      StatusBadgeTone.info => context.appInfoTriad,
      StatusBadgeTone.brand => context.appBrandTriad,
      null => AppSemanticTriad(
        background: backgroundColor,
        border: borderColor ?? textColor.withValues(alpha: 0.28),
        foreground: textColor,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final triad = _resolve(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8 + 2,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: AppDimensions.borderRadiusFull,
        border: Border.all(color: triad.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: triad.foreground),
            const SizedBox(width: AppDimensions.space4 + 1),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: triad.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
