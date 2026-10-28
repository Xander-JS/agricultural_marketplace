import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../login/widgets/topo_header.dart';
import '../../widgets/auth_layout.dart';
import '../services/recovery_service.dart';
import '../../../../core/constants/input_limits.dart';

/// Pantalla para solicitar la recuperación de contraseña por correo electrónico.
class ForgotPasswordScreen extends StatefulWidget {
  final RecoveryService? recoveryService;

  const ForgotPasswordScreen({super.key, this.recoveryService});

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    child: AuthHeaderButton(
                      icon: Icons.arrow_back,
                      tooltip: l10n.common_back,
                      onPressed: () => Navigator.of(context).maybePop(),
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
                        icon: LucideIcons.keyRound,
                        title: l10n.recovery_title,
                        subtitle: l10n.recovery_subtitle,
                      ),
                      const SizedBox(height: AppDimensions.space20),
                      InsetGroupCard(
                        child: CustomTextField(
                          label: l10n.recovery_email_label,
                          hint: l10n.recovery_email_hint,
                          icon: LucideIcons.mail,
                          controller: _contactController,
                          maxLength: InputLimits.email,
                          showCounter: false,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.send,
                          autofillHints: const [AutofillHints.email],
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
                      ),

                      // Resultado del envío (confirmación o error)
                      if (_statusMessage != null) ...[
                        const SizedBox(height: AppDimensions.space16),
                        StatusBanner(
                          key: ValueKey('recovery_status_$_isSuccess'),
                          tone: _isSuccess
                              ? StatusTone.success
                              : StatusTone.error,
                          icon: _isSuccess
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          message: _statusMessage!,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space20),
                      PrimaryActionButton(
                        onPressed: _isLoading ? null : _handleRequestReset,
                        text: _isLoading
                            ? l10n.recovery_sending
                            : l10n.recovery_send_button,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: Text(l10n.recovery_back_to_login),
                        ),
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
