import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A reusable badge for status like 'Preventa' or 'Listo para despacho'
class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    Key? key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  }) : super(key: key);

  /// Factory for 'Preventa' status (Orange)
  factory StatusBadge.preventa({required String text}) {
    return StatusBadge(
      text: text,
      backgroundColor: const Color(0xFFFDE8E0), // Based on mockup orange tint
      textColor: const Color(0xFFC04F15), // Based on mockup orange text
      icon: Icons.circle,
    );
  }

  /// Factory for 'Listo para despacho' status (Green)
  factory StatusBadge.ready({required String text}) {
    return StatusBadge(
      text: text,
      backgroundColor: const Color(0xFFE9F5E9), // Based on mockup green tint
      textColor: const Color(0xFF2E7D32), // Based on mockup green text
      icon: Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 6),
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
