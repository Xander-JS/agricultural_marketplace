import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../core/widgets/progress/step_progress_bar.dart';

/// Shared frame for registration and verification steps.
///
/// iOS navigation bar, the step bar (when the screen is part of the counted
/// flow), a lead sentence, scrolling content and a bottom action area that
/// stays put above the home indicator.
class RegistrationStepScaffold extends StatelessWidget {
  final String title;
  final int? step;
  final int totalSteps;
  final String? lead;
  final List<Widget> children;
  final Widget? bottom;
  final Key? scaffoldKey;

  const RegistrationStepScaffold({
    super.key,
    required this.title,
    this.step,
    this.totalSteps = 4,
    this.lead,
    required this.children,
    this.bottom,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(title: title),
      body: SafeArea(
        child: Column(
          children: [
            if (step != null)
              StepProgressBar(totalSteps: totalSteps, currentStep: step!),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space20,
                  AppDimensions.space12,
                  AppDimensions.space20,
                  AppDimensions.space24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lead != null) ...[
                      Text(
                        lead!,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),
                    ],
                    ...children,
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space20,
                  AppDimensions.space8,
                  AppDimensions.space20,
                  AppDimensions.space16,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Small sentence-case heading for a group of rows, iOS settings style.
class GroupHeading extends StatelessWidget {
  final String text;

  const GroupHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space4,
        bottom: AppDimensions.space8,
      ),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

/// Quiet one-line footnote with a leading icon (privacy and process notes).
class StepFootnote extends StatelessWidget {
  final IconData icon;
  final String text;

  const StepFootnote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: context.appTextSecondary),
        ),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
