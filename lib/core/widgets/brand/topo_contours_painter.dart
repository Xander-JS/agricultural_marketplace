import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// KUS signature texture: hand-placed contour lines evoking the Nariño
/// highlands where the crops are grown.
///
/// Drawn on a 393x360 design canvas and scaled to the paint size. Line
/// opacity is multiplied by [intensity] so the same contours can sit quietly
/// behind type or read clearly on a header.
class TopoContoursPainter extends CustomPainter {
  final Color color;
  final double intensity;

  const TopoContoursPainter({required this.color, this.intensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 393.0, size.height / 360.0);

    Paint stroke(double opacity, double width) => Paint()
      ..color = color.withValues(alpha: (opacity * intensity).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void ellipse(
      double cx,
      double cy,
      double rx,
      double ry,
      double opacity,
      double width,
      double angleDeg,
    ) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angleDeg * math.pi / 180.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        stroke(opacity, width),
      );
      canvas.restore();
    }

    canvas.drawPath(
      Path()
        ..moveTo(-20, 40)
        ..quadraticBezierTo(60, 10, 140, 50)
        ..quadraticBezierTo(220, 90, 300, 30)
        ..quadraticBezierTo(380, -30, 420, 80),
      stroke(0.30, 1.2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-30, 80)
        ..quadraticBezierTo(70, 40, 160, 95)
        ..quadraticBezierTo(250, 150, 320, 60)
        ..quadraticBezierTo(390, -30, 430, 120),
      stroke(0.35, 1.2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-20, 130)
        ..quadraticBezierTo(90, 90, 190, 140)
        ..quadraticBezierTo(290, 190, 350, 110)
        ..quadraticBezierTo(410, 30, 430, 170),
      stroke(0.40, 1.4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 180)
        ..quadraticBezierTo(100, 140, 210, 190)
        ..quadraticBezierTo(320, 240, 370, 160)
        ..quadraticBezierTo(420, 80, 430, 220),
      stroke(0.45, 1.4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, 230)
        ..quadraticBezierTo(120, 190, 230, 240)
        ..quadraticBezierTo(340, 290, 380, 210)
        ..quadraticBezierTo(420, 130, 440, 270),
      stroke(0.50, 1.5),
    );

    ellipse(290, 190, 90, 50, 0.30, 1.2, -15);
    ellipse(290, 190, 65, 35, 0.35, 1.2, -15);
    ellipse(290, 190, 40, 20, 0.40, 1.4, -15);
    ellipse(290, 190, 18, 9, 0.45, 1.5, -15);

    ellipse(80, 100, 70, 40, 0.25, 1.2, 10);
    ellipse(80, 100, 45, 25, 0.30, 1.2, 10);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TopoContoursPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.intensity != intensity;
}
