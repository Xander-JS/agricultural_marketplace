import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// A reusable badge for status like 'Preventa' or 'Listo para despacho'.
class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  /// Factory for 'Preventa' status (Orange).
  factory StatusBadge.preventa({required String text}) {
    return StatusBadge(
      text: text,
      backgroundColor: AppColors.statusPreventaBackground,
      textColor: AppColors.statusPreventaText,
      icon: Icons.circle,
    );
  }

  /// Factory for 'Listo para despacho' status (Green).
  factory StatusBadge.ready({required String text}) {
    return StatusBadge(
      text: text,
      backgroundColor: AppColors.statusReadyBackground,
      textColor: AppColors.statusReadyText,
      icon: Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8 - 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDimensions.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppDimensions.iconXS - 4, color: textColor),
            const SizedBox(width: AppDimensions.space4 + 2),
          ],
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
