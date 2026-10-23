import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';

/// Floating label that straddles the top edge of a scanner frame.
///
/// [guide] uses the strict `primary`/`onPrimary` pair; [captured] switches
/// to the success triad once the user's own photo is in place.
class ScannerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool captured;

  const ScannerChip.guide({
    super.key,
    required this.label,
    this.icon = LucideIcons.scanLine,
  }) : captured = false;

  const ScannerChip.captured({
    super.key,
    required this.label,
    this.icon = LucideIcons.circleCheck,
  }) : captured = true;

  @override
  Widget build(BuildContext context) {
    final triad = context.appSuccessTriad;
    final fill = captured ? triad.background : context.appPrimary;
    final border = captured ? triad.border : context.appPrimary;
    final foreground = captured ? triad.text : context.appOnPrimary;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppDimensions.borderRadiusFull,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: captured ? triad.foreground : foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Document scanner frame in the manner of Apple Wallet's card scanner.
///
/// A `surfaceVariant` well with a 1.5px hairline, rounded corner brackets
/// in the brand color and a [chip] floating across the top edge. Until
/// [captured], the [child] (a framing guide) sits inset and a single scan
/// line sweeps it once to show where the document goes. Once captured, the
/// child (the user's photo) fills the well edge to edge.
class ScannerViewfinder extends StatefulWidget {
  final Widget child;
  final Widget chip;
  final bool captured;
  final double aspectRatio;

  const ScannerViewfinder({
    super.key,
    required this.child,
    required this.chip,
    this.captured = false,
    this.aspectRatio = 1.48,
  });

  static const double radius = 20;

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with SingleTickerProviderStateMixin {
  // Explanatory, seen once per capture step: slower than UI feedback.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.captured && !AppMotion.reduced(context)) {
      _sweep.forward();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.emphasized);
    final bracket = widget.captured
        ? context.appSuccessTriad.foreground
        : context.appPrimary;

    final well = AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: CustomPaint(
        foregroundPainter: CornerBracketsPainter(
          color: bracket,
          radius: ScannerViewfinder.radius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.appSurfaceVariant,
            borderRadius: BorderRadius.circular(ScannerViewfinder.radius),
            border: Border.all(
              color: context.appBorder,
              width: AppDimensions.borderWidthMedium,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ScannerViewfinder.radius - AppDimensions.borderWidthMedium,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: AppMotion.easeOut,
                  switchOutCurve: AppMotion.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey(widget.captured),
                    child: Padding(
                      padding: widget.captured
                          ? EdgeInsets.zero
                          : const EdgeInsets.fromLTRB(14, 26, 14, 12),
                      child: widget.child,
                    ),
                  ),
                ),
                if (!widget.captured)
                  IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) => AnimatedBuilder(
                        animation: _sweep,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _ScanLine(color: context.appPrimary),
                        ),
                        builder: (context, child) {
                          if (!_sweep.isAnimating) {
                            return const SizedBox.shrink();
                          }
                          final progress = _sweep.value;
                          final t = AppMotion.easeInOut.transform(progress);
                          // Fade in over the first tenth, out over the last
                          // fifth; travel stays inside the well's padding.
                          final opacity = math.min(
                            (progress / 0.1).clamp(0.0, 1.0),
                            ((1 - progress) / 0.2).clamp(0.0, 1.0),
                          );
                          final travel = constraints.maxHeight;
                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                travel * (0.08 + 0.84 * t) - _ScanLine.height,
                              ),
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(padding: const EdgeInsets.only(top: 15), child: well),
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(widget.captured),
            child: widget.chip,
          ),
        ),
      ],
    );
  }
}

/// The sweeping line with a short trail above it showing the direction of
/// travel. Positioned by its parent with a transform.
class _ScanLine extends StatelessWidget {
  final Color color;

  static const double height = 24;

