import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A stroked icon inside a tinted iOS squircle (continuous corners at
/// ~30% of the side), the way Settings and Wallet mark list rows.
class IconSquircle extends StatelessWidget {
  final IconData icon;
  final AppSemanticTriad triad;
  final double size;
  final double? iconSize;

  const IconSquircle({
    super.key,
    required this.icon,
    required this.triad,
    this.size = 44,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: triad.background,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.6),
          side: BorderSide(color: triad.border),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize ?? size * 0.48, color: triad.foreground),
    );
  }
}
