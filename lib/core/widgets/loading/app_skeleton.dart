import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';

/// Shimmer wrapper with KUS colors.
///
/// Paint skeleton shapes ([AppSkeletonBlock]) inside [child]; the sweep
/// replaces their fill. Set [onBrandStage] for skeletons drawn over the
/// full-bleed brand ground. The sweep stops when [enabled] is false or when
/// the platform asks for reduced motion, leaving static placeholders.
class AppShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final bool onBrandStage;

  const AppShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.onBrandStage = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = onBrandStage
        ? AppColors.onBrand.withValues(alpha: 0.14)
        : context.appSkeletonBase;
    final highlight = onBrandStage
        ? AppColors.onBrand.withValues(alpha: 0.30)
        : context.appSkeletonHighlight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: AppMotion.shimmerPeriod,
      enabled: enabled && !AppMotion.reduced(context),
      child: child,
    );
  }
}

/// A flat placeholder shape at the real size of the content it stands for.
class AppSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const AppSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = AppDimensions.radiusXS,
  }) : circle = false;

  const AppSkeletonBlock.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 0,
      circle = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Any opaque fill: the shimmer shader replaces it.
        color: AppColors.onBrand,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
