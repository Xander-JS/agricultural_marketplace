import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_indicator.dart';
import '../../../dashboard/screens/main_dashboard_screen.dart';
import '../services/verification_service.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({Key? key}) : super(key: key);

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  final VerificationService _service = VerificationService();
  late Future<VerificationStatusData> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = _service.getCurrentVerificationStatus();
  }

  void _retry() {
    setState(() {
      _statusFuture = _service.getCurrentVerificationStatus();
    });
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
          return _buildStatusState(context, data);
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
                const SnackBar(
                  content: Text('Funcionalidad de re-carga en desarrollo.'),
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MainDashboardScreen(
                    role: data.role ?? 'desconocido',
                  ),
                ),
              );
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
      ],
    );
  }
}
