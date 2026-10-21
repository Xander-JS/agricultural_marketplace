import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'loading_indicator.dart';

class LoadingContent extends StatelessWidget {
  final bool isError;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final String? retryText;
  final String? backText;
  final bool isSpinning;

  const LoadingContent({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
    this.onBack,
    this.retryText,
    this.backText,
    this.isSpinning = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isError)
          LoadingIndicator(isSpinning: isSpinning)
        else
          const Icon(
            Icons.error_outline,
            color: AppColors.onBrand,
            size: AppDimensions.space64 + AppDimensions.space16,
          ),
        const SizedBox(height: AppDimensions.space32),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.onBrand,
          ),
        ),
        if (isError) ...[
          const SizedBox(height: AppDimensions.space32),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onBrand,
                foregroundColor: AppColors.loadingBackground,
                padding: AppDimensions.paddingButtonLarge,
              ),
              child: Text(retryText ?? l10n?.common_retry ?? ''),
            ),
          const SizedBox(height: AppDimensions.space16),
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
