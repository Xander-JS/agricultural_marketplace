import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../login/widgets/topo_header.dart';
import '../../widgets/auth_layout.dart';
import '../services/recovery_service.dart';
import '../../../../core/constants/input_limits.dart';

/// Pantalla para establecer una nueva contraseña tras abrir un enlace de recuperación.
class ResetPasswordScreen extends StatefulWidget {
  final RecoveryService? recoveryService;
  final VoidCallback? onPasswordUpdated;
  final VoidCallback? onCancel;

  const ResetPasswordScreen({
    super.key,
    this.recoveryService,
    this.onPasswordUpdated,
    this.onCancel,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final RecoveryService _service;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _service = widget.recoveryService ?? RecoveryService();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context);
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final result = await _service.updatePassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      showAppSnackBar(
        context,
        l10n?.reset_password_success ?? result.message,
        tone: StatusTone.success,
      );

      // Notificar a AuthGate o al llamador para cerrar sesión y volver a LoginScreen
      widget.onPasswordUpdated?.call();
    } else {
      setState(() {
        _isLoading = false;
        if (result.isNetworkError) {
          _errorMessage = l10n?.recovery_network_error ?? result.message;
        } else {
          _errorMessage = result.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget visibilityToggle(bool obscured, VoidCallback onPressed) {
      return IconButton(
        icon: Icon(
          obscured ? LucideIcons.eye : LucideIcons.eyeOff,
          size: AppDimensions.iconSM,
          color: context.appTextSecondary,
        ),
        onPressed: onPressed,
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: TopoHeader.compactHeight(context),
                  width: double.infinity,
                  child: const TopoHeader(compact: true),
                ),
                if (widget.onCancel != null)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      child: AuthHeaderButton(
                        icon: LucideIcons.x,
                        tooltip: l10n.reset_password_cancel,
                        onPressed: widget.onCancel,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.space20,
                AppDimensions.space8,
                AppDimensions.space20,
                AppDimensions.space24 + bottomInset,
              ),
              child: AuthFormEntrance(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTaskHeader(
                        icon: LucideIcons.lockKeyhole,
                        title: l10n.reset_password_title,
                        subtitle: l10n.reset_password_subtitle,
                      ),
                      const SizedBox(height: AppDimensions.space20),
                      InsetGroupCard(
                        child: Column(
                          children: [
                            CustomTextField(
                              label: l10n.reset_password_new_label,
                              hint: l10n.reset_password_new_hint,
                              icon: LucideIcons.lockKeyhole,
                              controller: _passwordController,
                              maxLength: InputLimits.password,
                              showCounter: false,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              suffixIcon: visibilityToggle(
                                _obscurePassword,
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (value) {
                                final val = value ?? '';
                                if (val.isEmpty) {
                                  return l10n.reset_password_required_error;
                                }
                                if (val.length < 6) {
                                  return l10n.reset_password_length_error;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            CustomTextField(
                              label: l10n.reset_password_confirm_label,
                              hint: l10n.reset_password_confirm_hint,
                              icon: LucideIcons.keyRound,
                              controller: _confirmPasswordController,
                              maxLength: InputLimits.password,
                              showCounter: false,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              suffixIcon: visibilityToggle(
                                _obscureConfirmPassword,
                                () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                              validator: (value) {
                                final val = value ?? '';
                                if (val.isEmpty) {
                                  return l10n.reset_password_required_error;
                                }
                                if (val != _passwordController.text) {
                                  return l10n.reset_password_mismatch_error;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Error devuelto por el servicio de recuperación
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppDimensions.space16),
                        StatusBanner(
                          tone: StatusTone.error,
                          icon: Icons.error_outline,
                          message: _errorMessage!,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space20),
                      PrimaryActionButton(
                        onPressed: (_isLoading || _isSuccess)
                            ? null
                            : _handleUpdatePassword,
                        text: _isLoading
                            ? l10n.reset_password_updating
                            : l10n.reset_password_submit_button,
                        isLoading: _isLoading,
                      ),
                      if (widget.onCancel != null) ...[
                        const SizedBox(height: AppDimensions.space8),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : widget.onCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: context.appTextSecondary,
                            ),
                            child: Text(l10n.reset_password_cancel),
                          ),
                        ),
                      ],
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
