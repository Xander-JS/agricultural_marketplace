import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import '../../widgets/document_image_picker.dart';
import '../../widgets/document_selection_card.dart';
import '../../widgets/registration_step_scaffold.dart';
import '../../widgets/upload_progress_note.dart';
import '../services/account_completion_service.dart';

/// Pantalla de recuperación para cuentas que existen en Supabase Auth pero no
/// tienen perfil en `public.profiles`.
///
/// No inventa datos: cualquier dato precargado proviene de los metadatos de la
/// propia sesión y siempre es editable. Los tres documentos deben capturarse de
/// nuevo porque no es posible recuperarlos desde el registro anterior.
class CompleteRegistrationScreen extends StatefulWidget {
  final User? currentUser;
  final AccountCompletionService? completionService;
  final DocumentImageSelector? imageSelector;
  final Future<void> Function()? onCompleted;
  final Future<void> Function()? onSignOut;

  const CompleteRegistrationScreen({
    super.key,
    this.currentUser,
    this.completionService,
    this.imageSelector,
    this.onCompleted,
    this.onSignOut,
  });

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AccountCompletionService _service;

  final _contactController = TextEditingController();
  final _fullNameController = TextEditingController();

  String? _selectedRole;
  File? _documentFront;
  File? _documentBack;
  File? _selfie;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.completionService ?? AccountCompletionService();

    final user = widget.currentUser;
    final email = user?.email ?? '';
    _contactController.text = email.endsWith('@agromarket.com')
        ? email.substring(0, email.length - '@agromarket.com'.length)
        : email;

    final metadata = user?.userMetadata;
    final rawFullName = metadata?['full_name'] ?? metadata?['name'];
    if (rawFullName is String) {
      _fullNameController.text = rawFullName.trim();
    }

