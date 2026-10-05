import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'loading_indicator.dart';

class LoadingContent extends StatelessWidget {
  final bool isError;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final String retryText;
  final String backText;
  final bool isSpinning;

  const LoadingContent({
    Key? key,
    required this.message,
    this.isError = false,
    this.onRetry,
    this.onBack,
    this.retryText = 'Reintentar',
    this.backText = 'Volver atrás',
    this.isSpinning = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isError)
          LoadingIndicator(isSpinning: isSpinning)
        else
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 80,
          ),
        const SizedBox(height: 32),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        if (isError) ...[
          const SizedBox(height: 32),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.loadingBackground,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(retryText),
            ),
          const SizedBox(height: 16),
          if (onBack != null)
            TextButton(
              onPressed: onBack,
              child: Text(
                backText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ],
    );
  }
}
