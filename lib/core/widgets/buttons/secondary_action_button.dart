import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../misc/pressable_scale.dart';

/// Visual weight of a [SecondaryActionButton].
enum SecondaryActionTone {
  /// Surface fill, hairline border, primary label.
  neutral,

  /// Formal destructive: surface fill and neutral hairline, with only the
  /// label and icon in the error ink.
  destructive,

  /// AI triad: soft sapphire fill and label.
  ai,
}

/// Companion to the primary button: same 52px squircle, quieter fill.
///
/// Built on [OutlinedButton] so it never reads as the screen's primary
/// action, including to tests and assistive tech. While [isLoading] it keeps
/// its size and swaps the icon for a micro-loader.
class SecondaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final SecondaryActionTone tone;
  final double height;

  const SecondaryActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.tone = SecondaryActionTone.neutral,
    this.height = AppDimensions.buttonHeightPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final (Color fill, Color border, Color label) = switch (tone) {
      SecondaryActionTone.neutral => (
        context.appSurface,
        context.appBorder,
        context.appPrimary,
      ),
      SecondaryActionTone.destructive => (
        context.appSurface,
        context.appBorder,
        context.appErrorText,
      ),
      SecondaryActionTone.ai => (
        context.appInfoContainer,
        context.appInfoBorder,
        context.appInfoText,
      ),
    };

    final Widget leading = isLoading
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              strokeCap: StrokeCap.round,
              color: label,
            ),
          )
        : Icon(icon, size: 18);

    return PressableScale(
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: fill,
            foregroundColor: label,
            disabledForegroundColor: isLoading ? label : context.appTextMuted,
            disabledBackgroundColor: isLoading
                ? fill
                : context.appSurfaceVariant,
            side: BorderSide(color: border),
            textStyle: AppTextStyles.buttonMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusControl,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null || isLoading) ...[
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.quick),
                  switchInCurve: AppMotion.easeOut,
                  switchOutCurve: AppMotion.easeOut,
                  child: KeyedSubtree(key: ValueKey(isLoading), child: leading),
                ),
                const SizedBox(width: AppDimensions.space8),
              ],
              Flexible(
                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