  const _ScanLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0),
                    color.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: AppDimensions.borderRadiusFull,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0),
                  color,
                  color,
                  color.withValues(alpha: 0),
                ],
                stops: const [0, 0.18, 0.82, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four rounded L-brackets drawn on the frame's own corner radius, so they
/// read as a lit portion of the border rather than a separate overlay.
class CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double arm;

  static const double strokeWidth = 3;

  const CornerBracketsPainter({
    required this.color,
    required this.radius,
    this.arm = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final inset = strokeWidth / 2;
    final r = radius - inset;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    Path corner(Offset start, Offset arcCorner, double startAngle, Offset end) {
      // arcTo draws the straight run from [start] to the arc on its own.
      return Path()
        ..moveTo(start.dx, start.dy)
        ..arcTo(
          Rect.fromCircle(center: arcCorner, radius: r),
          startAngle,
          math.pi / 2,
          false,
        )
        ..lineTo(end.dx, end.dy);
    }

    // Top-left: from down the left edge, around the corner, along the top.
    canvas.drawPath(
      corner(
        Offset(rect.left, rect.top + r + arm),
        Offset(rect.left + r, rect.top + r),
        math.pi,
        Offset(rect.left + r + arm, rect.top),
      ),
      paint,
    );
    // Top-right.
    canvas.drawPath(
      corner(
        Offset(rect.right - r - arm, rect.top),
        Offset(rect.right - r, rect.top + r),
        -math.pi / 2,
        Offset(rect.right, rect.top + r + arm),
      ),
      paint,
    );
    // Bottom-right.
    canvas.drawPath(
      corner(
        Offset(rect.right, rect.bottom - r - arm),
        Offset(rect.right - r, rect.bottom - r),
        0,
        Offset(rect.right - r - arm, rect.bottom),
      ),
      paint,
    );
    // Bottom-left.
    canvas.drawPath(
      corner(
        Offset(rect.left + r + arm, rect.bottom),
        Offset(rect.left + r, rect.bottom - r),
        math.pi / 2,
        Offset(rect.left, rect.bottom - r - arm),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.arm != arm;
}

/// Face ID-style frame for the selfie step.
///
/// The photo sits in a circle with a faint emerald perimeter ring, wrapped
/// by a dial of short ticks. On first appearance the ticks light up once,
/// clockwise from the top, the way Face ID enrolment does; when [captured]
/// the whole dial turns to the success hue.
class BiometricFrame extends StatefulWidget {
  final Widget child;
  final bool captured;
  final double diameter;
  final Widget? chip;

  const BiometricFrame({
    super.key,
    required this.child,
    this.captured = false,
    this.diameter = 232,
    this.chip,
  });

  @override
  State<BiometricFrame> createState() => _BiometricFrameState();
}

class _BiometricFrameState extends State<BiometricFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dial = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.captured || AppMotion.reduced(context)) {
      _dial.value = 1;
    } else {
      _dial.forward();
    }
  }

  @override
  void dispose() {
    _dial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dialGap = 12.0;
    const tickLength = 8.0;
    final outer = widget.diameter + (dialGap + tickLength) * 2;
    // Idle ticks rest half-lit; the dial reaches full strength only when the
    // selfie is in place.
    final lit = widget.captured
        ? context.appSuccessTriad.foreground
        : context.appPrimary.withValues(alpha: 0.55);
    final duration = AppMotion.of(context, AppMotion.emphasized);

    final dial = SizedBox.square(
      dimension: outer,
      child: AnimatedBuilder(
        animation: _dial,
        builder: (context, child) => CustomPaint(
          painter: _TickDialPainter(
            progress: AppMotion.easeOut.transform(_dial.value),
            litColor: lit,
            restColor: context.appBorder,
            innerRadius: widget.diameter / 2 + dialGap,
            tickLength: tickLength,
          ),
          child: child,
        ),
        child: Center(
          child: Container(
            width: widget.diameter,
            height: widget.diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appSurfaceVariant,
              border: Border.all(
                color:
                    (widget.captured
                            ? context.appSuccessTriad.foreground
                            : context.appPrimary)
                        .withValues(alpha: 0.35),
                width: AppDimensions.borderWidthThick,
              ),
            ),
            child: ClipOval(
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeOut,
                child: KeyedSubtree(
                  key: ValueKey(widget.captured),
                  child: SizedBox.expand(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.chip == null) return dial;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        dial,
        Positioned(
          bottom: -AppDimensions.space4,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeOut,
            child: KeyedSubtree(
              key: ValueKey(widget.captured),
              child: widget.chip!,
            ),
          ),
        ),
      ],
    );
  }
}

class _TickDialPainter extends CustomPainter {
  final double progress;
  final Color litColor;
  final Color restColor;
  final double innerRadius;
  final double tickLength;

  static const int _ticks = 60;

  const _TickDialPainter({
    required this.progress,
    required this.litColor,
    required this.restColor,
    required this.innerRadius,
    required this.tickLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rest = Paint()
      ..color = restColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final on = Paint()
      ..color = litColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final litCount = (progress * _ticks).round();
    for (var i = 0; i < _ticks; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / _ticks;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * innerRadius,
        center + dir * (innerRadius + tickLength),
        i < litCount ? on : rest,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TickDialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.litColor != litColor ||
      oldDelegate.restColor != restColor ||
      oldDelegate.innerRadius != innerRadius;
}
