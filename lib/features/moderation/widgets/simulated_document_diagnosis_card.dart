import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/localization/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_action_button.dart';
import '../../../core/widgets/buttons/secondary_action_button.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../services/document_diagnosis_service.dart';

/// Decision a moderator can take from the KUS Vision panel.
enum DiagnosisDecision { approve, reject, markInReview }

/// "KUS Vision" telemetry and verification panel for the moderator.
///
/// Every indicator comes from [DocumentDiagnosisReport]: file presence and
/// path validity, independence of the files and whether the profile has an
/// email. Checks the report does not perform (legibility, selfie-to-ID
/// match) are shown as the moderator's visual review, never as passed. The
/// decision area at the bottom appears only when decision callbacks are
/// supplied; [busyDecision] puts a micro-loader on the action in flight and
/// holds the other actions disabled until it settles.
class SimulatedDocumentDiagnosisCard extends StatelessWidget {
  final DocumentDiagnosisReport report;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onMarkInReview;
  final DiagnosisDecision? busyDecision;

  const SimulatedDocumentDiagnosisCard({
    super.key,
    required this.report,
    this.onApprove,
    this.onReject,
    this.onMarkInReview,
    this.busyDecision,
  });

  bool get _hasDecisions =>
      onApprove != null || onReject != null || onMarkInReview != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ai = context.appInfoTriad;
    final observations = report.observations;
    final sharedPaths = observations.contains(
      DocumentDiagnosisObservation.sharedDocumentPaths,
    );
    final noEmail = observations.contains(
      DocumentDiagnosisObservation.emailNotProvided,
    );
    final idle = busyDecision == null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius),
        border: Border.all(color: ai.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: AI identity on the soft sapphire ground.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: ai.background,
              border: Border(bottom: BorderSide(color: ai.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: AppDimensions.borderRadiusMD,
                        border: Border.all(color: ai.border),
                      ),
                      child: Icon(
                        LucideIcons.scanFace,
                        size: 20,
                        color: ai.foreground,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: AppDimensions.borderRadiusFull,
                        border: Border.all(color: ai.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 13,
                            color: ai.foreground,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.moderation_diagnosis_simulated,
                            key: const ValueKey(
                              'moderation_diagnosis_simulated_badge',
                            ),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: ai.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  l10n.moderation_diagnosis_title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  l10n.moderation_diagnosis_disclaimer,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Telemetry rows.
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RowGroup(
                  children: [
                    _TelemetryRow(
                      icon: LucideIcons.fileScan,
                      tone: report.hasAllRequiredDocuments
                          ? _Tone.ok
                          : _Tone.warning,
                      label: l10n.moderation_diagnosis_available_label,
                      value:
                          '${report.availableDocuments}/${report.totalDocuments}',
                      tabular: true,
                    ),
                    for (final document in report.documents)
                      _TelemetryRow(
                        icon: document.isAvailable
                            ? LucideIcons.circleCheck
                            : LucideIcons.circleX,
                        tone: document.isAvailable ? _Tone.ok : _Tone.error,
                        label: _documentLabel(document.type, l10n),
                        value: document.isAvailable
                            ? l10n.moderation_diagnosis_present
                            : l10n.moderation_diagnosis_missing,
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                _RowGroup(
                  children: [
                    _TelemetryRow(
                      icon: sharedPaths
                          ? LucideIcons.triangleAlert
                          : LucideIcons.circleCheck,
                      tone: sharedPaths ? _Tone.warning : _Tone.ok,
                      label: l10n.moderation_diagnosis_files_independent,
                      value: sharedPaths
                          ? l10n.moderation_diagnosis_value_review
                          : l10n.moderation_diagnosis_value_verified,
                    ),
                    _TelemetryRow(
                      icon: noEmail
                          ? LucideIcons.triangleAlert
                          : LucideIcons.circleCheck,
                      tone: noEmail ? _Tone.warning : _Tone.ok,
                      label: l10n.moderation_diagnosis_contact,
                      value: noEmail
                          ? l10n.moderation_diagnosis_value_no_email
                          : l10n.moderation_diagnosis_value_email,
                    ),
                    _TelemetryRow(
                      icon: LucideIcons.clock,
                      tone: _Tone.ai,
                      label: l10n.moderation_diagnosis_legibility,
                      value: l10n.moderation_diagnosis_value_visual,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.userCheck,
                      size: 16,
                      color: context.appPrimary,
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Expanded(
                      child: Text(
                        l10n.moderation_diagnosis_pending,
                        key: const ValueKey(
                          'moderation_diagnosis_pending_human',
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (observations.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space20),
                  _SectionTitle(l10n.moderation_diagnosis_observations_title),
                  ...observations.map(
                    (observation) => _Note(
                      icon: LucideIcons.eye,
                      text: _observationText(observation, l10n),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.space16),
                _SectionTitle(l10n.moderation_diagnosis_limitations_title),
                _Note(
                  icon: LucideIcons.circleCheck,
                  text: l10n.moderation_diagnosis_limit_authenticity,
                ),
                _Note(
                  icon: LucideIcons.scanEye,
                  text: l10n.moderation_diagnosis_limit_biometrics,
                ),
                _Note(
                  icon: LucideIcons.fileCheck,
                  text: l10n.moderation_diagnosis_limit_external,
                ),
                _Note(
                  icon: LucideIcons.cpu,
                  text: l10n.moderation_diagnosis_limit_auto,
                ),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.shieldCheck,
                        size: 16,
                        color: ai.foreground,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Expanded(
                      child: Text(
                        l10n.moderation_diagnosis_no_auto,
                        key: const ValueKey('moderation_diagnosis_no_auto'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ai.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Moderator decision.
          if (_hasDecisions) ...[
            Divider(height: 1, color: context.appDivider),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(l10n.moderation_diagnosis_decision_title),
                  const SizedBox(height: AppDimensions.space4),
                  if (onMarkInReview != null) ...[
                    SecondaryActionButton(
                      key: const ValueKey('moderation_btn_mark_in_review'),
                      tone: SecondaryActionTone.ai,
                      onPressed: idle ? onMarkInReview : null,
                      isLoading: busyDecision == DiagnosisDecision.markInReview,
                      icon: LucideIcons.scanEye,
                      text: l10n.moderation_btn_mark_in_review,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryActionButton(
                          key: const ValueKey('moderation_btn_reject'),
                          tone: SecondaryActionTone.destructive,
                          onPressed: idle ? onReject : null,
                          isLoading: busyDecision == DiagnosisDecision.reject,
                          icon: LucideIcons.x,
                          text: l10n.moderation_btn_reject,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: PrimaryActionButton(
                          key: const ValueKey('moderation_btn_approve'),
                          onPressed: idle ? onApprove : null,
                          isLoading: busyDecision == DiagnosisDecision.approve,
                          text: l10n.moderation_btn_approve,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _observationText(
    DocumentDiagnosisObservation observation,
    AppLocalizations l10n,
  ) {
    return switch (observation) {
      DocumentDiagnosisObservation.manualProfileReview =>
        l10n.moderation_diagnosis_obs_profile,
      DocumentDiagnosisObservation.missingDocuments =>
        l10n.moderation_diagnosis_obs_missing_docs,
      DocumentDiagnosisObservation.sharedDocumentPaths =>
        l10n.moderation_diagnosis_obs_shared_paths,
      DocumentDiagnosisObservation.emailNotProvided =>
        l10n.moderation_diagnosis_obs_email,
    };
  }

  String _documentLabel(
    DocumentDiagnosisDocumentType type,
    AppLocalizations l10n,
  ) {
    switch (type) {
      case DocumentDiagnosisDocumentType.front:
        return l10n.moderation_doc_front;
      case DocumentDiagnosisDocumentType.back:
        return l10n.moderation_doc_back;
      case DocumentDiagnosisDocumentType.selfie:
        return l10n.moderation_doc_selfie;
    }
  }
}

enum _Tone { ok, warning, error, ai }

/// iOS grouped block of rows separated by inset hairlines.
class _RowGroup extends StatelessWidget {
  final List<Widget> children;

  const _RowGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: AppDimensions.borderRadiusControl,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 40, color: context.appDivider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final IconData icon;
  final _Tone tone;
  final String label;
  final String value;
  final bool tabular;

  const _TelemetryRow({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    final triad = switch (tone) {
      _Tone.ok => context.appSuccessTriad,
      _Tone.warning => context.appWarningTriad,
      _Tone.error => context.appErrorTriad,
      _Tone.ai => context.appInfoTriad,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: triad.foreground),
            const SizedBox(width: AppDimensions.space12 - 2),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: triad.text,
                fontWeight: FontWeight.w700,
                fontFeatures: tabular ? AppTextStyles.tabularFigures : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: context.appTextPrimary,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: context.appTextSecondary),
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
