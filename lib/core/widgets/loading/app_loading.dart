import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../brand/topo_contours_painter.dart';

/// Full-bleed brand stage for blocking states (session check, account
/// processing, verification status).
///
/// Forest green falling into deep emerald (deep forest in dark mode), with
/// faint contour lines. Content placed here uses [AppColors.onBrand] tones, which
/// keep AAA contrast on both stages.
class AppLoading extends StatelessWidget {
  final Widget child;

  const AppLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.appBrandStage,
        body: Stack(
          children: [
            // Ambient depth: the auth header's forest-to-deep-emerald field,
            // so blocking states are never a flat slab of green.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: context.appAuthHeaderGradient,
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: TopoContoursPainter(
                    color: AppColors.onBrand,
                    intensity: 0.16,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space24,
                    vertical: AppDimensions.space32,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
