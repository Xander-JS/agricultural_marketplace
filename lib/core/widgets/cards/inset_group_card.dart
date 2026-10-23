import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// iOS inset grouped container: `surface` ground, 20px radius and a single
/// 1px `border` hairline. Elevation comes from the hairline alone, never a
/// shadow, so the card sits flat on the grouped background.
class InsetGroupCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  static const double radius = 20;

  const InsetGroupCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.color,
    this.borderColor,
    this.borderWidth = AppDimensions.borderWidthThin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.appSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? context.appBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}
