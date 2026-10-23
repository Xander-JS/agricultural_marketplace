import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// Scales its child down slightly while a pointer is pressed.
///
/// Uses a [Listener], so it never competes in the gesture arena with the
/// button or detector it wraps. The press is quick and the release a bit
/// slower; [AnimatedScale] retargets mid-flight, so rapid taps never restart
/// from zero.
class PressableScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = AppMotion.pressedScale,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant PressableScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(
      context,
      _pressed ? AppMotion.press : AppMotion.release,
    );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: duration,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
