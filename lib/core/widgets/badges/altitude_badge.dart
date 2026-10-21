import 'package:flutter/material.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// A reusable badge to display altitude over images.
class AltitudeBadge extends StatelessWidget {
  final String text;

  const AltitudeBadge({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: AppDimensions.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: AppDimensions.iconSM - 6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDimensions.space4),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
