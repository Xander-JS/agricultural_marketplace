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
import '../models/registration_data.dart';
import 'processing_screen.dart';

/// Paso final del registro: permite revisar, reemplazar y validar las tres
/// imágenes de verificación antes de enviar la solicitud.
class DocumentReviewScreen extends StatefulWidget {
  final RegistrationData data;
  final DocumentImageSelector? imageSelector;

  /// Permite sustituir la navegación al procesamiento en pruebas.
  final Future<void> Function()? onSubmit;

  const DocumentReviewScreen({
    super.key,
    required this.data,
    this.imageSelector,
    this.onSubmit,
  });

  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends State<DocumentReviewScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickImage({
    required String title,
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
      widget.data.isDocumentFrontValid &&
      widget.data.isDocumentBackValid &&
      widget.data.isSelfieValid;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    if (!_hasAllDocuments) {
      setState(() => _errorMessage = l10n.document_review_missing);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!();
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(data: widget.data),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = l10n.document_review_submit_error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(title: l10n.document_review_title),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.document_review_description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DocumentSelectionCard(
                      key: const ValueKey('document_review_front'),
                      title: l10n.document_front_title,
                      file: widget.data.documentFront,
                      enabled: !_isSubmitting,
                      pickButtonKey: const ValueKey(
                        'document_review_front_pick',
                      ),
                      onPick: () => _pickImage(
                        title: l10n.document_front_title,
                        preferredCameraDevice: CameraDevice.rear,
                        onSelected: (file) => widget.data.documentFront = file,
                      ),
                      onRemove: () => setState(() {
                        widget.data.documentFront = null;
                        _errorMessage = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    DocumentSelectionCard(
                      key: const ValueKey('document_review_back'),
                      title: l10n.document_back_title,
                      file: widget.data.documentBack,
                      enabled: !_isSubmitting,
                      pickButtonKey: const ValueKey(
                        'document_review_back_pick',
                      ),
                      onPick: () => _pickImage(
                        title: l10n.document_back_title,
                        preferredCameraDevice: CameraDevice.rear,
                        onSelected: (file) => widget.data.documentBack = file,
                      ),
                      onRemove: () => setState(() {
                        widget.data.documentBack = null;
                        _errorMessage = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    DocumentSelectionCard(
                      key: const ValueKey('document_review_selfie'),
                      title: l10n.document_selfie_title,
                      file: widget.data.selfie,
                      enabled: !_isSubmitting,
                      pickButtonKey: const ValueKey(
                        'document_review_selfie_pick',
                      ),
                      onPick: () => _pickImage(
                        title: l10n.document_selfie_title,
                        preferredCameraDevice: CameraDevice.front,
                        onSelected: (file) => widget.data.selfie = file,
                      ),
                      onRemove: () => setState(() {
                        widget.data.selfie = null;
                        _errorMessage = null;
                      }),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    if (_hasAllDocuments) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: context.appSuccess,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.document_review_ready,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.appSuccess,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryActionButton(
                onPressed: _isSubmitting ? null : _submit,
                text: l10n.document_review_submit,
                isLoading: _isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appErrorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appError.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: context.appError, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }
}
