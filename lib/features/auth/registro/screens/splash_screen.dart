import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/brand/topo_contours_painter.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Hold the brand moment, then hand off to Welcome.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduced = AppMotion.reduced(context);

    Widget slogan = Text(
      l10n?.brand_slogan ?? '',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.onBrandSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
    if (!reduced) {
      slogan = slogan
          .animate()
          .fadeIn(
            delay: 260.ms,
            duration: AppMotion.entrance,
            curve: AppMotion.easeOut,
          )
          .moveY(
            begin: 6,
            end: 0,
            delay: 260.ms,
            duration: AppMotion.entrance,
            curve: AppMotion.easeOut,
          );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.appBrandStage,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(
              painter: TopoContoursPainter(
                color: AppColors.onBrand,
                intensity: 0.16,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space32,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    const KusBrandLogo.hero(onBrandStage: true),
                    const SizedBox(height: AppDimensions.space24),
                    slogan,
                    const Spacer(flex: 4),
                    const CupertinoActivityIndicator(
                      radius: 10,
                      color: AppColors.onBrand,
                    ),
                    const SizedBox(height: AppDimensions.space32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
