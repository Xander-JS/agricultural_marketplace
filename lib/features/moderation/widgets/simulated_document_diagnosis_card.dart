import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/localization/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../services/document_diagnosis_service.dart';

/// Decision a moderator can take from the detail screen's action bar.
enum DiagnosisDecision { approve, reject, markInReview }

/// "KUS Vision" telemetry and verification panel for the moderator.
///
/// Every indicator comes from [DocumentDiagnosisReport]: file presence and
/// path validity, independence of the files and whether the profile has an
/// email. Checks the report does not perform (legibility, selfie-to-ID
/// match) are shown as the moderator's visual review, never as passed.
///
/// The panel is monochrome: passed checks stay graphite and only a warning
/// or a missing file takes a hue, so the eye lands on what needs review.
/// The decision itself lives in the detail screen's fixed action bar.
class SimulatedDocumentDiagnosisCard extends StatelessWidget {
  final DocumentDiagnosisReport report;

  const SimulatedDocumentDiagnosisCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final observations = report.observations;
    final sharedPaths = observations.contains(
      DocumentDiagnosisObservation.sharedDocumentPaths,
    );
    final noEmail = observations.contains(
      DocumentDiagnosisObservation.emailNotProvided,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: report identity, no tinted ground.
        Row(
          children: [
            const IconSquircle(icon: LucideIcons.scanFace, size: 40),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                l10n.moderation_diagnosis_title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.appIconTriad.background,
                borderRadius: AppDimensions.borderRadiusFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 13,
                    color: context.appTextSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.moderation_diagnosis_simulated,
                    key: const ValueKey('moderation_diagnosis_simulated_badge'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          l10n.moderation_diagnosis_disclaimer,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.space16),

        // Telemetry rows.
        _RowGroup(
          children: [
            _TelemetryRow(
              icon: LucideIcons.fileScan,
              tone: report.hasAllRequiredDocuments ? _Tone.ok : _Tone.warning,
              label: l10n.moderation_diagnosis_available_label,
              value: '${report.availableDocuments}/${report.totalDocuments}',
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
              icon: LucideIcons.scanEye,
              tone: _Tone.ok,
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
              color: context.appTextSecondary,
            ),
            const SizedBox(width: AppDimensions.space8),
            Expanded(
              child: Text(
                l10n.moderation_diagnosis_pending,
                key: const ValueKey('moderation_diagnosis_pending_human'),
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
                color: context.appTextSecondary,
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Expanded(
              child: Text(
                l10n.moderation_diagnosis_no_auto,
                key: const ValueKey('moderation_diagnosis_no_auto'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
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

enum _Tone { ok, warning, error }

/// iOS grouped block of rows separated by inset hairlines.
class _RowGroup extends StatelessWidget {
  final List<Widget> children;

  const _RowGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppDimensions.borderRadiusControl,
        border: Border.all(color: context.appBorder),
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
    final (Color iconColor, Color valueColor) = switch (tone) {
      _Tone.ok => (context.appTextSecondary, context.appTextPrimary),
      _Tone.warning => (context.appWarning, context.appWarningText),
      _Tone.error => (context.appErrorText, context.appErrorText),
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
            Icon(icon, size: 18, color: iconColor),
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
                color: valueColor,
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
