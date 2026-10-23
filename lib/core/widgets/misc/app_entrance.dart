import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// One-time entrance: fade, short rise and a slight settle in scale.
///
/// The [delay] is part of the animation timeline (an [Interval]), not a
/// timer, so mounting this widget never leaves pending timers behind. With
/// Reduce Motion on, the child appears immediately.
class AppEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double beginScale;

  const AppEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.entrance,
    this.offsetY = 8,
    this.beginScale = 1,
  });

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _controller.duration!.inMicroseconds == 0
          ? 0
          : widget.delay.inMicroseconds / _controller.duration!.inMicroseconds,
      1,
      curve: AppMotion.easeOut,
    ),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - t)),
            child: Transform.scale(
              scale: widget.beginScale + (1 - widget.beginScale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
