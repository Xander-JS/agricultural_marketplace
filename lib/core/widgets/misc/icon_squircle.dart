import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A fine-stroke icon inside a subtle squircle (10px superellipse corners),
/// the way Settings marks list rows.
///
/// Without a [triad] it uses the neutral [AppThemeColors.appIconTriad]:
/// slate glyph on a faint translucent wash. Pass a semantic triad only when
/// the icon reports a real state.
class IconSquircle extends StatelessWidget {
  final IconData icon;
  final AppSemanticTriad? triad;
  final double size;
  final double? iconSize;

  const IconSquircle({
    super.key,
    required this.icon,
    this.triad,
    this.size = 44,
    this.iconSize,
  });

  static const double radius = 10;

  @override
  Widget build(BuildContext context) {
    final colors = triad ?? context.appIconTriad;

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: colors.background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius),
          side: colors.border.a == 0
              ? BorderSide.none
              : BorderSide(color: colors.border),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize ?? size * 0.48,
        color: colors.foreground,
      ),
    );
  }
}
