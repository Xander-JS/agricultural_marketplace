import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/document_diagnosis_service.dart';

/// Presenta el informe documental demostrativo al moderador, dejando explícito
/// que es SIMULADO y que la decisión final es siempre humana.
class SimulatedDocumentDiagnosisCard extends StatelessWidget {
  final DocumentDiagnosisReport report;

  const SimulatedDocumentDiagnosisCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.moderation_diagnosis_title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    l10n.moderation_diagnosis_simulated,
                    key: const ValueKey('moderation_diagnosis_simulated_badge'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.moderation_diagnosis_disclaimer,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ...report.documents.map(
              (document) => _buildDocumentRow(document, l10n),
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.moderation_diagnosis_available_label} '
              '${report.availableDocuments}/${report.totalDocuments}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.moderation_diagnosis_pending,
                key: const ValueKey('moderation_diagnosis_pending_human'),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
            if (report.observations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.moderation_diagnosis_observations_title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ...report.observations.map(
                (observation) => _buildObservation(observation, l10n),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.moderation_diagnosis_limitations_title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            _buildBullet(l10n.moderation_diagnosis_limit_authenticity),
            _buildBullet(l10n.moderation_diagnosis_limit_biometrics),
            _buildBullet(l10n.moderation_diagnosis_limit_external),
            _buildBullet(l10n.moderation_diagnosis_limit_auto),
            const SizedBox(height: 10),
            Text(
              l10n.moderation_diagnosis_no_auto,
              key: const ValueKey('moderation_diagnosis_no_auto'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(
    DocumentDiagnosisDocument document,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            document.isAvailable
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 18,
            color: document.isAvailable ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _documentLabel(document.type, l10n),
              style: AppTextStyles.bodySmall,
            ),
          ),
          Text(
            document.isAvailable
                ? l10n.moderation_diagnosis_present
                : l10n.moderation_diagnosis_missing,
            style: AppTextStyles.labelSmall.copyWith(
              color: document.isAvailable ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservation(
    DocumentDiagnosisObservation observation,
    AppLocalizations l10n,
  ) {
    final message = switch (observation) {
      DocumentDiagnosisObservation.manualProfileReview =>
        l10n.moderation_diagnosis_obs_profile,
      DocumentDiagnosisObservation.missingDocuments =>
        l10n.moderation_diagnosis_obs_missing_docs,
      DocumentDiagnosisObservation.sharedDocumentPaths =>
        l10n.moderation_diagnosis_obs_shared_paths,
      DocumentDiagnosisObservation.emailNotProvided =>
        l10n.moderation_diagnosis_obs_email,
    };
    return _buildBullet(message);
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: AppColors.warning),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
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
