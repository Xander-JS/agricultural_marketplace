import 'package:flutter/material.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/moderation_request.dart';
import '../services/moderation_service.dart';

/// Pantalla de detalle de una solicitud de verificación para revisión por parte de un moderador.
class ModerationDetailScreen extends StatefulWidget {
  final ModerationRequest request;
  final ModerationService? moderationService;
  final ValueChanged<ModerationRequest>? onRequestUpdated;

  const ModerationDetailScreen({
    super.key,
    required this.request,
    this.moderationService,
    this.onRequestUpdated,
  });

  @override
  State<ModerationDetailScreen> createState() => _ModerationDetailScreenState();
}

class _ModerationDetailScreenState extends State<ModerationDetailScreen> {
  late ModerationService _service;
  late ModerationRequest _currentRequest;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _service = widget.moderationService ?? ModerationService();
  }

  Future<void> _handleApprove() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.moderation_confirm_approve_title ?? 'Confirmar Aprobación'),
        content: Text(
          l10n?.moderation_confirm_approve_desc ??
              '¿Estás seguro de que deseas aprobar esta solicitud? El usuario obtendrá acceso a las funcionalidades comerciales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.verification_status_retry == 'Reintentar' ? 'Cancelar' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n?.moderation_btn_approve ?? 'Aprobar',
              style: const TextStyle(color: Colors.white),
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
            content: Text(l10n?.moderation_approved_success ?? 'Solicitud aprobada con éxito.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (l10n?.verification_status_error_title ?? 'Error al procesar la solicitud'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleReject() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.moderation_confirm_reject_title ?? 'Rechazar Solicitud'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.moderation_reject_reason_prompt ??
                    'Indica el motivo del rechazo para que el usuario pueda corregirlo:',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n?.moderation_reject_reason_hint ??
                      'Ej. Documento borroso o fecha de vencimiento ilegible',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n?.moderation_reject_reason_required ??
                        'El motivo de rechazo es obligatorio.';
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
            child: Text(l10n?.verification_status_retry == 'Reintentar' ? 'Cancelar' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              l10n?.moderation_btn_reject ?? 'Rechazar',
              style: const TextStyle(color: Colors.white),
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
            content: Text(l10n?.moderation_rejected_success ?? 'Solicitud rechazada correctamente.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (l10n?.verification_status_error_title ?? 'Error al rechazar solicitud'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.moderation_detail_title ?? 'Detalle de Solicitud'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Identidad del Usuario
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          child: Text(
                            _currentRequest.fullName.isNotEmpty
                                ? _currentRequest.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentRequest.fullName,
                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _currentRequest.phone,
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(_currentRequest.status),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(l10n?.moderation_lbl_role ?? 'Rol:', _currentRequest.userRole.displayName),
                    if (_currentRequest.email != null && _currentRequest.email!.isNotEmpty)
                      _buildInfoRow('Email:', _currentRequest.email!),
                    _buildInfoRow('User ID:', _currentRequest.userId),
                    _buildInfoRow(
                      l10n?.moderation_lbl_submitted ?? 'Enviado:',
                      _currentRequest.createdAt.toLocal().toString().split('.')[0],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta de Documentos Adjuntos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, color: AppColors.lightPrimary),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.moderation_documents_title ?? 'Documentos Presentados',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n?.moderation_storage_notice ??
                                  'Archivos locales/simulados. La integración con Supabase Storage se completará en la Fase 2.',
                              style: AppTextStyles.bodySmall.copyWith(color: isDark ? Colors.amber[200] : Colors.amber[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentTile(
                      l10n?.moderation_doc_front ?? 'Cédula (Frente)',
                      _currentRequest.documentFrontPath,
                    ),
                    _buildDocumentTile(
                      l10n?.moderation_doc_back ?? 'Cédula (Dorso)',
                      _currentRequest.documentBackPath,
                    ),
                    _buildDocumentTile(
                      l10n?.moderation_doc_selfie ?? 'Selfie Facial',
                      _currentRequest.selfiePath,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Motivo de Rechazo (si existe)
            if (_currentRequest.rejectionReason != null && _currentRequest.rejectionReason!.isNotEmpty)
              Card(
                color: AppColors.error.withValues(alpha: 0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.error),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.moderation_previous_rejection ?? 'Motivo de Rechazo Registrado',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.error,
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
            if (_currentRequest.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _handleReject,
                      icon: const Icon(Icons.close),
                      label: Text(l10n?.moderation_btn_reject ?? 'Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _handleApprove,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        l10n?.moderation_btn_approve ?? 'Aprobar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  l10n?.moderation_already_resolved ??
                      'Esta solicitud ya fue resuelta y no admite nuevas modificaciones inmediatas.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                ),
              ),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String title, String? path) {
    final hasDoc = path != null && path.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        hasDoc ? Icons.check_circle_outline : Icons.cancel_outlined,
        color: hasDoc ? AppColors.success : Colors.grey,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        hasDoc ? path : 'No proporcionado',
        style: TextStyle(color: hasDoc ? null : Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildStatusBadge(UserVerificationStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case UserVerificationStatus.pendiente:
        bg = Colors.orange.withValues(alpha: 0.2);
        fg = Colors.orange[800]!;
        label = 'Pendiente';
        break;
      case UserVerificationStatus.enRevisionIa:
        bg = Colors.blue.withValues(alpha: 0.2);
        fg = Colors.blue[800]!;
        label = 'En Revisión';
        break;
      case UserVerificationStatus.aprobado:
        bg = Colors.green.withValues(alpha: 0.2);
        fg = Colors.green[800]!;
        label = 'Aprobado';
        break;
      case UserVerificationStatus.rechazado:
        bg = Colors.red.withValues(alpha: 0.2);
        fg = Colors.red[800]!;
        label = 'Rechazado';
        break;
      case UserVerificationStatus.suspendido:
        bg = Colors.purple.withValues(alpha: 0.2);
        fg = Colors.purple[800]!;
        label = 'Suspendido';
        break;
      case UserVerificationStatus.desconocido:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey[800]!;
        label = 'Desconocido';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
