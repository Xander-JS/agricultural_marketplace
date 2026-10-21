import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../widgets/document_image_picker.dart';
import '../../widgets/document_selection_card.dart';
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

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(title: l10n.document_upload_title),
      body: SafeArea(
        child: _isSuccess
            ? _buildSuccess(context, l10n)
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.document_upload_description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.appTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DocumentSelectionCard(
                            key: const ValueKey('document_upload_front'),
                            title: l10n.document_front_title,
                            file: _documentFront,
                            enabled: !_isSubmitting,
                            pickButtonKey: const ValueKey(
                              'document_upload_front_pick',
                            ),
                            onPick: () => _pickImage(
                              preferredCameraDevice: CameraDevice.rear,
                              onSelected: (file) => _documentFront = file,
                            ),
                            onRemove: () => setState(() {
                              _documentFront = null;
                              _errorMessage = null;
                            }),
                          ),
                          const SizedBox(height: 12),
                          DocumentSelectionCard(
                            key: const ValueKey('document_upload_back'),
                            title: l10n.document_back_title,
                            file: _documentBack,
                            enabled: !_isSubmitting,
                            pickButtonKey: const ValueKey(
                              'document_upload_back_pick',
                            ),
                            onPick: () => _pickImage(
                              preferredCameraDevice: CameraDevice.rear,
                              onSelected: (file) => _documentBack = file,
                            ),
                            onRemove: () => setState(() {
                              _documentBack = null;
                              _errorMessage = null;
                            }),
                          ),
                          const SizedBox(height: 12),
                          DocumentSelectionCard(
                            key: const ValueKey('document_upload_selfie'),
                            title: l10n.document_selfie_title,
                            file: _selfie,
                            enabled: !_isSubmitting,
                            pickButtonKey: const ValueKey(
                              'document_upload_selfie_pick',
                            ),
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
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              l10n.document_upload_in_progress,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.appErrorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.appError.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: context.appError,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.appError,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: PrimaryActionButton(
                      key: const ValueKey('document_upload_submit'),
                      onPressed: _isSubmitting ? null : _submit,
                      text: l10n.document_upload_submit,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: context.appSuccess,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.document_upload_success_title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.document_upload_success_desc,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('document_upload_success_back'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.document_upload_success_back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
