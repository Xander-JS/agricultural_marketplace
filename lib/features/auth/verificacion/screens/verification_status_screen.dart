import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/cards/inset_group_card.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
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
        const SizedBox(height: AppDimensions.space24),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.onBrand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.onBrand.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              LucideIcons.cloudAlert,
              color: AppColors.onBrand,
              size: AppDimensions.iconLG,
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          Text(
            l10n.verification_status_error_title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.onBrand,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            cleanError,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onBrandSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space32),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeightPrimary,
            child: ElevatedButton(
              key: const ValueKey('verification_status_retry_btn'),
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onBrand,
                foregroundColor: context.appBrandStage,
              ),
              child: Text(l10n.verification_status_retry),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          _StageTextButton(
            label: l10n.profile_logout,
            onPressed: _handleSignOut,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusState(BuildContext context, VerificationStatusData data) {
    final l10n = AppLocalizations.of(context)!;
    final _StatusVisual visual;

    switch (data.status) {
      case 'pendiente':
        visual = _StatusVisual(
          title: l10n.verification_status_pending_title,
          description: l10n.verification_status_pending_desc,
          icon: LucideIcons.hourglass,
          triad: context.appWarningTriad,
        );
        break;
      case 'en_revision_ia':
        visual = _StatusVisual(
          title: l10n.verification_status_review_title,
          description: l10n.verification_status_simulated_review,
          icon: LucideIcons.cpu,
          triad: context.appInfoTriad,
        );
        break;
      case 'aprobado':
        visual = _StatusVisual(
          title: l10n.verification_status_approved_title,
          description: l10n.verification_status_approved_desc,
          icon: LucideIcons.badgeCheck,
          triad: context.appSuccessTriad,
        );
        break;
      case 'rechazado':
        visual = _StatusVisual(
          title: l10n.verification_status_rejected_title,
          description:
              data.rejectionReason ??
              l10n.verification_status_default_reject_reason,
          icon: LucideIcons.circleX,
          triad: context.appErrorTriad,
        );
        break;
      case 'suspendido':
        visual = _StatusVisual(
          title: l10n.verification_status_suspended_title,
          description: l10n.verification_status_suspended_desc,
          icon: LucideIcons.ban,
          triad: context.appErrorTriad,
        );
        break;
      default:
        visual = _StatusVisual(
          title: l10n.verification_status_unknown_title,
          description: l10n.verification_status_unknown_desc,
          icon: LucideIcons.circleHelp,
          triad: context.appNeutralTriad,
        );
    }

    final isRejected = data.status == 'rechazado';
    final showSuccessText =
        data.status == 'pendiente' || data.status == 'en_revision_ia';
    final isSpinning =
        data.status == 'en_revision_ia' || data.status == 'pendiente';
    final needsDocuments =
        isRejected ||
        (data.status == 'pendiente' && data.hasAllDocuments != true);

    // Where the account stands on the real review path:
    // registration received -> KUS Vision analysis -> moderator decision.
    final int? trackStage = switch (data.status) {
      'pendiente' => data.hasAllDocuments == true ? 1 : 0,
      'en_revision_ia' => 2,
      'aprobado' => 3,
      _ => null,
    };

    Widget? cardAction;
    if (needsDocuments) {
      cardAction = PrimaryActionButton(
        key: const ValueKey('verification_upload_documents'),
        onPressed: _openDocumentUpload,
        text: isRejected
            ? l10n.verification_status_resubmit
            : l10n.verification_status_upload_docs,
      );
    } else if (data.status == 'aprobado') {
      cardAction = PrimaryActionButton(
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
        text: l10n.verification_status_enter_app,
      );
    }

    final card = Container(
      key: const ValueKey('verification_status_card'),
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius + 4),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: visual.triad.background,
                  borderRadius: AppDimensions.borderRadiusLG,
                  border: Border.all(color: visual.triad.border),
                ),
                child: Icon(
                  visual.icon,
                  size: 26,
                  color: visual.triad.foreground,
                ),
              ),
              const Spacer(),
              Container(
                key: const ValueKey('verification_status_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12 - 2,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: visual.triad.background,
                  borderRadius: AppDimensions.borderRadiusFull,
                  border: Border.all(color: visual.triad.border),
                ),
                child: Text(
                  data.verificationStatus.displayName,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: visual.triad.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            visual.title,
            key: const ValueKey('verification_status_title'),
            style: AppTextStyles.displaySmall.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          if (isRejected) ...[
            Text(
              l10n.verification_status_reason_label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            StatusBanner(
              tone: StatusTone.error,
              icon: LucideIcons.fileWarning,
              message: visual.description,
              messageKey: const ValueKey('verification_status_description'),
            ),
          ] else
            Text(
              visual.description,
              key: const ValueKey('verification_status_description'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          if (trackStage != null) ...[
            const SizedBox(height: AppDimensions.space16),
            _ReviewTrack(
              stage: trackStage,
              labels: [
                l10n.verification_status_track_received,
                l10n.verification_status_track_ai,
                l10n.verification_status_track_moderator,
              ],
            ),
          ],
          if (cardAction != null) ...[
            const SizedBox(height: AppDimensions.space20),
            cardAction,
          ],
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(isSpinning: isSpinning),
          const SizedBox(height: AppDimensions.space24),
          if (showSuccessText) ...[
            Text(
              l10n.verification_status_success_msg,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.onBrand,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
          ],
          card,
          const SizedBox(height: AppDimensions.space16),
          if (!needsDocuments &&
              data.status != 'aprobado' &&
              data.status != 'suspendido')
            _StageTextButton(
              key: const ValueKey('verification_status_refresh'),
              label: l10n.verification_status_update_status,
              icon: LucideIcons.refreshCw,
              onPressed: _retry,
            ),
          if (data.status != 'aprobado')
            _StageTextButton(
              key: const ValueKey('verification_status_logout'),
              label: l10n.profile_logout,
              icon: LucideIcons.logOut,
              onPressed: _handleSignOut,
            ),
        ],
      ),
    );
  }
}

class _StatusVisual {
  final String title;
  final String description;
  final IconData icon;
  final AppSemanticTriad triad;

  const _StatusVisual({
    required this.title,
    required this.description,
    required this.icon,
    required this.triad,
  });
}

/// Three-stop review path drawn as a compact horizontal stepper. Stops
/// before [stage] are complete, the stop at [stage] is in progress and later
/// stops are still ahead; a [stage] past the last stop marks all complete.
class _ReviewTrack extends StatelessWidget {
  final int stage;
  final List<String> labels;

  const _ReviewTrack({required this.stage, required this.labels});

  @override
  Widget build(BuildContext context) {
    final done = context.appSuccessTriad.foreground;
    final current = context.appInfoTriad.foreground;
    final ahead = context.appTextMuted;

    Widget connector(bool lit, {required bool visible}) => Expanded(
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: !visible
              ? AppColors.transparent
              : lit
              ? done
              : context.appBorder,
          borderRadius: AppDimensions.borderRadiusFull,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: AppDimensions.borderRadiusLG,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      connector(i <= stage, visible: i > 0),
                      const SizedBox(width: 6),
                      Icon(
                        i < stage
                            ? LucideIcons.circleCheck
                            : i == stage
                            ? LucideIcons.clock
                            : LucideIcons.circleDashed,
                        size: 22,
                        color: i < stage
                            ? done
                            : i == stage
                            ? current
                            : ahead,
                      ),
                      const SizedBox(width: 6),
                      connector(i < stage, visible: i < labels.length - 1),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: i <= stage
                            ? context.appTextPrimary
                            : context.appTextSecondary,
                        fontWeight: i == stage
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Low-emphasis action on the brand stage (refresh, sign out).
class _StageTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _StageTextButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: AppColors.onBrand,
      minimumSize: const Size(0, AppDimensions.minTouchTarget),
    );
    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
