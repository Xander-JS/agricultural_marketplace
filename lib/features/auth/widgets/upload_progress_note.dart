import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Indeterminate upload bar with its status line, used while documents are
/// sent to private storage.
class UploadProgressNote extends StatelessWidget {
  final String message;

  const UploadProgressNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final triad = context.appInfoTriad;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: triad.background,
        borderRadius: AppDimensions.borderRadiusControl,
        border: Border.all(color: triad.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.cloudUpload, size: 18, color: triad.foreground),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: triad.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          ClipRRect(
            borderRadius: AppDimensions.borderRadiusFull,
            child: LinearProgressIndicator(
              minHeight: 4,
              color: triad.foreground,
              backgroundColor: triad.border,
            ),
          ),
        ],
      ),
    );
  }
}
