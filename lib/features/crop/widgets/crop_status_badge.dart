import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

class CropStatusBadge extends StatelessWidget {
  final CropStatus status;

  const CropStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case CropStatus.borrador:
        backgroundColor = context.appSurfaceVariant;
        textColor = context.appTextDisabled;
        label = l10n.crop_status_draft;
        break;
      case CropStatus.activa:
        backgroundColor = context.appSuccessContainer;
        textColor = context.appSuccess;
        label = l10n.crop_status_active;
        break;
      case CropStatus.pausada:
        backgroundColor = context.appWarningContainer;
        textColor = context.appWarning;
        label = l10n.crop_status_paused;
        break;
      case CropStatus.agotada:
        backgroundColor = context.appErrorContainer;
        textColor = context.appError;
        label = l10n.crop_status_exhausted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
