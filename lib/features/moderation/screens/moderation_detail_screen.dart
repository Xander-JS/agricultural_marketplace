import 'package:flutter/material.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/moderation_request.dart';
import '../services/document_diagnosis_service.dart';
import '../services/document_image_service.dart';
import '../services/moderation_service.dart';
import '../widgets/document_image_preview.dart';
import '../widgets/simulated_document_diagnosis_card.dart';

/// Pantalla de detalle de una solicitud de verificación para revisión por parte de un moderador.
class ModerationDetailScreen extends StatefulWidget {
  final ModerationRequest request;
  final ModerationService? moderationService;
  final ValueChanged<ModerationRequest>? onRequestUpdated;
  final DocumentImageUrlService? documentImageService;
  final DocumentDiagnosisService? documentDiagnosisService;
  final DocumentImageWidgetBuilder? documentImageBuilder;

  const ModerationDetailScreen({
    super.key,
    required this.request,
    this.moderationService,
    this.onRequestUpdated,
    this.documentImageService,
    this.documentDiagnosisService,
    this.documentImageBuilder,
  });

  @override
  State<ModerationDetailScreen> createState() => _ModerationDetailScreenState();
}

class _ModerationDetailScreenState extends State<ModerationDetailScreen> {
  late ModerationService _service;
  late ModerationRequest _currentRequest;
  late DocumentImageUrlService _documentImageService;
  late DocumentDiagnosisService _diagnosisService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _service = widget.moderationService ?? ModerationService();
    _documentImageService =
        widget.documentImageService ?? DocumentImageUrlService();
    _diagnosisService =
        widget.documentDiagnosisService ?? const DocumentDiagnosisService();
  }

  Future<void> _handleApprove() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.moderation_confirm_approve_title,
        ),
        content: Text(
          l10n.moderation_confirm_approve_desc,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.common_cancel,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.appSuccess),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.moderation_btn_approve,
              style: TextStyle(color: context.appOnPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _service.approveRequest(
        attemptId: _currentRequest.id,
        userId: _currentRequest.userId,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final updated = _currentRequest.copyWith(
          status: UserVerificationStatus.aprobado,
          reviewedAt: DateTime.now().toUtc(),
          reviewedBy: _service.currentUserId,
        );
        setState(() {
          _currentRequest = updated;
        });
        widget.onRequestUpdated?.call(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.moderation_approved_success,
            ),
            backgroundColor: context.appSuccess,
          ),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? l10n.moderation_error_processing,
            ),
            backgroundColor: context.appError,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.common_unexpected_error(e.toString())),
          backgroundColor: context.appError,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleReject() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.moderation_confirm_reject_title,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.moderation_reject_reason_prompt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.moderation_reject_reason_hint,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.moderation_reject_reason_required;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.common_cancel,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.appError),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              l10n.moderation_btn_reject,
              style: TextStyle(color: context.appOnPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final reason = reasonController.text.trim();
    setState(() => _isSubmitting = true);

    try {
      final result = await _service.rejectRequest(
        attemptId: _currentRequest.id,
        userId: _currentRequest.userId,
        reason: reason,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final updated = _currentRequest.copyWith(
          status: UserVerificationStatus.rechazado,
          rejectionReason: reason,
          reviewedAt: DateTime.now().toUtc(),
          reviewedBy: _service.currentUserId,
        );
        setState(() {
          _currentRequest = updated;
        });
        widget.onRequestUpdated?.call(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.moderation_rejected_success,
            ),
            backgroundColor: context.appError,
          ),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? l10n.moderation_error_rejecting,
            ),
            backgroundColor: context.appError,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.common_unexpected_error(e.toString())),
          backgroundColor: context.appError,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleMarkInReview() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);

    try {
      final result = await _service.markInReview(
        attemptId: _currentRequest.id,
        userId: _currentRequest.userId,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final updated = _currentRequest.copyWith(
          status: UserVerificationStatus.enRevisionIa,
          updatedAt: DateTime.now().toUtc(),
        );
        setState(() {
          _currentRequest = updated;
        });
        widget.onRequestUpdated?.call(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.moderation_in_review_success,
            ),
            backgroundColor: context.appInfo,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? l10n.moderation_error_updating,
            ),
            backgroundColor: context.appError,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.common_unexpected_error(e.toString())),
          backgroundColor: context.appError,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moderation_detail_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Identidad del Usuario
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.appPrimary,
                          child: Text(
                            _currentRequest.fullName.isNotEmpty
                                ? _currentRequest.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: context.appOnPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentRequest.fullName,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              Text(
                                _currentRequest.phone,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.appTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(_currentRequest.status),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      l10n.moderation_lbl_role,
                      _currentRequest.userRole.displayName,
                    ),
                    if (_currentRequest.email != null &&
                        _currentRequest.email!.isNotEmpty)
                      _buildInfoRow(l10n.moderation_lbl_email, _currentRequest.email!),
                    _buildInfoRow(l10n.moderation_lbl_user_id, _currentRequest.userId),
                    _buildInfoRow(
                      l10n.moderation_lbl_submitted,
                      _currentRequest.createdAt.toLocal().toString().split(
                        '.',
                      )[0],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de Documentos Adjuntos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: context.appPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.moderation_documents_title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.appWarningContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.appWarning,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: context.appWarning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.moderation_storage_notice,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.appWarning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DocumentImagePreview(
                      key: const ValueKey('moderation_document_front'),
                      title: l10n.moderation_doc_front,
                      path: _currentRequest.documentFrontPath,
                      imageUrlService: _documentImageService,
                      imageBuilder: widget.documentImageBuilder,
                    ),
                    const SizedBox(height: 10),
                    DocumentImagePreview(
                      key: const ValueKey('moderation_document_back'),
                      title: l10n.moderation_doc_back,
                      path: _currentRequest.documentBackPath,
                      imageUrlService: _documentImageService,
                      imageBuilder: widget.documentImageBuilder,
                    ),
                    const SizedBox(height: 10),
                    DocumentImagePreview(
                      key: const ValueKey('moderation_document_selfie'),
                      title: l10n.moderation_doc_selfie,
                      path: _currentRequest.selfiePath,
                      imageUrlService: _documentImageService,
                      imageBuilder: widget.documentImageBuilder,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SimulatedDocumentDiagnosisCard(
              report: _diagnosisService.build(_currentRequest),
            ),
            const SizedBox(height: 16),

            // Motivo de Rechazo (si existe)
            if (_currentRequest.rejectionReason != null &&
                _currentRequest.rejectionReason!.isNotEmpty)
              Card(
                color: context.appErrorContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.appError),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: context.appError,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.moderation_previous_rejection,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: context.appError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentRequest.rejectionReason!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Botones de Decisión (solo si sigue pendiente o revisable)
            if (_currentRequest.isPending) ...[
              if (_currentRequest.status == UserVerificationStatus.pendiente) ...[
                OutlinedButton.icon(
                  key: const ValueKey('moderation_btn_mark_in_review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appInfo,
                    side: BorderSide(color: context.appInfo),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isSubmitting ? null : _handleMarkInReview,
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(
                    l10n.moderation_btn_mark_in_review,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('moderation_btn_reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appError,
                        side: BorderSide(color: context.appError),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _handleReject,
                      icon: const Icon(Icons.close),
                      label: Text(l10n.moderation_btn_reject),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const ValueKey('moderation_btn_approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appSuccess,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _handleApprove,
                      icon: Icon(Icons.check, color: context.appOnPrimary),
                      label: Text(
                        l10n.moderation_btn_approve,
                        style: TextStyle(color: context.appOnPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Text(
                  l10n.moderation_already_resolved,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.appTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserVerificationStatus status) {
    Color bg;
    Color fg;
    String label;

    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case UserVerificationStatus.pendiente:
        bg = context.appWarningContainer;
        fg = context.appWarning;
        label = l10n.moderation_status_pending;
        break;
      case UserVerificationStatus.enRevisionIa:
        bg = context.appInfoContainer;
        fg = context.appInfo;
        label = status.displayName;
        break;
      case UserVerificationStatus.aprobado:
        bg = context.appSuccessContainer;
        fg = context.appSuccess;
        label = l10n.moderation_status_approved;
        break;
      case UserVerificationStatus.rechazado:
        bg = context.appErrorContainer;
        fg = context.appError;
        label = l10n.moderation_status_rejected;
        break;
      case UserVerificationStatus.suspendido:
        bg = context.appPrimaryContainer;
        fg = context.appOnPrimaryContainer;
        label = l10n.moderation_status_suspended;
        break;
      case UserVerificationStatus.desconocido:
        bg = context.appSurfaceVariant;
        fg = context.appTextSecondary;
        label = l10n.moderation_status_unknown;
        break;
    }

    return Container(
      key: const ValueKey('moderation_detail_status_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
