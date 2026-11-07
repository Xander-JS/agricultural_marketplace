import 'package:flutter/cupertino.dart';

import '../../theme/app_colors.dart';

/// Brand loader for the [AppLoading] stage: a prominent iOS activity
/// indicator while [isSpinning].
///
/// When idle the indicator's slot stays reserved, so text below the spinner
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

  static const double _indicatorRadius = 22;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = onBrandStage
        ? AppColors.onBrand
        : context.appPrimary;

    return SizedBox.square(
      dimension: _indicatorRadius * 2,
      child: isSpinning
          ? CupertinoActivityIndicator(
              radius: _indicatorRadius,
              color: indicatorColor,
            )
          : null,
    );
  }
}
