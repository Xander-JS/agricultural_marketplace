import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_indicator.dart';
import '../../../dashboard/screens/main_dashboard_screen.dart';
import '../../widgets/document_image_picker.dart';
import '../services/document_submission_service.dart';
import '../services/verification_service.dart';
import 'document_upload_screen.dart';

class VerificationStatusScreen extends StatefulWidget {
  final VerificationStatusData? initialData;
  final void Function(VerificationStatusData data)? onVerificationApproved;
  final Future<void> Function()? onSignOut;
  final VerificationService? verificationService;
  final DocumentSubmissionService? documentSubmissionService;
  final DocumentImageSelector? imageSelector;
  final bool enableAutoPolling;

  const VerificationStatusScreen({
    super.key,
    this.initialData,
    this.onVerificationApproved,
    this.onSignOut,
    this.verificationService,
    this.documentSubmissionService,
    this.imageSelector,
    this.enableAutoPolling = true,
  });

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen>
    with WidgetsBindingObserver {
  late final VerificationService _service;
  late Future<VerificationStatusData> _statusFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = widget.verificationService ?? VerificationService();
    if (widget.initialData != null) {
      _statusFuture = Future.value(widget.initialData);
    } else {
      _statusFuture = _service.getCurrentVerificationStatus();
    }
    _startPollTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _checkStatusSilently();
    }
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    if (!widget.enableAutoPolling) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _checkStatusSilently();
      }
    });
  }

  Future<void> _checkStatusSilently() async {
    try {
      final data = await _service.getCurrentVerificationStatus();
      if (!mounted) return;
      if (data.status == 'aprobado') {
        _pollTimer?.cancel();
        if (widget.onVerificationApproved != null) {
          widget.onVerificationApproved!(data);
          return;
        }
      }
      setState(() {
        _statusFuture = Future.value(data);
      });
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _statusFuture = _service.getCurrentVerificationStatus().then((data) {
        if (data.status == 'aprobado' && mounted) {
          _pollTimer?.cancel();
          if (widget.onVerificationApproved != null) {
            widget.onVerificationApproved!(data);
          }
        }
        return data;
      });
    });
  }

  Future<void> _openDocumentUpload() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentUploadScreen(
          submissionService: widget.documentSubmissionService,
          imageSelector: widget.imageSelector,
        ),
      ),
    );
    if (!mounted) return;
    if (uploaded == true) {
      _retry();
    }
  }

  Future<void> _handleSignOut() async {
    if (widget.onSignOut != null) {
      await widget.onSignOut!();
    } else {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        try {
          await Supabase.instance.client.auth.signOut(
            scope: SignOutScope.local,
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLoading(
      child: FutureBuilder<VerificationStatusData>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString());
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _retry();
              try {
                await _statusFuture;
              } catch (_) {}
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildStatusState(context, data),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LoadingIndicator(isSpinning: true),
        const SizedBox(height: 32),
        Text(
          l10n.verification_status_checking,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.onBrand),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    final cleanError = error.replaceAll('Exception: ', '');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: context.appError, size: 80),
        const SizedBox(height: 32),
        Text(
          l10n.verification_status_error_title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.onBrand),
        ),
        const SizedBox(height: 16),
        Text(
          cleanError,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onBrandSecondary),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          key: const ValueKey('verification_status_retry_btn'),
          onPressed: _retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onBrand,
            foregroundColor: AppColors.loadingBackground,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(l10n.verification_status_retry),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _handleSignOut,
          child: Text(
            l10n.profile_logout,
            style: TextStyle(color: AppColors.onBrandSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusState(BuildContext context, VerificationStatusData data) {
    final l10n = AppLocalizations.of(context)!;
    String title = '';
    String description = '';
    IconData iconData = Icons.info_outline;
    Color statusColor = context.appTextDisabled;

    switch (data.status) {
      case 'pendiente':
        title = l10n.verification_status_pending_title;
        description = l10n.verification_status_pending_desc;
        iconData = Icons.hourglass_empty;
        statusColor = context.appWarning;
        break;
      case 'en_revision_ia':
        title = l10n.verification_status_review_title;
        description = l10n.verification_status_simulated_review;
        iconData = Icons.analytics_outlined;
        statusColor = context.appInfo;
        break;
      case 'aprobado':
        title = l10n.verification_status_approved_title;
        description = l10n.verification_status_approved_desc;
        iconData = Icons.check_circle_outline;
        statusColor = context.appSuccess;
        break;
      case 'rechazado':
        title = l10n.verification_status_rejected_title;
        description =
            data.rejectionReason ??
            l10n.verification_status_default_reject_reason;
        iconData = Icons.cancel_outlined;
        statusColor = context.appError;
        break;
      case 'suspendido':
        title = l10n.verification_status_suspended_title;
        description = l10n.verification_status_suspended_desc;
        iconData = Icons.block;
        statusColor = context.appError;
        break;
      default:
        title = l10n.verification_status_unknown_title;
        description = l10n.verification_status_unknown_desc;
        iconData = Icons.help_outline;
        statusColor = context.appTextDisabled;
    }

    final showSuccessText =
        data.status == 'pendiente' || data.status == 'en_revision_ia';
    final isSpinning =
        data.status == 'en_revision_ia' || data.status == 'pendiente';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingIndicator(isSpinning: isSpinning),
        const SizedBox(height: 32),

        if (showSuccessText) ...[
          Text(
            l10n.verification_status_success_msg,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.onBrand),
          ),
          const SizedBox(height: 48),
        ],

        Container(
          key: const ValueKey('verification_status_card'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.appShadow,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: statusColor, size: 32),
              ),
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('verification_status_badge'),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  data.verificationStatus.displayName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                key: const ValueKey('verification_status_title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                key: const ValueKey('verification_status_description'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        if (data.status == 'rechazado' ||
            (data.status == 'pendiente' && data.hasAllDocuments != true))
          ElevatedButton(
            key: const ValueKey('verification_upload_documents'),
            onPressed: _openDocumentUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onBrand,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n.verification_status_upload_docs),
          )
        else if (data.status == 'aprobado')
          ElevatedButton(
            key: const ValueKey('verification_status_enter_app'),
            onPressed: () {
              if (widget.onVerificationApproved != null) {
                widget.onVerificationApproved!(data);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        MainDashboardScreen(role: data.role ?? 'desconocido'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onBrand,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n.verification_status_enter_app),
          )
        else if (data.status != 'suspendido')
          TextButton(
            key: const ValueKey('verification_status_refresh'),
            onPressed: _retry,
            child: Text(
              l10n.verification_status_update_status,
              style: TextStyle(color: AppColors.onBrandSecondary),
            ),
          ),

        if (data.status != 'aprobado') ...[
          const SizedBox(height: 16),
          TextButton(
            key: const ValueKey('verification_status_logout'),
            onPressed: _handleSignOut,
            child: Text(
              l10n.profile_logout,
              style: TextStyle(color: AppColors.onBrandSecondary),
            ),
          ),
        ],
      ],
    );
  }
}
