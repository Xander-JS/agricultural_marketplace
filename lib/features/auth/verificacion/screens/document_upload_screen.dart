import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_icons.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/misc/app_entrance.dart';
import '../../widgets/document_image_picker.dart';
import '../../widgets/document_selection_card.dart';
import '../../widgets/registration_step_scaffold.dart';
import '../../widgets/upload_progress_note.dart';
import '../services/document_submission_service.dart';

/// Permite volver a cargar el frente, reverso y selfie cuando la solicitud fue
/// rechazada o cuando el registro no pudo guardar los documentos.
class DocumentUploadScreen extends StatefulWidget {
  final DocumentSubmissionService? submissionService;
  final DocumentImageSelector? imageSelector;

  const DocumentUploadScreen({
    super.key,
    this.submissionService,
    this.imageSelector,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late final DocumentSubmissionService _service;

  File? _documentFront;
  File? _documentBack;
  File? _selfie;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.submissionService ?? DocumentSubmissionService();
  }

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

  bool get _hasAllDocuments =>
      _documentFront != null && _documentBack != null && _selfie != null;

  String _messageForFailure(
    AppLocalizations l10n,
    DocumentSubmissionFailure? failure,
  ) {
    switch (failure) {
      case DocumentSubmissionFailure.missingDocuments:
        return l10n.document_upload_missing;
      case DocumentSubmissionFailure.fileUnavailable:
        return l10n.document_upload_file_missing;
      case DocumentSubmissionFailure.unauthorized:
        return l10n.document_upload_unauthorized;
      case DocumentSubmissionFailure.storage:
        return l10n.document_upload_storage_error;
      case DocumentSubmissionFailure.attempt:
        return l10n.document_upload_attempt_error;
      case DocumentSubmissionFailure.pendingExists:
        return l10n.document_upload_duplicate;
      case DocumentSubmissionFailure.inProgress:
        return l10n.document_upload_in_progress;
      case DocumentSubmissionFailure.unknown:
      case null:
        return l10n.document_upload_error;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    if (!_hasAllDocuments) {
      setState(() => _errorMessage = l10n.document_upload_missing);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await _service.submitDocuments(
      documentFront: _documentFront,
      documentBack: _documentBack,
      selfie: _selfie,
    );

    if (result.isSuccess) clearPersistedDocumentImages();
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (result.isSuccess) {
        _isSuccess = true;
      } else {
        _errorMessage = _messageForFailure(l10n, result.failure);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: CustomAppBar(title: l10n.document_upload_title),
        body: SafeArea(child: _buildSuccess(context, l10n)),
      );
    }

    return RegistrationStepScaffold(
      title: l10n.document_upload_title,
      lead: l10n.document_upload_description,
      bottom: PrimaryActionButton(
        key: const ValueKey('document_upload_submit'),
        onPressed: _isSubmitting ? null : _submit,
        text: l10n.document_upload_submit,
        isLoading: _isSubmitting,
      ),
      children: [
        DocumentSelectionCard(
          key: const ValueKey('document_upload_front'),
          title: l10n.document_front_title,
          file: _documentFront,
          enabled: !_isSubmitting,
          pickButtonKey: const ValueKey('document_upload_front_pick'),
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
          key: const ValueKey('document_upload_back'),
          title: l10n.document_back_title,
          file: _documentBack,
          enabled: !_isSubmitting,
          pickButtonKey: const ValueKey('document_upload_back_pick'),
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
          key: const ValueKey('document_upload_selfie'),
          title: l10n.document_selfie_title,
          file: _selfie,
          enabled: !_isSubmitting,
          pickButtonKey: const ValueKey('document_upload_selfie_pick'),
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
    );
  }

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    final triad = context.appSuccessTriad;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: AppEntrance(
          duration: AppMotion.emphasized,
          beginScale: 0.97,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: triad.background,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: triad.border),
                ),
                child: Icon(
                  LucideIcons.fileCheck,
                  size: 40,
                  color: triad.foreground,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
              Text(
                l10n.document_upload_success_title,
                textAlign: TextAlign.center,
                style: AppTextStyles.displaySmall.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                l10n.document_upload_success_desc,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.space32),
              PrimaryActionButton(
                key: const ValueKey('document_upload_success_back'),
                onPressed: () => Navigator.of(context).pop(true),
                text: l10n.document_upload_success_back,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
