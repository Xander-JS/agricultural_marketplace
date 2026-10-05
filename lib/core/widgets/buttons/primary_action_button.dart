import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final bool isLoading;

  const PrimaryActionButton({
    Key? key,
    required this.onPressed,
    this.text,
    this.icon,
    this.isLoading = false,
  }) : assert(text != null || icon != null),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : text != null
                ? Text(
                    text!,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: Colors.white),
      ),
    );
  }
}
