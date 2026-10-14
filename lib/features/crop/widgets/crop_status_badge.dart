import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../../../core/theme/app_colors.dart';

class CropStatusBadge extends StatelessWidget {
  final CropStatus status;

  const CropStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case CropStatus.borrador:
        backgroundColor = isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSecondary.withValues(alpha: 0.5);
        textColor = isDark ? AppColors.darkTextDisabled : AppColors.lightTextSecondary;
        label = 'Borrador';
        break;
      case CropStatus.activa:
        backgroundColor = isDark
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.successLight;
        textColor = isDark ? AppColors.darkTertiary : AppColors.success;
        label = 'Activa';
        break;
      case CropStatus.pausada:
        backgroundColor = isDark
            ? AppColors.warning.withValues(alpha: 0.2)
            : AppColors.warningLight;
        textColor = isDark ? const Color(0xFFFFB74D) : AppColors.warning;
        label = 'Pausada';
        break;
      case CropStatus.agotada:
        backgroundColor = isDark
            ? AppColors.error.withValues(alpha: 0.2)
            : AppColors.errorLight;
        textColor = isDark ? const Color(0xFFEF9A9A) : AppColors.error;
        label = 'Agotada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
