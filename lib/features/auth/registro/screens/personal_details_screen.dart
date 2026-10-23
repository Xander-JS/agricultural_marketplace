import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../widgets/registration_step_scaffold.dart';
import '../models/registration_data.dart';
import 'role_selection_screen.dart';

// Nota: OtpVerificationScreen eliminado del flujo de registro por defecto.
// El proveedor SMS de Supabase está desactivado (enable_signup = false en [auth.sms]).
// La verificación de identidad se realiza a través de documentos físicos revisados por moderador.

class PersonalDetailsScreen extends StatefulWidget {
  final RegistrationData? data;
  const PersonalDetailsScreen({super.key, this.data});

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

      // El flujo de OTP por SMS fue eliminado: Supabase no tiene SMS habilitado.
      // Se navega directamente a la selección de rol.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoleSelectionScreen(data: _data)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: RegistrationStepScaffold(
        title: l10n.personal_info_title,
        step: 1,
        bottom: PrimaryActionButton(
          onPressed: _onNext,
          text: l10n.common_continue,
          isLoading: _isLoading,
        ),
        children: [
          InsetGroupCard(
            child: Column(
              children: [
                CustomTextField(
                  label: l10n.personal_info_phone,
                  hint: l10n.personal_info_phone_hint,
                  icon: LucideIcons.phone,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.personal_info_required;
                    }
                    final clean = value.replaceAll(RegExp(r'[\s\-()]+'), '');
                    if (!clean.contains('@') && clean.length < 7) {
                      return l10n.personal_info_phone_invalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space16),
                CustomTextField(
                  label: l10n.personal_info_first_name,
                  hint: l10n.personal_info_first_name_hint,
                  icon: LucideIcons.userRound,
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.personal_info_required
                      : null,
                ),
                const SizedBox(height: AppDimensions.space16),
                CustomTextField(
                  label: l10n.personal_info_last_name,
                  hint: l10n.personal_info_last_name_hint,
                  icon: LucideIcons.userRound,
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.personal_info_required
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
                  autofillHints: const [AutofillHints.newPassword],
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.personal_info_required;
                    }
                    if (value.length < 6) {
                      return l10n.personal_info_password_min;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          StatusBanner(
            tone: StatusTone.brand,
            icon: LucideIcons.shieldCheck,
            message: l10n.personal_info_verification_description,
          ),
        ],
      ),
    );
  }
}
