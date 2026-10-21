import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'personal_details_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    // The upper graphic section occupies 58% of the screen.
    final topHeight = size.height * 0.58;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          // Topographic graphic section
          SizedBox(
            height: topHeight,
            width: double.infinity,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                width: double.infinity,
                height: topHeight,
                color: colors.primaryContainer,
                child: CustomPaint(
                  painter: _TopoPainter(color: context.appSuccess),
                ),
              ),
            ),
          ),

          // Lower text and action section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.space32,
                right: AppDimensions.space32,
                top: AppDimensions.space16,
                bottom: AppDimensions.space40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcome_title,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    l10n.welcome_description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Footer action area
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PersonalDetailsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.welcome_continue,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Container(
                            width: AppDimensions.space48,
                            height: AppDimensions.space48,
                            decoration: BoxDecoration(
                              color: context.appSuccess,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.appSuccess.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: AppColors.onBrand,
                              size: AppDimensions.iconSM,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _TopoPainter extends CustomPainter {
  final Color color;

  _TopoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 393;
    canvas.save();
    canvas.scale(s, s);

    final paintThick = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintThin = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(200, 240),
        width: 84,
        height: 48,
      ),
      paintThick,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(205, 242),
        width: 150,
        height: 90,
      ),
      paintThin,
    );

    canvas.drawPath(
      Path()
        ..moveTo(95, 245)
        ..cubicTo(95, 190, 315, 190, 315, 245)
        ..cubicTo(315, 300, 95, 300, 95, 245)
        ..close(),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(60, 250)
        ..cubicTo(60, 165, 350, 165, 350, 250)
        ..cubicTo(350, 335, 60, 335, 60, 250)
        ..close(),
      paintThin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-30, 110)
        ..quadraticBezierTo(110, 70, 196, 110)
        ..quadraticBezierTo(282, 150, 420, 110),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 140)
        ..quadraticBezierTo(110, 100, 200, 140)
        ..quadraticBezierTo(290, 180, 420, 135),
      paintThin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 170)
        ..quadraticBezierTo(110, 130, 200, 170)
        ..quadraticBezierTo(290, 210, 410, 165),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(230, -20)
        ..cubicTo(270, 40, 370, 40, 420, -10),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(200, -30)
        ..cubicTo(250, 70, 390, 70, 430, -20),
      paintThin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(170, -40)
        ..cubicTo(230, 100, 410, 100, 440, -10),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 310)
        ..cubicTo(60, 310, 120, 380, 180, 360)
        ..cubicTo(260, 340, 320, 400, 410, 360),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 340)
        ..cubicTo(50, 340, 130, 420, 200, 390)
        ..cubicTo(270, 360, 330, 430, 420, 390),
      paintThin,
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 220)
        ..cubicTo(15, 160, 80, 120, 130, 140)
        ..cubicTo(180, 160, 160, 220, 100, 240)
        ..cubicTo(60, 250, 40, 240, 30, 220)
        ..close(),
      paintThick,
    );
    canvas.drawPath(
      Path()
        ..moveTo(250, 270)
        ..cubicTo(220, 300, 240, 360, 300, 370)
        ..cubicTo(360, 380, 390, 320, 370, 280)
        ..cubicTo(350, 240, 280, 240, 250, 270)
        ..close(),
      paintThick,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
