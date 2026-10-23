import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading/app_skeleton.dart';
import '../services/document_diagnosis_service.dart';
import '../services/document_image_service.dart';

typedef DocumentImageWidgetBuilder = Widget Function(
  BuildContext context,
  String url,
);

/// Vista segura de una imagen de documento privada. Solicita una URL firmada
/// temporal y muestra estados de carga, error, reintento y documento ausente.
///
/// While the signed link and bytes load, a shimmer holds the frame's real
/// size; tapping a loaded document opens it full screen with pinch zoom.
class DocumentImagePreview extends StatefulWidget {
  final String title;
  final String? path;
  final DocumentImageUrlService? imageUrlService;
  final DocumentImageWidgetBuilder? imageBuilder;

  const DocumentImagePreview({
    super.key,
    required this.title,
    required this.path,
    this.imageUrlService,
    this.imageBuilder,
  });

  @override
  State<DocumentImagePreview> createState() => _DocumentImagePreviewState();
}

class _DocumentImagePreviewState extends State<DocumentImagePreview> {
  late final DocumentImageUrlService _service;
  Future<DocumentImageUrlResult>? _urlFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.imageUrlService ?? DocumentImageUrlService();
    _load();
  }

  @override
  void didUpdateWidget(covariant DocumentImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _load();
    }
  }

  void _load() {
    final path = widget.path;
    if (path == null || path.trim().isEmpty) {
      _urlFuture = null;
      return;
    }
    _urlFuture = _service.createSignedUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final path = widget.path;
    final hasPath = path != null && path.trim().isNotEmpty;
    final isValidPath = DocumentPathValidator.isValid(path);
    // A valid file stays graphite; only a broken path is marked.
    final markColor = isValidPath
        ? context.appTextSecondary
        : context.appWarning;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              children: [
                Icon(
                  isValidPath
                      ? LucideIcons.shieldCheck
                      : LucideIcons.shieldAlert,
                  size: 18,
                  color: markColor,
                ),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: AppDimensions.borderRadiusMD,
              child: ColoredBox(
                color: context.appSurfaceVariant,
                child: _buildContent(
                  context,
                  l10n,
                  hasPath: hasPath,
                  isValidPath: isValidPath,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isValidPath
                  ? l10n.document_image_available
                  : hasPath
                  ? l10n.document_image_invalid
                  : l10n.document_image_missing,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n, {
    required bool hasPath,
    required bool isValidPath,
  }) {
    if (!hasPath) {
      return _status(
        LucideIcons.cameraOff,
        l10n.document_image_missing,
        context.appTextSecondary,
      );
    }
    if (!isValidPath) {
      return _status(
        LucideIcons.unlink,
        l10n.document_image_invalid,
        context.appWarningText,
      );
    }

    return FutureBuilder<DocumentImageUrlResult>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingPlaceholder(l10n);
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null || !result.isSuccess) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.lock, color: context.appErrorText, size: 28),
                const SizedBox(height: AppDimensions.space8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                  ),
                  child: Text(
                    l10n.document_image_error,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appErrorText,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('document_image_retry'),
                  onPressed: () => setState(_load),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(l10n.document_image_retry),
                ),
              ],
            ),
          );
        }

        final url = result.url!;
        final heroTag = 'document-preview-${widget.title}-${widget.path}';
        Widget image(BoxFit fit) {
          final builder = widget.imageBuilder;
          if (builder != null) return builder(context, url);
          return Image.network(
            url,
            fit: fit,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return _loadingPlaceholder(l10n);
            },
            errorBuilder: (_, _, _) => _status(
              LucideIcons.imageOff,
              l10n.document_image_display_error,
              context.appErrorText,
            ),
          );
        }

        return Semantics(
          button: true,
          label: l10n.moderation_doc_view_semantics,
          child: GestureDetector(
            onTap: () => _openViewer(context, heroTag, image),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(tag: heroTag, child: image(BoxFit.contain)),
                Positioned(
                  right: AppDimensions.space8,
                  bottom: AppDimensions.space8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Icon(
                      LucideIcons.maximize2,
                      size: 15,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openViewer(
    BuildContext context,
    String heroTag,
    Widget Function(BoxFit fit) image,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.transparent,
        transitionDuration: AppMotion.of(context, AppMotion.emphasized),
        reverseTransitionDuration: AppMotion.of(context, AppMotion.standard),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.easeOut),
          child: _DocumentViewer(
            title: widget.title,
            heroTag: heroTag,
            child: image(BoxFit.contain),
          ),
        ),
      ),
    );
  }

  /// Shimmer at the frame's real size while the signed link or the image
  /// bytes arrive, with the reason in words for screen readers and people.
  Widget _loadingPlaceholder(AppLocalizations l10n) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppShimmer(child: AppSkeletonBlock(height: double.infinity)),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: AppDimensions.borderRadiusFull,
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.lockKeyhole,
                  size: 13,
                  color: context.appTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.document_image_loading,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _status(IconData icon, String label, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppDimensions.space8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom look at one document on a dark field, so
/// small print and the photo can be read clearly before deciding.
class _DocumentViewer extends StatelessWidget {
  final String title;
  final String heroTag;
  final Widget child;

  const _DocumentViewer({
    required this.title,
    required this.heroTag,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space20,
                AppDimensions.space8,
                AppDimensions.space8,
                AppDimensions.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.onBrand,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.common_close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: AppDimensions.iconSM),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.onBrand,
                      backgroundColor: AppColors.onBrand.withValues(
                        alpha: 0.12,
                      ),
                      fixedSize: const Size.square(
                        AppDimensions.minTouchTarget,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Hero(tag: heroTag, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
