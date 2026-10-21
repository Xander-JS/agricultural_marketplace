import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

class StepProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isLast = index == totalSteps - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: AppDimensions.space4,
                    color: isCompleted ? context.appSuccess : context.appBorder,
                  ),
                ),
                if (!isLast) const SizedBox(width: AppDimensions.space4),
              ],
            ),
          );
        }),
      ),
    );
  }
}
