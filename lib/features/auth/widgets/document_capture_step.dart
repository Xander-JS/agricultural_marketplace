import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/buttons/primary_action_button.dart';
import '../../../core/widgets/buttons/secondary_action_button.dart';
import '../../../core/widgets/info/tip_pill.dart';
import '../../../core/widgets/scanner/scanner_viewfinder.dart';
import 'registration_step_scaffold.dart';

/// One capture tip shown under a scanner frame.
class CaptureTip {
  final IconData icon;
  final String text;

  const CaptureTip(this.icon, this.text);
}

/// Shared layout for the document capture steps (front and back).
///
/// Shows the framing guide from `assets/images/` inside the scanner frame
/// until the user takes their photo; then the photo replaces the guide,
/// the chip turns into a "captured" badge, and the actions become
/// retake + continue.
class DocumentCaptureStep extends StatelessWidget {
  final String title;
  final String description;
  final String guideAsset;
  final String guideChipLabel;
  final List<CaptureTip> tips;
  final File? photo;
  final VoidCallback onCapture;
  final VoidCallback onContinue;
  final int step;

  const DocumentCaptureStep({
    super.key,
    required this.title,
    required this.description,
    required this.guideAsset,
    required this.guideChipLabel,
    required this.tips,
    required this.photo,
    required this.onCapture,
    required this.onContinue,
    this.step = 3,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final captured = photo != null;

    final Widget frameContent = captured
        ? Image.file(
            photo!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                LucideIcons.imageOff,
                size: AppDimensions.iconLG,
                color: context.appTextMuted,
              ),
            ),
          )
        : Semantics(
            label: l10n.capture_guide_semantics,
            image: true,
            child: Image.asset(guideAsset, fit: BoxFit.contain),
          );

    return RegistrationStepScaffold(
      title: title,
      step: step,
      lead: description,
      bottom: CaptureActions(
        captured: captured,
        captureLabel: l10n.capture_scan_button,
        onCapture: onCapture,
        onContinue: onContinue,
      ),
      children: [
        const SizedBox(height: AppDimensions.space4),
        ScannerViewfinder(
          captured: captured,
          chip: captured
              ? ScannerChip.captured(label: l10n.capture_document_captured)
              : ScannerChip.guide(label: guideChipLabel),
          child: frameContent,
        ),
        const SizedBox(height: AppDimensions.space24),
        CaptureTips(tips: tips),
      ],
    );
  }
}

/// Centered, wrapping row of [TipPill]s.
class CaptureTips extends StatelessWidget {
  final List<CaptureTip> tips;

  const CaptureTips({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppDimensions.space8,
      runSpacing: AppDimensions.space8,
      children: [
        for (final tip in tips) TipPill(icon: tip.icon, text: tip.text),
      ],
    );
  }
}

/// Bottom actions for a capture step: a single capture button until a photo
/// exists, then "retake" beside "continue".
class CaptureActions extends StatelessWidget {
  final bool captured;
  final String captureLabel;
  final VoidCallback onCapture;
  final VoidCallback onContinue;

  const CaptureActions({
    super.key,
    required this.captured,
    required this.captureLabel,
    required this.onCapture,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!captured) {
      return PrimaryActionButton(onPressed: onCapture, text: captureLabel);
    }

    return Row(
      children: [
        Expanded(
          child: SecondaryActionButton(
            onPressed: onCapture,
            text: l10n.capture_retake,
            icon: LucideIcons.rotateCcw,
          ),
        ),
        const SizedBox(width: AppDimensions.space12),
        Expanded(
          child: PrimaryActionButton(
            onPressed: onContinue,
            text: l10n.common_continue,
          ),
        ),
      ],
    );
  }
}
