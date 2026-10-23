import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Short capture tip ("Buena iluminación", "Sin reflejos").
///
/// Brand triad: primarySoft fill, 1px border, forest/emerald text and icon.
class TipPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const TipPill({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final triad = context.appBrandTriad;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8 - 1,
      ),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: AppDimensions.borderRadiusFull,
        border: Border.all(color: triad.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconXS, color: triad.foreground),
          const SizedBox(width: AppDimensions.space8 - 2),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(color: triad.text),
            ),
          ),
        ],
      ),
    );
  }
}
