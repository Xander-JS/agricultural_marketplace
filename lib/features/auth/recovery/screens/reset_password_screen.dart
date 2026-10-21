import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../login/widgets/topo_header.dart';
import '../services/recovery_service.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.reset_password_success ?? result.message,
          ),
          backgroundColor: context.appSuccess,
          duration: const Duration(seconds: 3),
        ),
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

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                const SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: TopoHeader(),
                ),
                if (widget.onCancel != null)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: IconButton(
                        icon: Icon(Icons.close, color: context.appSuccess),
                        onPressed: widget.onCancel,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.reset_password_title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.reset_password_subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo de nueva contraseña
                    CustomTextField(
                      label: l10n.reset_password_new_label,
                      hint: l10n.reset_password_new_hint,
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: context.appTextSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
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
                    const SizedBox(height: 16),

                    // Campo de confirmación de contraseña
                    CustomTextField(
                      label: l10n.reset_password_confirm_label,
                      hint: l10n.reset_password_confirm_hint,
                      icon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: context.appTextSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
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
                    const SizedBox(height: 24),

                    // Mensaje de error si ocurrió
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.appError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.appError,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: context.appError,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.appError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Botón de actualización
                    PrimaryActionButton(
                      onPressed: (_isLoading || _isSuccess)
                          ? null
                          : _handleUpdatePassword,
                      text: _isLoading
                          ? (l10n.reset_password_updating)
                          : (l10n.reset_password_submit_button),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    if (widget.onCancel != null)
                      TextButton(
                        onPressed: _isLoading ? null : widget.onCancel,
                        child: Text(
                          l10n.reset_password_cancel,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
