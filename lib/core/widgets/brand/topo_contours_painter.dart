import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// KUS official background texture: an aerial "field plots" mosaic evoking
/// irregular farm plots seen from above.
///
/// The default constructor renders the full-bleed green brand stage: a flat
/// `#14532F` base fill covered by 3 staggered rows of rounded rectangles
/// (corner radius ~6px, gap ~6px) in subtle tonal variations (`#155430`,
/// `#165632`, `#175834`, `#185A33`, `#1A5F37`), rotated -18° around the
/// center and oversized so no empty corners appear at any widget size.
///
/// [TopoContoursPainter.card] renders the same 3-row staggered mosaic as a
/// subtle micro-texture over regular card surfaces using faint alphas of
/// [color] (typically `context.appPrimarySoft`), preserving WCAG AAA text
/// contrast.
class TopoContoursPainter extends CustomPainter {
  /// Base flat green fill (`#14532F`).
  static const Color baseColor = Color(0xFF14532F);

  /// Subtle plot palette (`#155430`, `#165632`, `#175834`, `#185A33`, `#1A5F37`).
  static const Color _c0 = Color(0xFF155430);
  static const Color _c1 = Color(0xFF165632);
  static const Color _c2 = Color(0xFF175834);
  static const Color _c3 = Color(0xFF185A33);
  static const Color _c4 = Color(0xFF1A5F37);

  /// Subtle alpha steps for [TopoContoursPainter.card] micro-texture.
  static const double _a0 = 0.16;
  static const double _a1 = 0.22;
  static const double _a2 = 0.28;
  static const double _a3 = 0.34;
  static const double _a4 = 0.42;

  static const double _cornerRadius = 6.0;
  static const double _gap = 6.0;
  static const double _rotationRadians = -18.0 * math.pi / 180.0;
  static const double _cos18 = 0.9510565162951535;
  static const double _sin18 = 0.3090169943749474;

  /// Three staggered rows of irregular-width plots.
  /// Every plot in a row has a distinct width fraction, seams are staggered
  /// across adjacent rows, and no two adjacent plots (horizontally or
  /// vertically across seams) share the same color or alpha step.
  static const List<List<_PlotSpec>> _rows = [
    [
      _PlotSpec(0.16, _c0, _a0),
      _PlotSpec(0.24, _c2, _a2),
      _PlotSpec(0.18, _c4, _a4),
      _PlotSpec(0.25, _c1, _a1),
      _PlotSpec(0.17, _c3, _a3),
    ],
    [
      _PlotSpec(0.23, _c3, _a3),
      _PlotSpec(0.14, _c1, _a1),
      _PlotSpec(0.26, _c0, _a0),
      _PlotSpec(0.15, _c4, _a4),
      _PlotSpec(0.22, _c2, _a2),
    ],
    [
      _PlotSpec(0.12, _c1, _a1),
      _PlotSpec(0.20, _c4, _a4),
      _PlotSpec(0.21, _c2, _a2),
      _PlotSpec(0.19, _c3, _a3),
      _PlotSpec(0.28, _c0, _a0),
    ],
  ];

  final Color color;
  final double intensity;
  final bool isCardTexture;

  const TopoContoursPainter({
    this.color = const Color(0xFFFFFFFF),
    this.intensity = 1.0,
  }) : isCardTexture = false;

  const TopoContoursPainter.card({
    required this.color,
    this.intensity = 1.0,
  }) : isCardTexture = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (!isCardTexture) {
      final basePaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, basePaint);
    }

    // Oversize the rotated mosaic so all four corners of [size] are covered
    // after rotating -18° around the center.
    final rotatedBoundsWidth = size.width * _cos18 + size.height * _sin18;
    final rotatedBoundsHeight = size.height * _cos18 + size.width * _sin18;
    final mosaicWidth = rotatedBoundsWidth * 1.16 + 24.0;
    final mosaicHeight = rotatedBoundsHeight * 1.16 + 24.0;

    canvas.translate(size.width / 2.0, size.height / 2.0);
    canvas.rotate(_rotationRadians);

    final rowCount = _rows.length;
    final totalVerticalGaps = _gap * (rowCount - 1);
    final rowHeight = math.max(
      12.0,
      (mosaicHeight - totalVerticalGaps) / rowCount,
    );

    const radius = Radius.circular(_cornerRadius);
    final plotPaint = Paint()..style = PaintingStyle.fill;

    var y = -mosaicHeight / 2.0;
    for (var r = 0; r < rowCount; r++) {
      final row = _rows[r];
      final totalHorizontalGaps = _gap * (row.length - 1);
      final availableWidth = math.max(
        row.length * 12.0,
        mosaicWidth - totalHorizontalGaps,
      );

      var x = -mosaicWidth / 2.0;
      for (var i = 0; i < row.length; i++) {
        final spec = row[i];
        final plotWidth = availableWidth * spec.widthFraction;
        plotPaint.color = isCardTexture
            ? color.withValues(alpha: (spec.alpha * intensity).clamp(0.0, 1.0))
            : spec.color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, plotWidth, rowHeight),
            radius,
          ),
          plotPaint,
        );
        x += plotWidth + _gap;
      }
      y += rowHeight + _gap;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TopoContoursPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.intensity != intensity ||
      oldDelegate.isCardTexture != isCardTexture;
}

class _PlotSpec {
  final double widthFraction;
  final Color color;
  final double alpha;

  const _PlotSpec(this.widthFraction, this.color, this.alpha);
}
