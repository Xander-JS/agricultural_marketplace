import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

class LoadingIndicator extends StatefulWidget {
  final bool isSpinning;

  const LoadingIndicator({super.key, this.isSpinning = true});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isSpinning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _controller.repeat(reverse: true);
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
    final logo = Image.asset(
      'assets/images/app_movil_only_sm.png',
      width: AppDimensions.space64 + AppDimensions.space16,
      height: AppDimensions.space64 + AppDimensions.space16,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.eco,
        color: AppColors.onBrand,
        size: AppDimensions.space64 + AppDimensions.space16,
      ),
    );

    if (widget.isSpinning) {
      return ScaleTransition(
        scale: _animation,
        child: logo,
      );
    }
    return logo;
  }
}
