import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class TipPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const TipPill({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppDimensions.borderRadiusMD,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconXS,
            color: context.appSuccess,
          ),
          const SizedBox(width: AppDimensions.space4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
