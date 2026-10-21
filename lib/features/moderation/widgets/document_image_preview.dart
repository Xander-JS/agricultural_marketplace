import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/document_diagnosis_service.dart';
import '../services/document_image_service.dart';

typedef DocumentImageWidgetBuilder = Widget Function(
  BuildContext context,
  String url,
);

/// Vista segura de una imagen de documento privada. Solicita una URL firmada
/// temporal y muestra estados de carga, error, reintento y documento ausente.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = widget.path;
    final hasPath = path != null && path.trim().isNotEmpty;
    final isValidPath = DocumentPathValidator.isValid(path);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValidPath
                      ? Icons.verified_user_outlined
                      : Icons.report_gmailerrorred_outlined,
                  size: 20,
                  color: isValidPath ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightBackground,
                  child: _buildContent(
                    context,
                    l10n,
                    hasPath: hasPath,
                    isValidPath: isValidPath,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isValidPath
                  ? l10n.document_image_available
                  : hasPath
                  ? l10n.document_image_invalid
                  : l10n.document_image_missing,
              style: AppTextStyles.bodySmall.copyWith(
                color: isValidPath
                    ? AppColors.success
                    : isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        Icons.no_photography_outlined,
        l10n.document_image_missing,
        AppColors.lightTextSecondary,
      );
    }
    if (!isValidPath) {
      return _status(
        Icons.link_off,
        l10n.document_image_invalid,
        AppColors.warning,
      );
    }

    return FutureBuilder<DocumentImageUrlResult>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _status(
            Icons.lock_clock_outlined,
            l10n.document_image_loading,
            AppColors.info,
            showProgress: true,
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null || !result.isSuccess) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.error, size: 34),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.document_image_error,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('document_image_retry'),
                onPressed: () => setState(_load),
                child: Text(l10n.document_image_retry),
              ),
            ],
          );
        }

        final builder = widget.imageBuilder;
        if (builder != null) {
          return builder(context, result.url!);
        }

        return Image.network(
          result.url!,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _status(
              Icons.lock_clock_outlined,
              l10n.document_image_loading,
              AppColors.info,
              showProgress: true,
            );
          },
          errorBuilder: (_, _, _) => _status(
            Icons.broken_image_outlined,
            l10n.document_image_display_error,
            AppColors.error,
          ),
        );
      },
    );
  }

  Widget _status(
    IconData icon,
    String label,
    Color color, {
    bool showProgress = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(icon, color: color, size: 34),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
