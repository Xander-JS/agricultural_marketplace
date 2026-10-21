import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
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
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space8),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(color: context.appSuccess),
                ),
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
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            prefixIcon: isUnderlineBorder
                ? Icon(icon, color: colors.onSurfaceVariant)
                : null,
            suffixIcon: isUnderlineBorder
                ? suffixIcon
                : (suffixIcon ?? Icon(icon, color: colors.onSurfaceVariant)),
            filled: filled,
            fillColor: filled ? colors.surface : null,
            border: _getBorder(context),
            enabledBorder: _getBorder(context),
            focusedBorder: _getBorder(context, focused: true),
          ),
        ),
      ],
    );
  }

  InputBorder _getBorder(BuildContext context, {bool focused = false}) {
    final colors = Theme.of(context).colorScheme;
    if (isUnderlineBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: focused ? context.appSuccess : colors.outline,
        ),
      );
    }
    return OutlineInputBorder(
      borderRadius: AppDimensions.borderRadiusLG,
      borderSide: BorderSide(
        color: focused ? context.appSuccess : colors.outline,
      ),
    );
  }
}
