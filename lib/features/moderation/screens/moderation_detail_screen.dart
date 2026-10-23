import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/avatars/user_avatar.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../models/moderation_request.dart';
import '../services/document_diagnosis_service.dart';
import '../services/document_image_service.dart';
import '../services/moderation_service.dart';
import '../widgets/document_image_preview.dart';
import '../widgets/simulated_document_diagnosis_card.dart';
import '../widgets/verification_status_badge.dart';

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
  DiagnosisDecision? _busyDecision;

  void _setBusy(DiagnosisDecision? decision) {
    setState(() {
      _busyDecision = decision;
      _isSubmitting = decision != null;
    });
  }

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
        title: Text(l10n.moderation_confirm_approve_title),
        content: Text(l10n.moderation_confirm_approve_desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.moderation_btn_approve),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _setBusy(DiagnosisDecision.approve);

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

        showAppSnackBar(
          context,
          l10n.moderation_approved_success,
          tone: StatusTone.success,
        );
        Navigator.of(context).pop(updated);
      } else {
        showAppSnackBar(
          context,
          result.errorMessage ?? l10n.moderation_error_processing,
          tone: StatusTone.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.common_unexpected_error(e.toString()),
        tone: StatusTone.error,
      );
    } finally {
      if (mounted) _setBusy(null);
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
        title: Text(l10n.moderation_confirm_reject_title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.moderation_reject_reason_prompt),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.moderation_reject_reason_hint,
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
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appError,
              foregroundColor: context.appColorScheme.onError,
              minimumSize: const Size(0, AppDimensions.buttonHeightMedium),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l10n.moderation_btn_reject),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final reason = reasonController.text.trim();
    _setBusy(DiagnosisDecision.reject);

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

        showAppSnackBar(
          context,
          l10n.moderation_rejected_success,
          tone: StatusTone.error,
        );
        Navigator.of(context).pop(updated);
      } else {
        showAppSnackBar(
          context,
          result.errorMessage ?? l10n.moderation_error_rejecting,
          tone: StatusTone.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.common_unexpected_error(e.toString()),
        tone: StatusTone.error,
      );
    } finally {
      if (mounted) _setBusy(null);
    }
  }

  Future<void> _handleMarkInReview() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context)!;
    _setBusy(DiagnosisDecision.markInReview);

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

        showAppSnackBar(
          context,
          l10n.moderation_in_review_success,
          tone: StatusTone.info,
        );
      } else {
        showAppSnackBar(
          context,
          result.errorMessage ?? l10n.moderation_error_updating,
          tone: StatusTone.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        l10n.common_unexpected_error(e.toString()),
        tone: StatusTone.error,
      );
    } finally {
      if (mounted) _setBusy(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = _currentRequest;
    final rejection = request.rejectionReason;
    final hasEmail = request.email != null && request.email!.isNotEmpty;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(title: l10n.moderation_detail_title),
      // Non-lazy on purpose: the decision sits after all the evidence and
      // must exist in the tree even before it is scrolled into view.
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppDimensions.space16,
          AppDimensions.space8,
          AppDimensions.space16,
          AppDimensions.space32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identidad del solicitante
            InsetGroupCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const UserAvatar(radius: 26),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.fullName,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              request.phone,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.appTextSecondary,
                                fontFeatures: AppTextStyles.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _buildStatusBadge(request.status),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Divider(height: 1, color: context.appDivider),
                  _buildInfoRow(
                    l10n.moderation_lbl_role,
                    request.userRole.displayName,
                  ),
                  if (hasEmail)
                    _buildInfoRow(l10n.moderation_lbl_email, request.email!),
                  _buildInfoRow(l10n.moderation_lbl_user_id, request.userId),
                  _buildInfoRow(
                    l10n.moderation_lbl_submitted,
                    formatModerationDate(context, request.createdAt),
                    last: true,
                  ),
                ],
              ),
            ),

            // Motivo de rechazo previo (si existe)
            if (rejection != null && rejection.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              StatusBanner(
                tone: StatusTone.error,
                icon: LucideIcons.fileWarning,
                title: l10n.moderation_previous_rejection,
                message: rejection,
              ),
            ],

            // Documentos adjuntos
            const SizedBox(height: AppDimensions.space24),
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.space4,
                bottom: AppDimensions.space12,
              ),
              child: Text(
                l10n.moderation_documents_title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
            ),
            StatusBanner(
              tone: StatusTone.info,
              icon: LucideIcons.lockKeyhole,
              message: l10n.moderation_storage_notice,
            ),
            const SizedBox(height: AppDimensions.space12),
            DocumentImagePreview(
              key: const ValueKey('moderation_document_front'),
              title: l10n.moderation_doc_front,
              path: request.documentFrontPath,
              imageUrlService: _documentImageService,
              imageBuilder: widget.documentImageBuilder,
            ),
            const SizedBox(height: AppDimensions.space12),
            DocumentImagePreview(
              key: const ValueKey('moderation_document_back'),
              title: l10n.moderation_doc_back,
              path: request.documentBackPath,
              imageUrlService: _documentImageService,
              imageBuilder: widget.documentImageBuilder,
            ),
            const SizedBox(height: AppDimensions.space12),
            DocumentImagePreview(
              key: const ValueKey('moderation_document_selfie'),
              title: l10n.moderation_doc_selfie,
              path: request.selfiePath,
              imageUrlService: _documentImageService,
              imageBuilder: widget.documentImageBuilder,
            ),

            // Panel KUS Vision con la decisión del moderador al final de la
            // evidencia (solo mientras la solicitud sigue abierta).
            const SizedBox(height: AppDimensions.space24),
            SimulatedDocumentDiagnosisCard(
              report: _diagnosisService.build(request),
              busyDecision: _busyDecision,
              onApprove: request.isPending ? _handleApprove : null,
              onReject: request.isPending ? _handleReject : null,
              onMarkInReview: request.status == UserVerificationStatus.pendiente
                  ? _handleMarkInReview
                  : null,
            ),

            if (!request.isPending) ...[
              const SizedBox(height: AppDimensions.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.lockKeyhole,
                    size: 15,
                    color: context.appTextSecondary,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Flexible(
                    child: Text(
                      l10n.moderation_already_resolved,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool last = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.appDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserVerificationStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (status) {
      UserVerificationStatus.pendiente => l10n.moderation_status_pending,
      UserVerificationStatus.enRevisionIa => status.displayName,
      UserVerificationStatus.aprobado => l10n.moderation_status_approved,
      UserVerificationStatus.rechazado => l10n.moderation_status_rejected,
      UserVerificationStatus.suspendido => l10n.moderation_status_suspended,
      UserVerificationStatus.desconocido => l10n.moderation_status_unknown,
    };

    return verificationStatusBadge(
      context,
      status,
      key: const ValueKey('moderation_detail_status_badge'),
      label: label,
    );
  }
}
