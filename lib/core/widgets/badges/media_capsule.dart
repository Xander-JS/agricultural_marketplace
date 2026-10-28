import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Capsule label drawn over photography: blurred backdrop, black at 65%
/// and white text.
///
/// The dark scrim keeps the label readable over any crop photo, including
/// a bright white sack of rice or a sunlit field, in both themes.
class MediaCapsule extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// Shown instead of [label] when the capsule needs a richer layout
  /// (for example a counter that tests read as a single text).
  final Widget? child;

  const MediaCapsule({super.key, required this.label, this.icon})
    : child = null;

  const MediaCapsule.custom({super.key, required Widget this.child})
    : label = '',
      icon = null;

  static const Color scrim = Color(0xA6000000); // #000000 at 65%

  @override
  Widget build(BuildContext context) {
    final content =
        child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.onBrand),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onBrand,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: scrim),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.onBrand),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
