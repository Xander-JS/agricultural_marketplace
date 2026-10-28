import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// iOS grouped-style form field with its label above.
///
/// Rests on a `surfaceVariant` fill with no visible border; focus draws a
/// 1.5px primary outline and errors use the error triad. The [icon] always
/// leads the field so trailing controls (show password) never replace it.
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
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? maxLength;

  /// Hides the "n/max" counter while still enforcing [maxLength].
  final bool showCounter;
  final bool enabled;
  final TextCapitalization textCapitalization;

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
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = true,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: AppDimensions.iconSM,
      color: context.appTextSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.space4,
            bottom: AppDimensions.space8,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.appPrimary,
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          maxLines: maxLines,
          maxLength: maxLength,
          buildCounter: showCounter
              ? null
              : (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: AppTextStyles.bodyLarge.copyWith(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: context.appPrimary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
            // A multi-line field keeps its icon on the first line: the
            // decorator centers the icon, so lift it by the extra lines
            // (bodyLarge runs 22.5px per line).
            prefixIcon: maxLines > 1
                ? Padding(
                    padding: EdgeInsets.only(bottom: (maxLines - 1) * 22.5),
                    child: iconWidget,
                  )
                : iconWidget,
            prefixIconConstraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            suffixIcon: suffixIcon,
            filled: filled && !isUnderlineBorder,
            fillColor: context.appSurfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space16,
            ),
            border: _border(context, _FieldState.rest),
            enabledBorder: _border(context, _FieldState.rest),
            focusedBorder: _border(context, _FieldState.focused),
            errorBorder: _border(context, _FieldState.error),
            focusedErrorBorder: _border(context, _FieldState.focusedError),
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: context.appError,
            ),
          ),
        ),
      ],
    );
  }

  InputBorder _border(BuildContext context, _FieldState state) {
    final BorderSide side = switch (state) {
      _FieldState.rest =>
        isUnderlineBorder
            ? BorderSide(color: context.appBorder)
            : BorderSide.none,
      _FieldState.focused => BorderSide(
        color: context.appPrimary,
        width: AppDimensions.borderWidthMedium,
      ),
      _FieldState.error => BorderSide(color: context.appErrorBorder),
      _FieldState.focusedError => BorderSide(
        color: context.appError,
        width: AppDimensions.borderWidthMedium,
      ),
    };

    if (isUnderlineBorder) {
      return UnderlineInputBorder(borderSide: side);
    }
    return OutlineInputBorder(
      borderRadius: AppDimensions.borderRadiusControl,
      borderSide: side,
    );
  }
}

enum _FieldState { rest, focused, error, focusedError }
