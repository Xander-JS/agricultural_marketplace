import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../../../../core/widgets/feedback/status_banner.dart';
import '../../../../core/widgets/loading/app_loading.dart';
import '../../../../core/widgets/loading/loading_indicator.dart';
import '../../../../core/widgets/brand/kus_brand_logo.dart';
import '../../../../core/widgets/misc/app_entrance.dart';
import '../../../dashboard/screens/main_dashboard_screen.dart';
import '../../widgets/document_image_picker.dart';
import '../services/document_submission_service.dart';
import '../services/verification_service.dart';
import '../widgets/review_ring.dart';
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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = widget.verificationService ?? VerificationService();
    if (widget.initialData != null) {
      _statusFuture = Future.value(widget.initialData);
    } else {
      _statusFuture = _fetchStatus();
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

  /// Consulta `verification_status` y, si el moderador ya aprobó la cuenta,
  /// avisa de inmediato para pasar al panel principal.
  Future<VerificationStatusData> _fetchStatus() async {
    final data = await _service.getCurrentVerificationStatus();
    _notifyIfApproved(data);
    return data;
  }

  bool _notifyIfApproved(VerificationStatusData data) {
    if (data.status != 'aprobado' || !mounted) return false;
    _pollTimer?.cancel();
    final onApproved = widget.onVerificationApproved;
    if (onApproved == null) return false;
    onApproved(data);
    return true;
  }

  Future<void> _checkStatusSilently() async {
    try {
      final data = await _service.getCurrentVerificationStatus();
      if (!mounted || _notifyIfApproved(data)) return;
      setState(() {
        _statusFuture = Future.value(data);
      });
    } catch (_) {}
  }

  /// Gesto de deslizar para actualizar: conserva el estado visible mientras
  /// consulta, para que el indicador no desaparezca a mitad del gesto.
  Future<void> _pullToRefresh() async {
    try {
      final data = await _service.getCurrentVerificationStatus();
      if (!mounted || _notifyIfApproved(data)) return;
      setState(() {
        _statusFuture = Future.value(data);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusFuture = Future.error(error);
      });
    }
  }

  Future<void> _refreshInPlace() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _pullToRefresh();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _retry() {
    setState(() {
      _statusFuture = _fetchStatus();
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
            key: const ValueKey('verification_status_pull_refresh'),
            onRefresh: _pullToRefresh,
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
    final visual = _visualFor(context, l10n, data);
    final isRejected = data.status == 'rechazado';
    final needsDocuments =
        isRejected ||
        (data.status == 'pendiente' && data.hasAllDocuments != true);
    final isInReview =
        !needsDocuments &&
        (data.status == 'pendiente' || data.status == 'en_revision_ia');

    if (isInReview) return _buildReviewState(context, l10n, data, visual);
    if (isRejected) return _buildRejectedState(context, l10n, data, visual);
    return _buildDecisionState(
      context,
      l10n,
      data,
      visual,
      needsDocuments: needsDocuments,
    );
  }

  _StatusVisual _visualFor(
    BuildContext context,
    AppLocalizations l10n,
    VerificationStatusData data,
  ) {
    final _StatusVisual visual;
    switch (data.status) {
      case 'pendiente' when data.hasAllDocuments:
        visual = _StatusVisual(
          title: l10n.verification_status_submitted_title,
          description: l10n.verification_status_submitted_desc,
          icon: LucideIcons.fileCheck,
          triad: context.appInfoTriad,
        );
        break;
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

    return visual;
  }

  /// Mark entrance shared by every state: a short settle with easeOutCubic,
  /// played once. The ring (when present) carries the rest of the motion.
  Widget _brandMark({required double size}) {
    return AppEntrance(
      offsetY: 0,
      beginScale: 0.94,
      curve: Curves.easeOutCubic,
      child: KusBrandLogo(
        variant: KusBrandLogoVariant.hero,
        showWordmark: false,
        onBrandStage: true,
        markSize: size,
      ),
    );
  }

  /// Waiting room after the request is submitted (pending with all three
  /// documents, or under review): the contour ring around the mark tells the
  /// user which stage is in progress; the copy says what happens next.
  Widget _buildReviewState(
    BuildContext context,
    AppLocalizations l10n,
    VerificationStatusData data,
    _StatusVisual visual,
  ) {
    final stage = data.status == 'en_revision_ia' ? 2 : 1;
    final stageLabels = [
      l10n.verification_status_track_received,
      l10n.verification_status_track_ai,
      l10n.verification_status_track_moderator,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        children: [
          ReviewRing(
            stage: stage,
            size: 152,
            semanticsLabel: l10n.verification_status_ring_semantics(
              stageLabels[stage],
            ),
            child: _brandMark(size: 72),
          ),
          const SizedBox(height: AppDimensions.space24),
          AppEntrance(
            delay: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                Text(
                  l10n.verification_status_success_msg,
                  key: const ValueKey('verification_status_submitted_msg'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.onBrand,
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                _SupportLine(
                  key: const ValueKey('verification_status_support_line'),
                  text: l10n.verification_status_support_line,
                ),
                const SizedBox(height: AppDimensions.space20),
                // The action sits with the message it acts on, so it stays
                // above the fold on short phones; the panel below is detail.
                _StageRefreshButton(
                  key: const ValueKey('verification_status_refresh'),
                  label: l10n.verification_status_update_status,
                  isRefreshing: _isRefreshing,
                  onPressed: _refreshInPlace,
                ),
                const SizedBox(height: AppDimensions.space24),
                Container(
                  key: const ValueKey('verification_status_card'),
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: BoxDecoration(
                    // A tone step above the stage, not a floating card.
                    color: AppColors.onBrand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              visual.title,
                              key: const ValueKey('verification_status_title'),
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.onBrand,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          _StagePill(
                            key: const ValueKey('verification_status_badge'),
                            label: data.verificationStatus.displayName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        visual.description,
                        key: const ValueKey('verification_status_description'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onBrandSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space20),
                      ReviewStageList(
                        stage: stage,
                        labels: stageLabels,
                        currentLabel: l10n.verification_status_track_current,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
                _StageTextButton(
                  key: const ValueKey('verification_status_logout'),
                  label: l10n.profile_logout,
                  icon: LucideIcons.logOut,
                  onPressed: _handleSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Rejected: the moderator's own words in a semantic card, an empathetic
  /// next step and one primary action that reopens document capture.
  Widget _buildRejectedState(
    BuildContext context,
    AppLocalizations l10n,
    VerificationStatusData data,
    _StatusVisual visual,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        children: [
          _brandMark(size: 64),
          const SizedBox(height: AppDimensions.space24),
          AppEntrance(
            delay: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Container(
              key: const ValueKey('verification_status_card'),
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: visual.triad.background,
                          borderRadius: AppDimensions.borderRadiusLG,
                        ),
                        child: Icon(
                          visual.icon,
                          size: 22,
                          color: visual.triad.foreground,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Text(
                          visual.title,
                          key: const ValueKey('verification_status_title'),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                      _StatusBadge(
                        key: const ValueKey('verification_status_badge'),
                        label: data.verificationStatus.displayName,
                        triad: visual.triad,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  Text(
                    l10n.verification_status_reason_label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.appTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  StatusBanner(
                    tone: StatusTone.error,
                    icon: LucideIcons.fileWarning,
                    message: visual.description,
                    messageKey: const ValueKey(
                      'verification_status_description',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    l10n.verification_status_rejected_empathy,
                    key: const ValueKey('verification_status_rejected_help'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  PrimaryActionButton(
                    key: const ValueKey('verification_upload_documents'),
                    onPressed: _openDocumentUpload,
                    text: l10n.verification_status_resubmit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
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

  /// Remaining states (documents still missing, approved, suspended,
  /// unknown): one card with the state and, when it applies, its action.
  Widget _buildDecisionState(
    BuildContext context,
    AppLocalizations l10n,
    VerificationStatusData data,
    _StatusVisual visual, {
    required bool needsDocuments,
  }) {
    Widget? cardAction;
    if (needsDocuments) {
      cardAction = PrimaryActionButton(
        key: const ValueKey('verification_upload_documents'),
        onPressed: _openDocumentUpload,
        text: l10n.verification_status_upload_docs,
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
        borderRadius: BorderRadius.circular(16),
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
                ),
                child: Icon(
                  visual.icon,
                  size: 26,
                  color: visual.triad.foreground,
                ),
              ),
              const Spacer(),
              _StatusBadge(
                key: const ValueKey('verification_status_badge'),
                label: data.verificationStatus.displayName,
                triad: visual.triad,
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
          Text(
            visual.description,
            key: const ValueKey('verification_status_description'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextSecondary,
            ),
          ),
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
        children: [
          _brandMark(size: 64),
          const SizedBox(height: AppDimensions.space24),
          card,
          const SizedBox(height: AppDimensions.space12),
          if (!needsDocuments &&
              data.status != 'aprobado' &&
              data.status != 'suspendido')
            _StageRefreshButton(
              key: const ValueKey('verification_status_refresh'),
              label: l10n.verification_status_update_status,
              isRefreshing: _isRefreshing,
              onPressed: _refreshInPlace,
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

/// Support copy under the headline. The sentence pairs what is happening
/// with what comes next ("… en curso — Te avisaremos …"); the em dash becomes
/// the line break so each half reads as its own line instead of wrapping
/// mid-thought on narrow phones.
class _SupportLine extends StatelessWidget {
  final String text;

  const _SupportLine({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final parts = text.split(' — ');
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.onBrandSecondary,
      height: 1.5,
    );
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: parts.first,
              style: style.copyWith(
                color: AppColors.onBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (parts.length > 1)
              TextSpan(text: '\n${parts.skip(1).join(' — ')}'),
          ],
        ),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

/// Small status label on the brand stage (inside the review panel).
class _StagePill extends StatelessWidget {
  final String label;

  const _StagePill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onBrand.withValues(alpha: 0.14),
        borderRadius: AppDimensions.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onBrand,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Status label on a light card, tinted with the state's semantic triad.
class _StatusBadge extends StatelessWidget {
  final String label;
  final AppSemanticTriad triad;

  const _StatusBadge({super.key, required this.label, required this.triad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12 - 2,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: AppDimensions.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: triad.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tonal action on the stage. While a status request is in
/// flight it shows a small progress mark instead of the icon, so the screen
/// keeps its content instead of flashing back to a loader.
class _StageRefreshButton extends StatelessWidget {
  final String label;
  final bool isRefreshing;
  final VoidCallback onPressed;

  const _StageRefreshButton({
    super.key,
    required this.label,
    required this.isRefreshing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.minTouchTarget + 4,
      child: TextButton.icon(
        onPressed: isRefreshing ? null : onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space20,
          ),
          backgroundColor: AppColors.onBrand.withValues(alpha: 0.12),
          foregroundColor: AppColors.onBrand,
          disabledForegroundColor: AppColors.onBrand.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusControl,
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
        icon: isRefreshing
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onBrand,
                ),
              )
            : const Icon(LucideIcons.refreshCw, size: 16),
        label: Text(label),
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
