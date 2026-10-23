import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../misc/pressable_scale.dart';

/// One option in a small exclusive selector (delivery method and similar):
/// icon over a short label, filled with the brand soft tone when chosen.
class ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final triad = context.appBrandTriad;
    final duration = AppMotion.of(context, AppMotion.standard);
    final foreground = selected ? triad.foreground : context.appTextSecondary;

    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.easeOut,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? triad.background : context.appSurfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? triad.border : AppColors.transparent,
                width: AppDimensions.borderWidthMedium,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: selected ? triad.foreground : context.appTextPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
