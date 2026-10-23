import 'package:flutter/cupertino.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../brand/kus_brand_logo.dart';

/// Brand loader for the [AppLoading] stage: the KUS mark with an iOS
/// activity indicator beneath it while [isSpinning].
///
/// When idle the indicator's slot stays reserved, so text below the mark
/// never jumps when work finishes, and no animation keeps running.
class LoadingIndicator extends StatelessWidget {
  final bool isSpinning;

  /// Draws on the full-bleed brand stage (light marks). Set to false to use
  /// the regular surface colors.
  final bool onBrandStage;

  const LoadingIndicator({
    super.key,
    this.isSpinning = true,
    this.onBrandStage = true,
  });

  // Mark + gap + indicator = 80px, the loader's footprint across the app.
  static const double _markSize = 56;
  static const double _indicatorRadius = 8;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = onBrandStage
        ? AppColors.onBrand
        : context.appPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KusBrandLogo(
          variant: KusBrandLogoVariant.hero,
          markSize: _markSize,
          showWordmark: false,
          onBrandStage: onBrandStage,
          animateEntrance: true,
        ),
        const SizedBox(height: AppDimensions.space8),
        SizedBox.square(
          dimension: _indicatorRadius * 2,
          child: isSpinning
              ? CupertinoActivityIndicator(
                  radius: _indicatorRadius,
                  color: indicatorColor,
                )
              : null,
        ),
      ],
    );
  }
}
