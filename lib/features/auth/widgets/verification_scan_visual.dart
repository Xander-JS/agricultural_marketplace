import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../core/widgets/scanner/scanner_viewfinder.dart';

/// Working state for account processing on the brand stage: the KUS mark
/// inside scanner brackets, crossed by a scan line that travels while the
/// documents and selfie are being sent.
///
/// The line is constant motion tied to real work, so it runs only while
/// this widget is mounted (the parent swaps it out when work stops) and is
/// omitted under Reduce Motion, leaving the bracketed mark.
class VerificationScanVisual extends StatefulWidget {
  const VerificationScanVisual({super.key});

  @override
  State<VerificationScanVisual> createState() => _VerificationScanVisualState();
}

class _VerificationScanVisualState extends State<VerificationScanVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  static const double _size = 168;
  static const double _radius = 32;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!AppMotion.reduced(context)) _scan.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduced = AppMotion.reduced(context);

    return Semantics(
      label: l10n?.loading_skeleton_semantics,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: _size,
        child: CustomPaint(
          foregroundPainter: CornerBracketsPainter(
            color: AppColors.onBrand,
            radius: _radius,
            arm: 22,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.onBrand.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: AppColors.onBrand.withValues(alpha: 0.14),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const KusBrandLogo(
                    variant: KusBrandLogoVariant.hero,
                    markSize: 84,
                    showWordmark: false,
                    onBrandStage: true,
                  ),
                  if (!reduced)
                    AnimatedBuilder(
                      animation: _scan,
                      // Travels between the top and bottom brackets.
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          (_size / 2 - 22) *
                              (AppMotion.easeInOut.transform(_scan.value) * 2 -
                                  1),
                        ),
                        child: child,
                      ),
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppDimensions.borderRadiusFull,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.onBrand.withValues(alpha: 0),
                              AppColors.onBrand,
                              AppColors.onBrand,
                              AppColors.onBrand.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.2, 0.8, 1],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
