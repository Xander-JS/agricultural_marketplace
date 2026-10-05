import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool isRequired;
  final bool filled;
  final bool isUnderlineBorder;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.isRequired = true,
    this.filled = true,
    this.isUnderlineBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: AppColors.success)),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightTextDisabled,
            ),
            prefixIcon: isUnderlineBorder ? Icon(icon, color: AppColors.lightTextDisabled) : null,
            suffixIcon: isUnderlineBorder ? suffixIcon : (suffixIcon ?? Icon(icon, color: AppColors.lightTextDisabled)),
            filled: filled,
            fillColor: filled ? AppColors.lightSurface : null,
            border: _getBorder(),
            enabledBorder: _getBorder(),
            focusedBorder: _getBorder(focused: true),
          ),
        ),
      ],
    );
  }

  InputBorder _getBorder({bool focused = false}) {
    if (isUnderlineBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: focused ? AppColors.success : AppColors.lightBorder,
        ),
      );
    }
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: focused ? AppColors.success : AppColors.lightBorder,
      ),
    );
  }
}
