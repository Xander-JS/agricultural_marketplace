import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/misc/pressable_scale.dart';

/// Single-choice card for account role and document type.
///
/// Rests as a flat inset card; selection lights the hairline in `primary`,
/// tints the icon well and fills the iPhone-style check. Only color and the
/// check animate, so repeated taps between options stay instant.
class SelectableOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? tagline;
  final String? description;
  final IconData? descriptionIcon;
  final bool selected;
  final VoidCallback onTap;

  const SelectableOptionCard({
    super.key,
    required this.icon,
    required this.title,
    this.tagline,
    this.description,
    this.descriptionIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.quick);
    final wellColor = selected
        ? context.appPrimarySoft
        : context.appSurfaceVariant;
    final iconColor = selected
        ? context.appOnPrimarySoft
        : context.appTextPrimary;

    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(InsetGroupCard.radius),
              border: Border.all(
                color: selected ? context.appPrimary : context.appBorder,
                width: AppDimensions.borderWidthMedium,
              ),
              color: context.appSurface,
            ),
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: duration,
                      curve: AppMotion.easeOut,
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: wellColor,
                        borderRadius: AppDimensions.borderRadiusLG,
                      ),
                      child: Icon(icon, size: 28, color: iconColor),
                    ),
                    const SizedBox(width: AppDimensions.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (tagline != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              tagline!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    AnimatedSwitcher(
                      duration: duration,
                      switchInCurve: AppMotion.easeOut,
                      switchOutCurve: AppMotion.easeOut,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.9,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Icon(
                        selected
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        key: ValueKey(selected),
                        size: 26,
                        color: selected
                            ? context.appPrimary
                            : context.appTextMuted,
                      ),
                    ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: AppDimensions.space12),
                  Divider(height: 1, color: context.appDivider),
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (descriptionIcon != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            descriptionIcon,
                            size: 16,
                            color: context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                      ],
                      Expanded(
                        child: Text(
                          description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
