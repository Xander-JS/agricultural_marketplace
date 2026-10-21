import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final bool isLoading;

  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    this.text,
    this.icon,
    this.isLoading = false,
  }) : assert(text != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightLarge,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? CircularProgressIndicator(color: context.appOnPrimary)
            : text != null
            ? Text(
                text!,
                style: AppTextStyles.buttonLarge.copyWith(
                  color: context.appOnPrimary,
                ),
              )
            : Icon(icon, color: context.appOnPrimary),
      ),
    );
  }
}
