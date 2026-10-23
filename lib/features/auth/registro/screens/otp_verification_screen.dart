import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/registration_step_scaffold.dart';
import '../models/registration_data.dart';
import 'role_selection_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final RegistrationData data;
  const OtpVerificationScreen({super.key, required this.data});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int _otpLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _otpLength; i++) {
      _controllers.add(TextEditingController());
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (mounted) setState(() {});
      });
      _focusNodes.add(focusNode);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChange(String value, int index) {
    if (value.length == 1) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otpCode = _controllers.map((c) => c.text).join();

    if (otpCode.length == _otpLength) {
      // Validación simulada correcta
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoleSelectionScreen(data: widget.data),
        ),
      );
    } else {
      // Error simulado
      final l10n = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        l10n.otp_error_incomplete,
        tone: StatusTone.warning,
      );
    }
  }

  Future<void> _resendOtp() async {
    // Simulación de reenvío
    final l10n = AppLocalizations.of(context)!;
    showAppSnackBar(
      context,
      l10n.otp_resend_simulated,
      tone: StatusTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = AppMotion.of(context, AppMotion.quick);

    return RegistrationStepScaffold(
      title: l10n.otp_verification_appbar_title,
      step: 1,
      bottom: PrimaryActionButton(
        onPressed: _verifyOtp,
        text: l10n.common_continue,
        isLoading: _isLoading,
      ),
      children: [
        AuthTaskHeader(
          icon: LucideIcons.smartphone,
          title: l10n.otp_verification_title,
          subtitle: l10n.otp_verification_subtitle,
        ),
        const SizedBox(height: AppDimensions.space32),
        Row(
          children: List.generate(_otpLength, (index) {
            final hasText = _controllers[index].text.isNotEmpty;
            final isFocused = _focusNodes[index].hasFocus;

            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == _otpLength - 1 ? 0 : AppDimensions.space8,
                ),
                child: AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.easeOut,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: AppDimensions.borderRadiusControl,
                    border: Border.all(
                      color: isFocused
                          ? context.appPrimary
                          : hasText
                          ? context.appTextSecondary
                          : context.appBorder,
                      width: isFocused
                          ? AppDimensions.borderWidthMedium
                          : AppDimensions.borderWidthThin,
                    ),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    maxLength: 1,
                    cursorColor: context.appPrimary,
                    style: AppTextStyles.figureLarge.copyWith(
                      color: context.appTextPrimary,
                      height: 1.0,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _onOtpChange(value, index);
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppDimensions.space24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.otp_verification_didnt_receive,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
            TextButton(
              onPressed: _resendOtp,
              child: Text(l10n.otp_verification_resend),
            ),
          ],
        ),
      ],
    );
  }
}
