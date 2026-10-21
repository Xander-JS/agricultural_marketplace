import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../registro/screens/welcome_screen.dart';
import '../services/login_service.dart';
import '../widgets/topo_header.dart';
import '../../recovery/screens/forgot_password_screen.dart';
import '../../recovery/services/recovery_service.dart';

class LoginScreen extends StatefulWidget {
  final RecoveryService? recoveryService;

  const LoginScreen({
    super.key,
    this.recoveryService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginService = LoginService();

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _loginService.signIn(
          phone: _phoneController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: context.appError,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Expanded(
              flex: 4,
              child: TopoHeader(),
            ),
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        l10n.login_title,
                        style: AppTextStyles.displayLarge.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 32),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.appSuccess,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      CustomTextField(
                        label: l10n.login_phone,
                        hint: l10n.login_phone_hint,
                        icon: Icons.mail_outline,
                        controller: _phoneController,
                        filled: false,
                        isUnderlineBorder: true,
                        isRequired: false, // In original there was no star indicator explicitly, but it was required
                        validator: (value) =>
                            value == null || value.isEmpty ? l10n.login_required : null,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: l10n.login_password,
                        hint: l10n.login_password_hint,
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        filled: false,
                        isUnderlineBorder: true,
                        isRequired: false,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: context.appTextSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? l10n.login_required : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: context.appSuccess,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.login_remember_me,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.appTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(
                                    recoveryService: widget.recoveryService,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              l10n.login_forgot_password,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: context.appSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      PrimaryActionButton(
                        onPressed: _handleLogin,
                        text: l10n.login_login_button,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.login_no_account,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.appTextSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.login_register,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: context.appSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
