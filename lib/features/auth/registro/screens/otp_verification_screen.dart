import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/progress/step_progress_bar.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../models/registration_data.dart';
import 'role_selection_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final RegistrationData data;
  const OtpVerificationScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int _otpLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa los 6 dígitos completos')),
      );
    }
  }

  Future<void> _resendOtp() async {
    // Simulación de reenvío
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código reenviado (Simulado)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: CustomAppBar(title: l10n.otp_verification_appbar_title),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(totalSteps: 4, currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightTertiary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/images/app_movil_only_sm.png',
                        height: 48,
                        width: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.otp_verification_subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // OTP Inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_otpLength, (index) {
                        bool hasText = _controllers[index].text.isNotEmpty;
                        bool isFocused = _focusNodes[index].hasFocus;

                        return Container(
                          width: 46,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFocused || hasText
                                  ? AppColors.lightTertiary
                                  : AppColors.lightBorder,
                              width: isFocused || hasText ? 2.0 : 1.0,
                            ),
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            maxLength: 1,
                            cursorColor: AppColors.lightTertiary,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.lightTextPrimary,
                              fontSize: 24,
                              height: 1.0,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              counterText: '',
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() {});
                              _onOtpChange(value, index);
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.otp_verification_didnt_receive,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendOtp,
                          child: Text(
                            l10n.otp_verification_resend,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.lightTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : PrimaryActionButton(
                      onPressed: _verifyOtp,
                      icon: Icons.arrow_forward,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
