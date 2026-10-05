import 'package:flutter/material.dart';

class LoadingIndicator extends StatefulWidget {
  final bool isSpinning;

  const LoadingIndicator({Key? key, this.isSpinning = true}) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset(
      'assets/images/logo_lg.png',
      width: 80,
      height: 80,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.eco, color: Colors.white, size: 80),
    );

    if (widget.isSpinning) {
      return RotationTransition(
        turns: _controller,
        child: logo,
      );
    }
    return logo;
  }
}
