import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../brand/topo_contours_painter.dart';

/// iOS inset grouped container: `surface` ground, 20px radius and a single
/// 1px `border` hairline. Elevation comes from the hairline alone, never a
/// shadow, so the card sits flat on the grouped background.
///
/// When [showMosaic] is `true`, renders the subtle field-plots mosaic over
/// the card surface using `primarySoft` at low opacity so text and figures
/// retain full WCAG contrast.
class InsetGroupCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final bool showMosaic;

  static const double radius = 20;

  const InsetGroupCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.color,
    this.borderColor,
    this.borderWidth = AppDimensions.borderWidthThin,
    this.showMosaic = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        color: color ?? context.appSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? context.appBorder,
          width: borderWidth,
        ),
      ),
      clipBehavior: showMosaic ? Clip.antiAlias : Clip.none,
      child: showMosaic
          ? CustomPaint(
              painter: TopoContoursPainter.card(
                color: context.appPrimarySoft,
                intensity: context.appIsDark ? 0.45 : 0.85,
              ),
              child: content,
            )
          : content,
    );
  }
}
