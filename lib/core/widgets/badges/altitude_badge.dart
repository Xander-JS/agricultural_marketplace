import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A reusable badge to display altitude over images
class AltitudeBadge extends StatelessWidget {
  final String text;

  const AltitudeBadge({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.landscape_outlined,
            size: 14,
            color: AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
