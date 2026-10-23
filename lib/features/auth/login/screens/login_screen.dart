import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../registro/screens/welcome_screen.dart';
import '../../widgets/auth_layout.dart';
import '../services/login_service.dart';
import '../widgets/topo_header.dart';
import '../../recovery/screens/forgot_password_screen.dart';
import '../../recovery/services/recovery_service.dart';

class LoginScreen extends StatefulWidget {
  final RecoveryService? recoveryService;

  const LoginScreen({super.key, this.recoveryService});

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
        showAppSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
          tone: StatusTone.error,
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
    final size = MediaQuery.sizeOf(context);
    final headerHeight = (size.height * 0.36).clamp(250.0, 330.0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.login_title,
            style: AppTextStyles.displayMedium.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          InsetGroupCard(
            child: Column(
              children: [
                CustomTextField(
                  label: l10n.login_phone,
                  hint: l10n.login_phone_hint,
                  icon: LucideIcons.phone,
                  controller: _phoneController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.telephoneNumber,
                    AutofillHints.email,
                  ],
                  isRequired: false,
                  validator: (value) => value == null || value.isEmpty
                      ? l10n.login_required
                      : null,
                ),
                const SizedBox(height: AppDimensions.space16),
                CustomTextField(
                  label: l10n.login_password,
                  hint: l10n.login_password_hint,
                  icon: LucideIcons.lockKeyhole,
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  isRequired: false,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: AppDimensions.iconSM,
                      color: context.appTextSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? l10n.login_required
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              Expanded(
                child: _RememberToggle(
                  value: _rememberMe,
                  label: l10n.login_remember_me,
                  semanticsLabel: l10n.auth_remember_me_semantics,
                  onChanged: (value) => setState(() => _rememberMe = value),
                ),
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
                child: Text(l10n.login_forgot_password),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          PrimaryActionButton(
            onPressed: _handleLogin,
            text: l10n.login_login_button,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppDimensions.space24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.login_no_account,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                child: Text(l10n.login_register),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: const TopoHeader(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.space20,
                AppDimensions.space4,
                AppDimensions.space20,
                AppDimensions.space24 + bottomInset,
              ),
              child: AuthFormEntrance(child: form),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style round check with its label, the same check language used by
/// the selection cards in registration.
class _RememberToggle extends StatelessWidget {
  final bool value;
  final String label;
  final String semanticsLabel;
  final ValueChanged<bool> onChanged;

  const _RememberToggle({
    required this.value,
    required this.label,
    required this.semanticsLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: AppDimensions.borderRadiusSM,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.quick),
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeOut,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  value
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  key: ValueKey(value),
                  size: 22,
                  color: value ? context.appPrimary : context.appTextMuted,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
