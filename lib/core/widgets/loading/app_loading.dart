import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppLoading extends StatelessWidget {
  final Widget child;

  const AppLoading({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loadingBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
