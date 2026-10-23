import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand/topo_contours_painter.dart';

/// Stand-in for a lot without a photo: the soft variant ground with KUS's
/// Nariño contour lines and a muted "no image" mark, so an empty slot still
/// reads as part of the product instead of a gray hole.
class CropPhotoPlaceholder extends StatelessWidget {
  final double iconSize;

  const CropPhotoPlaceholder({super.key, this.iconSize = 32});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appSurfaceVariant,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: TopoContoursPainter(
                color: context.appTextMuted,
                intensity: 0.45,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: iconSize,
              color: context.appTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
