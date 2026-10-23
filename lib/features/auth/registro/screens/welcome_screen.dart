import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/brand/topo_contours_painter.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import 'personal_details_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    // The contour field occupies just over half of the screen.
    final topHeight = size.height * 0.54;
    final reduced = AppMotion.reduced(context);

    // Copy settles in after the mark: 60ms apart, one short rise each.
    Widget enter(Widget child, int order) {
      if (reduced) return child;
      final delay = (180 + order * 60).ms;
      return child
          .animate()
          .fadeIn(
            delay: delay,
            duration: AppMotion.entrance,
            curve: AppMotion.easeOut,
          )
          .moveY(
            begin: 10,
            end: 0,
            delay: delay,
            duration: AppMotion.entrance,
            curve: AppMotion.easeOut,
          );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          SizedBox(
            height: topHeight,
            width: double.infinity,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: ColoredBox(
                color: context.appPrimarySoft,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: TopoContoursPainter(
                        color: context.appPrimary,
                        intensity: context.appIsDark ? 0.55 : 0.75,
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 96),
                        child: const Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: KusBrandLogo.hero(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space24,
                  AppDimensions.space8,
                  AppDimensions.space24,
                  AppDimensions.space24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    enter(
                      Text(
                        l10n.welcome_title,
                        style: AppTextStyles.displayLarge.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                      0,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    enter(
                      Text(
                        l10n.brand_slogan,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: context.appPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      1,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    enter(
                      Text(
                        l10n.welcome_description,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      2,
                    ),
                    const Spacer(),
                    enter(
                      PrimaryActionButton(
                        text: l10n.welcome_continue,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PersonalDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final path = Path();

    double x(double val) => val * (w / 393);
    double y(double val) => h - 130 + val;

    path.lineTo(0, y(0));
    path.cubicTo(x(30), y(0), x(80), y(4), x(125), y(28));
    path.cubicTo(x(175), y(54), x(220), y(118), x(285), y(122));
    path.cubicTo(x(325), y(124), x(365), y(95), x(393), y(72));
    path.lineTo(w, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
