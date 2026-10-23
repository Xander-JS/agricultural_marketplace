import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand/topo_contours_painter.dart';

/// Wallet-style summary surface: the deep forest brand stage with faint
/// Nariño contour lines, for the one figure a screen is about.
///
/// Content placed here uses [AppColors.onBrand] / [AppColors.onBrandSecondary],
/// which keep AAA contrast on the stage in both themes.
class CostWalletPanel extends StatelessWidget {
  final Widget child;

  const CostWalletPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appBrandStage,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: context.appShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: TopoContoursPainter(
                    color: AppColors.onBrand,
                    intensity: 0.12,
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ),
      ),
    );
  }
}
