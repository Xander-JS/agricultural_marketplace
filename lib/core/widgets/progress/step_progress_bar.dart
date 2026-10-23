import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';

/// Segmented progress for multi-step flows (registration, verification).
///
/// Thin iOS-style segments with a "Paso n de N" counter. Each step is its
/// own screen, so the segment the user just reached fills from the leading
/// edge when the screen appears; earlier segments are already full. The
/// fill is a horizontal scale (GPU-only) and is skipped under Reduce Motion.
class StepProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = AppMotion.of(context, AppMotion.emphasized);
    final step = currentStep.clamp(0, totalSteps);
    final counter = l10n?.registration_step_counter(step, totalSteps);

    return Semantics(
      label: counter,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space20,
          AppDimensions.space4,
          AppDimensions.space20,
          AppDimensions.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (counter != null) ...[
              Text(
                counter,
                style: AppTextStyles.labelMedium.copyWith(
                  color: context.appTextSecondary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
            ],
            Row(
              children: List.generate(totalSteps, (index) {
                final isLast = index == totalSteps - 1;
                final isFilled = index < step;
                final isArriving = index == step - 1;

                Widget fill = ColoredBox(color: context.appPrimary);
                if (isArriving) {
                  fill = TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: duration,
                    curve: AppMotion.easeOut,
                    child: fill,
                    builder: (context, value, child) => Transform.scale(
                      scaleX: value,
                      alignment: AlignmentDirectional.centerStart,
                      child: child,
                    ),
                  );
                }

                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: isLast ? 0 : AppDimensions.space4 + 2,
                    ),
                    child: ClipRRect(
                      borderRadius: AppDimensions.borderRadiusFull,
                      child: SizedBox(
                        height: AppDimensions.space4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: context.appSurfaceVariant),
                            if (isFilled) fill,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
