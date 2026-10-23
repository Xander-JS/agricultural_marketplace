import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../brand/kus_brand_logo.dart';
import '../misc/app_entrance.dart';
import 'app_skeleton.dart';

/// Status content for the [AppLoading] stage while an account is being
/// prepared.
///
/// While [isSpinning], a shimmering skeleton of the profile card that is
/// being created stands in for the result, with the live status [message]
/// beside an activity indicator. When work stops it settles on the KUS mark
/// and the final message; on [isError] it offers retry and back actions.
/// Screens with a more specific job can replace the skeleton through
/// [workingVisual].
class LoadingContent extends StatelessWidget {
  final bool isError;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final String? retryText;
  final String? backText;
  final bool isSpinning;

  /// Shown instead of the profile skeleton while work is in progress.
  final Widget? workingVisual;

  const LoadingContent({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
    this.onBack,
    this.retryText,
    this.backText,
    this.isSpinning = true,
    this.workingVisual,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final working = isSpinning && !isError;

    final Widget visual;
    if (isError) {
      visual = Container(
        key: const ValueKey('loading_content_error'),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.onBrand.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.onBrand.withValues(alpha: 0.24)),
        ),
        child: const Icon(
          LucideIcons.circleAlert,
          color: AppColors.onBrand,
          size: AppDimensions.iconLG,
        ),
      );
    } else if (working && workingVisual != null) {
      visual = KeyedSubtree(
        key: const ValueKey('loading_content_working'),
        child: workingVisual!,
      );
    } else if (working) {
      visual = Semantics(
        key: const ValueKey('loading_content_skeleton'),
        label: l10n?.loading_skeleton_semantics,
        child: const _ProfileSkeletonCard(),
      );
    } else {
      visual = const KusBrandLogo(
        key: ValueKey('loading_content_mark'),
        variant: KusBrandLogoVariant.hero,
        showWordmark: false,
        onBrandStage: true,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.emphasized),
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: visual,
        ),
        const SizedBox(height: AppDimensions.space32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (working) ...[
              const CupertinoActivityIndicator(
                radius: 9,
                color: AppColors.onBrand,
              ),
              const SizedBox(width: AppDimensions.space12),
            ],
            Flexible(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.standard),
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeOut,
                child: Text(
                  message,
                  key: ValueKey(message),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onBrand,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isError) ...[
          const SizedBox(height: AppDimensions.space32),
          if (onRetry != null)
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightPrimary,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onBrand,
                  foregroundColor: AppColors.loadingBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.borderRadiusControl,
                  ),
                ),
                child: Text(retryText ?? l10n?.common_retry ?? ''),
              ),
            ),
          const SizedBox(height: AppDimensions.space12),
          if (onBack != null)
            TextButton(
              onPressed: onBack,
              child: Text(
                backText ?? l10n?.common_back ?? '',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.onBrand,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Skeleton of the profile card being assembled: avatar, name, role line,
/// detail lines and two status pills, at their real sizes.
class _ProfileSkeletonCard extends StatelessWidget {
  const _ProfileSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.onBrand.withValues(alpha: 0.08),
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: AppColors.onBrand.withValues(alpha: 0.16)),
      ),
      child: AppShimmer(
        onBrandStage: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const AppSkeletonBlock.circle(size: 48),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonBlock(width: 148, height: 14),
                      SizedBox(height: AppDimensions.space8),
                      AppSkeletonBlock(width: 92, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space20),
            const AppSkeletonBlock(width: double.infinity, height: 10),
            const SizedBox(height: AppDimensions.space8),
            const FractionallySizedBox(
              widthFactor: 0.72,
              child: AppSkeletonBlock(height: 10),
            ),
            const SizedBox(height: AppDimensions.space20),
            Row(
              children: const [
                AppSkeletonBlock(
                  width: 84,
                  height: 24,
                  radius: AppDimensions.radiusFull,
                ),
                SizedBox(width: AppDimensions.space8),
                AppSkeletonBlock(
                  width: 64,
                  height: 24,
                  radius: AppDimensions.radiusFull,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return AppEntrance(duration: AppMotion.emphasized, child: card);
  }
}
