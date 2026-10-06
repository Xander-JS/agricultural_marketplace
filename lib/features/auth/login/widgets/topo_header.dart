import 'package:flutter/material.dart';
import 'dart:math' as math;

class TopoHeader extends StatelessWidget {
  const TopoHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderWaveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB8EDBE),
              Color(0xFFCBF3D0),
              Color(0xFFE6F8E4),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _TopoPainter(
            color: const Color(0xFF04894D),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final waveHeight = 68.0;
    final startY = math.max(0.0, size.height - waveHeight);
    
    path.lineTo(0, startY);
    path.cubicTo(
      size.width * (120/393), startY,
      size.width * (165/393), size.height - 2,
      size.width, startY,
    );
    path.lineTo(size.width, 0);
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
    final scaleX = size.width / 393.0;
    final scaleY = size.height / 360.0;
    canvas.scale(scaleX, scaleY);

    void drawPath(Path path, double opacity, double strokeWidth) {
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawPath(path, paint);
    }

    void drawRotatedEllipse(double cx, double cy, double rx, double ry, double opacity, double strokeWidth, double angleDeg) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angleDeg * math.pi / 180.0);
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), paint);
      canvas.restore();
    }

    // Path 1
    final p1 = Path()..moveTo(-20, 40)..quadraticBezierTo(60, 10, 140, 50)..quadraticBezierTo(220, 90, 300, 30)..quadraticBezierTo(380, -30, 420, 80);
    drawPath(p1, 0.3, 1.2);

    // Path 2
    final p2 = Path()..moveTo(-30, 80)..quadraticBezierTo(70, 40, 160, 95)..quadraticBezierTo(250, 150, 320, 60)..quadraticBezierTo(390, -30, 430, 120);
    drawPath(p2, 0.35, 1.2);

    // Path 3
    final p3 = Path()..moveTo(-20, 130)..quadraticBezierTo(90, 90, 190, 140)..quadraticBezierTo(290, 190, 350, 110)..quadraticBezierTo(410, 30, 430, 170);
    drawPath(p3, 0.4, 1.4);

    // Path 4
    final p4 = Path()..moveTo(-10, 180)..quadraticBezierTo(100, 140, 210, 190)..quadraticBezierTo(320, 240, 370, 160)..quadraticBezierTo(420, 80, 430, 220);
    drawPath(p4, 0.45, 1.4);

    // Path 5
    final p5 = Path()..moveTo(-10, 230)..quadraticBezierTo(120, 190, 230, 240)..quadraticBezierTo(340, 290, 380, 210)..quadraticBezierTo(420, 130, 440, 270);
    drawPath(p5, 0.5, 1.5);

    // Center loops
    drawRotatedEllipse(290, 190, 90, 50, 0.3, 1.2, -15);
    drawRotatedEllipse(290, 190, 65, 35, 0.35, 1.2, -15);
    drawRotatedEllipse(290, 190, 40, 20, 0.4, 1.4, -15);
    drawRotatedEllipse(290, 190, 18, 9, 0.45, 1.5, -15);

    // Left loops
    drawRotatedEllipse(80, 100, 70, 40, 0.25, 1.2, 10);
    drawRotatedEllipse(80, 100, 45, 25, 0.3, 1.2, 10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
