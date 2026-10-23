import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Altitude chip laid over crop photographs (e.g. "2.850 m s. n. m.").
///
/// An opaque surface pill with a 1px border so the reading holds on any
/// photo, in light and dark mode.
class AltitudeBadge extends StatelessWidget {
  final String text;

  const AltitudeBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8 + 2,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: context.appSurface.withValues(alpha: 0.94),
        borderRadius: AppDimensions.borderRadiusFull,
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.mountain, size: 13, color: context.appPrimary),
          const SizedBox(width: AppDimensions.space4 + 1),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: context.appTextPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
