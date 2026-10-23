import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/brand/topo_contours_painter.dart';

/// Auth header: a deep forest field falling into dark emerald, traced with
/// the Nariño contour lines and closed by a soft wave.
///
/// Carries the KUS lockup on the brand stage (white mark and type, AAA on
/// both gradient stops). The lockup is centered in the band between the
/// status bar and the wave so it never collides with a back button placed
/// top-left by the screen. [compact] swaps the hero lockup for the header
/// size on task screens (password recovery) where the form leads.
class TopoHeader extends StatelessWidget {
  final bool showLogo;
  final bool compact;

  const TopoHeader({super.key, this.showLogo = true, this.compact = false});

  static const double _waveHeight = AppDimensions.space48;

  /// Height for the [compact] header: the status bar plus a band that fits
  /// the header lockup above the wave.
  static double compactHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 132;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    final Widget logo = compact
        ? const KusBrandLogo(
            variant: KusBrandLogoVariant.header,
            onBrandStage: true,
            animateEntrance: true,
          )
        : const KusBrandLogo.hero(onBrandStage: true);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: ClipPath(
        clipper: _HeaderWaveClipper(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: context.appAuthHeaderGradient,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(
                painter: TopoContoursPainter(
                  color: AppColors.onBrand,
                  intensity: 0.22,
                ),
              ),
              if (showLogo)
                Padding(
                  padding: EdgeInsets.only(
                    top: topInset + AppDimensions.space8,
                    bottom: _waveHeight * 0.7,
                    left: AppDimensions.space24,
                    right: AppDimensions.space24,
                  ),
                  child: Center(
                    child: FittedBox(fit: BoxFit.scaleDown, child: logo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const waveHeight = TopoHeader._waveHeight;
    final startY = math.max(0.0, size.height - waveHeight);

    path.lineTo(0, startY);
    path.cubicTo(
      size.width * (120 / 393),
      startY,
      size.width * (165 / 393),
      size.height - 2,
      size.width,
      startY,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