    final rawRole = metadata?['role'];
    final parsedRole = UserRole.tryParse(rawRole is String ? rawRole : null);
    if (parsedRole == UserRole.agricultor || parsedRole == UserRole.comprador) {
      _selectedRole = parsedRole!.toDbValue();
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  bool get _hasAllDocuments =>
      _documentFront != null && _documentBack != null && _selfie != null;

  Future<void> _pickImage({
    required CameraDevice preferredCameraDevice,
    required ValueChanged<File> onSelected,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final file = await showDocumentImageSourceSheet(
        context,
        selector: widget.imageSelector,
        preferredCameraDevice: preferredCameraDevice,
      );
      if (file == null || !mounted) return;
      setState(() {
        onSelected(file);
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.document_pick_error);
    }
  }

  String _messageForFailure(
    AppLocalizations l10n,
    AccountCompletionFailure? failure,
  ) {
    switch (failure) {
      case AccountCompletionFailure.unauthenticated:
        return l10n.complete_registration_unauthorized;
      case AccountCompletionFailure.invalidData:
        return l10n.complete_registration_invalid_data;
      case AccountCompletionFailure.profile:
        return l10n.complete_registration_profile_error;
      case AccountCompletionFailure.documents:
        return l10n.complete_registration_documents_error;
      case AccountCompletionFailure.inProgress:
        return l10n.complete_registration_in_progress;
      case AccountCompletionFailure.unknown:
      case null:
        return l10n.complete_registration_unknown_error;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _selectedRole == null || !_hasAllDocuments) {
      setState(() {
        _errorMessage = l10n.complete_registration_missing_documents;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await _service.completeRegistration(
      contact: _contactController.text,
      fullName: _fullNameController.text,
      role: _selectedRole!,
      documentFront: _documentFront,
      documentBack: _documentBack,
      selfie: _selfie,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final onCompleted = widget.onCompleted;
      if (onCompleted != null) {
        await onCompleted();
        return;
      }
      setState(() => _isSubmitting = false);
      if (mounted) {
        showAppSnackBar(
          context,
          l10n.complete_registration_success,
          tone: StatusTone.success,
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = _messageForFailure(l10n, result.failure);
    });
  }

  Future<void> _handleSignOut() async {
    final onSignOut = widget.onSignOut;
    if (onSignOut != null) {
      await onSignOut();
      return;
    }
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: RegistrationStepScaffold(
        scaffoldKey: const ValueKey('complete_registration_screen'),
        title: l10n.complete_registration_title,
        lead: l10n.complete_registration_description,
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryActionButton(
              key: const ValueKey('complete_registration_submit'),
              onPressed: _isSubmitting ? null : _submit,
              text: l10n.complete_registration_submit,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: AppDimensions.space4),
            TextButton(
              key: const ValueKey('complete_registration_logout'),
              onPressed: _isSubmitting ? null : _handleSignOut,
              style: TextButton.styleFrom(
                foregroundColor: context.appTextSecondary,
              ),
              child: Text(l10n.profile_logout),
            ),
          ],
        ),
        children: [
          InsetGroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  key: const ValueKey('complete_registration_contact'),
                  label: l10n.complete_registration_contact,
                  hint: l10n.complete_registration_contact_hint,
                  icon: LucideIcons.phone,
                  controller: _contactController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final clean = (value ?? '').trim().replaceAll(
                      RegExp(r'[\s\-()]+'),
                      '',
                    );
                    if (clean.isEmpty) {
                      return l10n.personal_info_required;
                    }
                    if (!clean.contains('@') && clean.length < 7) {
                      return l10n.complete_registration_invalid_data;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space16),
                CustomTextField(
                  key: const ValueKey('complete_registration_full_name'),
                  label: l10n.complete_registration_full_name,
                  hint: l10n.complete_registration_full_name_hint,
                  icon: LucideIcons.userRound,
                  controller: _fullNameController,
                  textInputAction: TextInputAction.done,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.personal_info_required
                      : null,
                ),
                const SizedBox(height: AppDimensions.space16),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.space4,
                    bottom: AppDimensions.space8,
                  ),
                  child: Text(
                    l10n.complete_registration_role,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                CupertinoSlidingSegmentedControl<String>(
                  groupValue: _selectedRole,
                  backgroundColor: context.appSurfaceVariant,
                  thumbColor: context.appSurface,
                  padding: const EdgeInsets.all(3),
                  onValueChanged: (value) {
                    if (_isSubmitting || value == null) return;
                    setState(() => _selectedRole = value);
                  },
                  children: {
                    'agricultor': _RoleSegment(
                      key: const ValueKey(
                        'complete_registration_role_agricultor',
                      ),
                      icon: LucideIcons.sprout,
                      label: UserRole.agricultor.displayName,
                    ),
                    'comprador': _RoleSegment(
                      key: const ValueKey(
                        'complete_registration_role_comprador',
                      ),
                      icon: LucideIcons.briefcaseBusiness,
                      label: UserRole.comprador.displayName,
                    ),
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          GroupHeading(l10n.complete_registration_documents),
          DocumentSelectionCard(
            key: const ValueKey('complete_registration_front'),
            title: l10n.document_front_title,
            file: _documentFront,
            enabled: !_isSubmitting,
            pickButtonKey: const ValueKey('complete_registration_front_pick'),
            onPick: () => _pickImage(
              preferredCameraDevice: CameraDevice.rear,
              onSelected: (file) => _documentFront = file,
            ),
            onRemove: () => setState(() {
              _documentFront = null;
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: AppDimensions.space12),
          DocumentSelectionCard(
            key: const ValueKey('complete_registration_back'),
            title: l10n.document_back_title,
            file: _documentBack,
            enabled: !_isSubmitting,
            pickButtonKey: const ValueKey('complete_registration_back_pick'),
            onPick: () => _pickImage(
              preferredCameraDevice: CameraDevice.rear,
              onSelected: (file) => _documentBack = file,
            ),
            onRemove: () => setState(() {
              _documentBack = null;
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: AppDimensions.space12),
          DocumentSelectionCard(
            key: const ValueKey('complete_registration_selfie'),
            title: l10n.document_selfie_title,
            file: _selfie,
            enabled: !_isSubmitting,
            pickButtonKey: const ValueKey('complete_registration_selfie_pick'),
            onPick: () => _pickImage(
              preferredCameraDevice: CameraDevice.front,
              onSelected: (file) => _selfie = file,
            ),
            onRemove: () => setState(() {
              _selfie = null;
              _errorMessage = null;
            }),
          ),
          if (_isSubmitting) ...[
            const SizedBox(height: AppDimensions.space16),
            UploadProgressNote(message: l10n.document_upload_in_progress),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppDimensions.space16),
            StatusBanner(tone: StatusTone.error, message: _errorMessage!),
          ],
        ],
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoleSegment({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.appTextPrimary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
