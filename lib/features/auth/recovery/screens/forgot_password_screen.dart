import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../login/widgets/topo_header.dart';
import '../services/recovery_service.dart';

/// Pantalla para solicitar la recuperación de contraseña por correo electrónico.
class ForgotPasswordScreen extends StatefulWidget {
  final RecoveryService? recoveryService;

  const ForgotPasswordScreen({
    super.key,
    this.recoveryService,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();

  late final RecoveryService _service;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _service = widget.recoveryService ?? RecoveryService();
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isSuccess = false;
    });

    final l10n = AppLocalizations.of(context);
    final contact = _contactController.text;

    final result = await _service.requestPasswordReset(
      contact: contact,
      redirectTo: 'agromarketplace://reset-password',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = result.success;
      if (result.success) {
        _statusMessage = l10n?.recovery_generic_success ?? result.message;
      } else {
        if (result.isNetworkError) {
          _statusMessage = l10n?.recovery_network_error ?? result.message;
        } else if (result.isValidationError) {
          _statusMessage = result.message;
        } else {
          _statusMessage = l10n?.recovery_generic_error ?? result.message;
        }
      }
    });
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: context.appSuccess),
                      onPressed: () => Navigator.of(context).maybePop(),
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
                      l10n.recovery_title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.recovery_subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo de correo
                    CustomTextField(
                      label: l10n.recovery_email_label,
                      hint: l10n.recovery_email_hint,
                      icon: Icons.email_outlined,
                      controller: _contactController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final val = value?.trim() ?? '';
                        if (val.isEmpty) {
                          return l10n.recovery_email_required;
                        }
                        if (!val.contains('@')) {
                          return l10n.recovery_phone_not_supported;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Mensaje de estado (éxito o error)
                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? context.appSuccess.withValues(alpha: 0.1)
                              : context.appError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSuccess
                                ? context.appSuccess
                                : context.appError,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isSuccess
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: _isSuccess
                                  ? context.appSuccess
                                  : context.appError,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _isSuccess
                                      ? context.appSuccess
                                      : context.appError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Botón de envío
                    PrimaryActionButton(
                      onPressed: _isLoading ? null : _handleRequestReset,
                      text: _isLoading
                          ? (l10n.recovery_sending)
                          : (l10n.recovery_send_button),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Botón volver a inicio de sesión
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).maybePop();
                            },
                      child: Text(
                        l10n.recovery_back_to_login,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: context.appSuccess,
                          fontWeight: FontWeight.w600,
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
