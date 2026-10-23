import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../misc/pressable_scale.dart';

/// Full-width primary call to action.
///
/// 52px squircle on the strict `primary`/`onPrimary` pair. While
/// [isLoading] the button keeps its brand fill, ignores taps and shows an
/// inline spinner beside the label so its size never jumps.
class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final bool isLoading;

  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    this.text,
    this.icon,
    this.isLoading = false,
  }) : assert(text != null || icon != null);

  void _handlePressed() {
    HapticFeedback.lightImpact();
    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final foreground = context.appOnPrimary;

    final Widget label = text != null
        ? Text(
            text!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.buttonLarge,
          )
        : Icon(icon, size: AppDimensions.iconMD);

    final Widget content = isLoading
        ? Row(
            key: const ValueKey('primary_action_loading'),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  strokeCap: StrokeCap.round,
                  color: foreground,
                ),
              ),
              if (text != null) ...[
                const SizedBox(width: AppDimensions.space12),
                Flexible(child: Opacity(opacity: 0.85, child: label)),
              ],
            ],
          )
        : KeyedSubtree(
            key: const ValueKey('primary_action_idle'),
            child: label,
          );

    return PressableScale(
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeightPrimary,
        child: ElevatedButton(
          onPressed: enabled ? _handlePressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appPrimary,
            foregroundColor: foreground,
            // Loading keeps the brand fill; a truly disabled button greys out.
            disabledBackgroundColor: isLoading
                ? context.appPrimary
                : context.appSurfaceVariant,
            disabledForegroundColor: isLoading
                ? foreground
                : context.appTextMuted,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusControl,
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.quick),
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            child: content,
          ),
        ),
      ),
    );
  }
}
