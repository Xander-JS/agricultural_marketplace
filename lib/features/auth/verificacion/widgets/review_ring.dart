import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';

/// Perimeter ring around the KUS mark that shows where the account stands on
/// the real review path. It is split into one arc per stage: completed
/// stages are solid, the current stage is drawn in harvest amber, and stages
/// still ahead stay as a faint track.
///
/// Only the current arc moves: it draws in once when the screen appears, so
/// the ring explains "this is the step in progress" without an endless loop.
class ReviewRing extends StatefulWidget {
  /// Index of the stage in progress. A value equal to [stageCount] marks
  /// every stage as complete.
  final int stage;
  final int stageCount;
  final double size;
  final String semanticsLabel;
  final Widget child;

  const ReviewRing({
    super.key,
    required this.stage,
    required this.semanticsLabel,
    required this.child,
    this.stageCount = 3,
    this.size = 176,
  });

  @override
  State<ReviewRing> createState() => _ReviewRingState();
}

class _ReviewRingState extends State<ReviewRing>
    with SingleTickerProviderStateMixin {
  // Rare, explanatory moment (seen once per visit): longer than UI feedback
  // so the eye can follow the arc, still well under a second.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ReviewRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refresh that advances the stage replays the draw for the new step.
    if (oldWidget.stage != widget.stage && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      container: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _ReviewRingPainter(
            stage: widget.stage,
            stageCount: widget.stageCount,
            sweep: _sweep,
            track: AppColors.onBrand.withValues(alpha: 0.16),
            done: AppColors.onBrand,
            // Harvest amber keeps >5:1 on both brand stages; the lighter
            // tone is used in both modes for that reason.
            current: AppColors.darkHarvestAmber,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _ReviewRingPainter extends CustomPainter {
  final int stage;
  final int stageCount;
  final Animation<double> sweep;
  final Color track;
  final Color done;
  final Color current;

  _ReviewRingPainter({
    required this.stage,
    required this.stageCount,
    required this.sweep,
    required this.track,
    required this.done,
    required this.current,
  }) : super(repaint: sweep);

  static const double _stroke = 4;
  static const double _gapDegrees = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - _stroke,
    );
    final gap = _gapDegrees * math.pi / 180;
    final arc = (2 * math.pi - gap * stageCount) / stageCount;

    Paint paintFor(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < stageCount; i++) {
      // First arc starts at 12 o'clock, offset by half a gap so the gaps sit
      // symmetrically around the top.
      final start = -math.pi / 2 + gap / 2 + i * (arc + gap);
      canvas.drawArc(rect, start, arc, false, paintFor(track));
      if (i < stage) {
        canvas.drawArc(rect, start, arc, false, paintFor(done));
      } else if (i == stage) {
        final t = sweep.value;
        if (t > 0) {
          canvas.drawArc(rect, start, arc * t, false, paintFor(current));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReviewRingPainter old) =>
      old.stage != stage ||
      old.stageCount != stageCount ||
      old.track != track ||
      old.done != done ||
      old.current != current;
}

/// Stage names under the ring, aligned with the arcs above. Sentence case,
/// no numbering: the order is carried by position and the icons.
class ReviewStageList extends StatelessWidget {
  final int stage;
  final List<String> labels;
  final String currentLabel;

  const ReviewStageList({
    super.key,
    required this.stage,
    required this.labels,
    required this.currentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: _StageRow(
              label: labels[i],
              state: i < stage
                  ? _StageState.done
                  : i == stage
                  ? _StageState.current
                  : _StageState.ahead,
              currentLabel: currentLabel,
            ),
          ),
      ],
    );
  }
}

enum _StageState { done, current, ahead }

class _StageRow extends StatelessWidget {
  final String label;
  final _StageState state;
  final String currentLabel;

  const _StageRow({
    required this.label,
    required this.state,
    required this.currentLabel,
  });

  @override
  Widget build(BuildContext context) {
    const amber = AppColors.darkHarvestAmber;
    final Widget marker = switch (state) {
      _StageState.done => Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.onBrand,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 14,
          color: context.appBrandStage,
        ),
      ),
      _StageState.current => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: amber, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: amber, shape: BoxShape.circle),
        ),
      ),
      _StageState.ahead => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.onBrand.withValues(alpha: 0.36),
            width: 1.5,
          ),
        ),
      ),
    };

    final isCurrent = state == _StageState.current;
    return Row(
      children: [
        marker,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: state == _StageState.ahead
                  ? AppColors.onBrand.withValues(alpha: 0.72)
                  : AppColors.onBrand,
            ),
          ),
        ),
        if (isCurrent)
          Text(
            currentLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: amber,
            ),
          ),
      ],
    );
  }
}
