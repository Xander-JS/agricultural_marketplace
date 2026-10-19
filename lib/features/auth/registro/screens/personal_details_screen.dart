import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/progress/step_progress_bar.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../models/registration_data.dart';
import 'otp_verification_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final RegistrationData? data;
  const PersonalDetailsScreen({Key? key, this.data}) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late RegistrationData _data;
  final _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data ?? RegistrationData();
    _phoneController.text = _data.phone ?? '';
    _firstNameController.text = _data.firstName ?? '';
    _lastNameController.text = _data.lastName ?? '';
    _passwordController.text = _data.password ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_formKey.currentState?.validate() ?? false) {
      _data.phone = _phoneController.text.trim();
      _data.firstName = _firstNameController.text.trim();
      _data.lastName = _lastNameController.text.trim();
      _data.password = _passwordController.text;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(data: _data),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: CustomAppBar(title: l10n.personal_info_title),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const StepProgressBar(totalSteps: 4, currentStep: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    CustomTextField(
                      label: l10n.personal_info_phone,
                      hint: l10n.personal_info_phone_hint,
                      icon: Icons.phone_android,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.personal_info_required;
                        }
                        final clean = value.replaceAll(RegExp(r'[\s\-()]+'), '');
                        if (!clean.contains('@') && clean.length < 7) {
                          return 'Número telefónico inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: l10n.personal_info_first_name,
                      hint: l10n.personal_info_first_name_hint,
                      icon: Icons.badge_outlined,
                      controller: _firstNameController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? l10n.personal_info_required : null,
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: l10n.personal_info_last_name,
                      hint: l10n.personal_info_last_name_hint,
                      icon: Icons.person_outline,
                      controller: _lastNameController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? l10n.personal_info_required : null,
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: l10n.login_password,
                      hint: l10n.login_password_hint,
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.lightTextDisabled,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.personal_info_required;
                        }
                        if (value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.personal_info_verification_description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : PrimaryActionButton(
                        onPressed: _onNext,
                        icon: Icons.arrow_forward,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
