import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../misc/app_entrance.dart';

/// Centered empty / no-results card: a stroked icon inside a soft circle,
/// a title, one explanatory line and an optional action.
///
/// [tone] tints the circle; the neutral default suits "nothing here yet",
/// the brand tone suits "start here" moments.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final AppEmptyStateTone tone;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tone = AppEmptyStateTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final triad = tone == AppEmptyStateTone.brand
        ? context.appBrandTriad
        : context.appNeutralTriad;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space24,
        ),
        child: AppEntrance(
          duration: AppMotion.emphasized,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: triad.background,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 28, color: triad.foreground),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: AppDimensions.space24),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppEmptyStateTone { neutral, brand }
