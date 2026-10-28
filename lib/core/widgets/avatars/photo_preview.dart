import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_icons.dart';

/// Full-screen photo viewer over a dark scrim.
///
/// Closes with the close button, a tap on the scrim around the photo, or the
/// system back gesture. The photo can be pinched to zoom.
abstract final class PhotoPreview {
  static Future<void> show(BuildContext context, String imageUrl) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xEB000000), // black at 92%
      barrierLabel: l10n.common_close,
      builder: (dialogContext) => _PhotoPreviewView(imageUrl: imageUrl),
    );
  }
}

class _PhotoPreviewView extends StatelessWidget {
  final String imageUrl;

  const _PhotoPreviewView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void close() => Navigator.of(context).pop();

    return SafeArea(
      child: Stack(
        children: [
          // Tapping anywhere off the photo closes the viewer.
          Positioned.fill(
            child: GestureDetector(
              key: const Key('photo_preview_scrim'),
              behavior: HitTestBehavior.opaque,
              onTap: close,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: InteractiveViewer(
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: AppDimensions.borderRadiusLG,
                  child: Image.network(
                    imageUrl,
                    key: const Key('photo_preview_image'),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const CircularProgressIndicator(
                            color: AppColors.onBrand,
                          ),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      LucideIcons.imageOff,
                      size: 48,
                      color: AppColors.onBrandSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppDimensions.space8,
            right: AppDimensions.space8,
            child: IconButton(
              key: const Key('photo_preview_close'),
              tooltip: l10n.common_close,
              onPressed: close,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x33FFFFFF),
                foregroundColor: AppColors.onBrand,
              ),
              icon: const Icon(LucideIcons.x, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
