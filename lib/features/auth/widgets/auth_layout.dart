import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/misc/icon_squircle.dart';

/// Entrance for auth form bodies: a 220ms fade with a 3% rise.
///
/// Auth screens are visited a handful of times, so one short settle is the
/// screen's only motion. Under Reduce Motion the body appears in place.
class AuthFormEntrance extends StatelessWidget {
  final Widget child;

  const AuthFormEntrance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return child
        .animate()
        .fadeIn(duration: 220.ms, curve: AppMotion.easeOut)
        .slideY(
          begin: 0.03,
          end: 0,
          duration: 220.ms,
          curve: AppMotion.easeOut,
        );
  }
}

/// Task header for focused auth screens (recover, reset): the task's icon in
/// a soft brand squircle, then the title and one line of guidance.
class AuthTaskHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthTaskHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconSquircle(icon: icon, size: 48, iconSize: 24),
        const SizedBox(height: AppDimensions.space16),
        Text(
          title,
          style: AppTextStyles.displayMedium.copyWith(
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: context.appTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// Round control floating over the auth header's forest field. White icon
/// on a translucent white disc keeps AAA contrast on both gradient stops.
class AuthHeaderButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  const AuthHeaderButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppDimensions.iconSM),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.onBrand,
        backgroundColor: AppColors.onBrand.withValues(alpha: 0.14),
        fixedSize: const Size.square(AppDimensions.minTouchTarget),
        shape: CircleBorder(
          side: BorderSide(color: AppColors.onBrand.withValues(alpha: 0.22)),
        ),
      ),
    );
  }
}
