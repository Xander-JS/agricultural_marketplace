import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_indicator.dart';
import '../../../dashboard/screens/main_dashboard_screen.dart';
import '../services/verification_service.dart';

class VerificationStatusScreen extends StatefulWidget {
  final VerificationStatusData? initialData;
  final void Function(VerificationStatusData data)? onVerificationApproved;
  final Future<void> Function()? onSignOut;
  final VerificationService? verificationService;
  final bool enableAutoPolling;

  const VerificationStatusScreen({
    super.key,
    this.initialData,
    this.onVerificationApproved,
    this.onSignOut,
    this.verificationService,
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
      _statusFuture = _service.getCurrentVerificationStatus();
    });
  }

  Future<void> _handleSignOut() async {
    if (widget.onSignOut != null) {
      await widget.onSignOut!();
    } else {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        try {
          await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
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
          return SingleChildScrollView(
            child: _buildStatusState(context, data),
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
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
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
        const Icon(Icons.error_outline, color: AppColors.error, size: 80),
        const SizedBox(height: 32),
        Text(
          l10n.verification_status_error_title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          cleanError,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
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
            style: const TextStyle(color: Colors.white70),
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
    Color statusColor = Colors.grey;

    switch (data.status) {
      case 'pendiente':
        title = l10n.verification_status_pending_title;
        description = l10n.verification_status_pending_desc;
        iconData = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
      case 'en_revision_ia':
        title = l10n.verification_status_review_title;
        description = l10n.verification_status_review_desc;
        iconData = Icons.analytics_outlined;
        statusColor = AppColors.info;
        break;
      case 'aprobado':
        title = l10n.verification_status_approved_title;
        description = l10n.verification_status_approved_desc;
        iconData = Icons.check_circle_outline;
        statusColor = AppColors.success;
        break;
      case 'rechazado':
        title = l10n.verification_status_rejected_title;
        description = data.rejectionReason ?? l10n.verification_status_default_reject_reason;
        iconData = Icons.cancel_outlined;
        statusColor = AppColors.error;
        break;
      case 'suspendido':
        title = l10n.verification_status_suspended_title;
        description = l10n.verification_status_suspended_desc;
        iconData = Icons.block;
        statusColor = AppColors.error;
        break;
      default:
        title = l10n.verification_status_unknown_title;
        description = l10n.verification_status_unknown_desc;
        iconData = Icons.help_outline;
        statusColor = Colors.grey;
    }

    final showSuccessText =
        data.status == 'pendiente' || data.status == 'en_revision_ia';
    final isSpinning = data.status == 'en_revision_ia' || data.status == 'pendiente';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingIndicator(isSpinning: isSpinning),
        const SizedBox(height: 32),

        if (showSuccessText) ...[
          Text(
            l10n.verification_status_success_msg,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 48),
        ],

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: statusColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        if (data.status == 'rechazado' || data.status == 'pendiente')
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.verification_status_reupload_coming_soon),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n.verification_status_upload_docs),
          )
        else if (data.status == 'aprobado')
          ElevatedButton(
            onPressed: () {
              if (widget.onVerificationApproved != null) {
                widget.onVerificationApproved!(data);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MainDashboardScreen(
                      role: data.role ?? 'desconocido',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.loadingBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(l10n.verification_status_enter_app),
          )
        else
          TextButton(
            onPressed: _retry,
            child: Text(
              l10n.verification_status_update_status,
              style: const TextStyle(color: Colors.white70),
            ),
          ),

        if (data.status != 'aprobado') ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              l10n.profile_logout,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ],
    );
  }
}
