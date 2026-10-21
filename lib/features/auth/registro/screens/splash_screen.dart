import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Simulate loading time and navigate to Welcome.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loadingBackground,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Image.asset(
            'assets/images/app_movil_only_lg.png',
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.eco,
              color: AppColors.onBrand,
              size: 120,
            ),
            width: 180,
            height: 180,
          ),
        ),
      ),
    );
  }
}
