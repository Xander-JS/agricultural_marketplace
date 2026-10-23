import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/crop_model.dart';
import '../services/crop_service.dart';
import 'crop_photo_placeholder.dart';
import 'crop_status_badge.dart';
import '../../geo/models/simulated_location.dart';
import '../../review/models/review_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/badges/media_capsule.dart';
import '../../../core/widgets/loading/app_skeleton.dart';
import '../../../core/widgets/misc/pressable_scale.dart';

/// Catalog card for a harvest lot.
///
/// Flat `surface` card with an 18px radius and a single hairline: depth
/// comes from the photo, not from shadows. The photo shimmers while it
/// loads and carries its badges in dark blurred capsules, so they stay
/// legible over any image. Below it, a fixed reading order: lot title,
/// crop, where and who (location chip, reputation), then the two numbers a
/// buyer compares, available kilograms and price per kilogram, set in
/// tabular figures.
class CropCard extends StatelessWidget {
  final CropModel crop;
  final VoidCallback onTap;
  final DistanceEvaluation? distanceEvaluation;

  /// Reputación del productor dueño de la cosecha. `null` mientras se carga
  /// o si la consulta falló; en ese caso no se muestra ningún indicador para
  /// evitar presentar datos ficticios.
  final ReviewSummary? reputation;

  const CropCard({
    super.key,
    required this.crop,
    required this.onTap,
    this.distanceEvaluation,
    this.reputation,
  });

  static const double _radius = 18;
  static const double _photoHeight = 156;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String? primaryImageUrl;
    if (crop.imageUrls.isNotEmpty) {
      primaryImageUrl = CropService().getPublicImageUrl(crop.imageUrls.first);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space16),
      child: Semantics(
        button: true,
        child: PressableScale(
          pressedScale: 0.985,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: context.appBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius - 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPhoto(context, l10n, primaryImageUrl),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: _buildDetails(context, l10n),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(
    BuildContext context,
    AppLocalizations l10n,
    String? imageUrl,
  ) {
    final badges = <Widget>[
      if (crop.status != CropStatus.activa)
        CropStatusBadge.overlay(status: crop.status),
      if (crop.isEarlySale)
        MediaCapsule(
          label: l10n.crop_detail_early_sale,
          icon: LucideIcons.calendarClock,
        ),
    ];

    return SizedBox(
      height: _photoHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const AppShimmer(
                  child: AppSkeletonBlock(height: _photoHeight, radius: 0),
                );
              },
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: AppMotion.of(context, AppMotion.standard),
                  curve: AppMotion.easeOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _buildImagePlaceholder(context),
            )
          else
            _buildImagePlaceholder(context),
          if (badges.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Wrap(spacing: 6, runSpacing: 6, children: badges),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context, AppLocalizations l10n) {
    final location = _buildLocationChip(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          crop.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          crop.cropType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        if (location != null || reputation != null) ...[
          const SizedBox(height: AppDimensions.space12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ?location,
              if (reputation != null) _buildReputationChip(context, l10n),
            ],
          ),
        ],
        const SizedBox(height: AppDimensions.space16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.crop_card_available,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    UnitFormatters.formatKg(crop.availableStock),
                    style: AppTextStyles.figureSmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatters.formatCop(crop.pricePerKg),
                  style: AppTextStyles.figureLarge.copyWith(
                    color: context.appPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ kg',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Location and estimated distance in one soft chip: municipality, a
  /// separator and the distance, each its own text run.
  Widget? _buildLocationChip(BuildContext context) {
    final locationName = crop.municipality.trim().isNotEmpty
        ? crop.municipality.trim()
        : crop.department.trim();
    final hasValidDistance =
        distanceEvaluation != null && distanceEvaluation!.hasValidDistance;

    if (locationName.isEmpty && !hasValidDistance) return null;

    final textStyle = AppTextStyles.labelMedium.copyWith(
      color: context.appTextSecondary,
      fontWeight: FontWeight.w500,
    );

    return _Chip(
      background: context.appSurfaceVariant,
      border: context.appSurfaceVariant,
      children: [
        Icon(
          hasValidDistance ? Icons.near_me_outlined : Icons.place_outlined,
          size: 13,
          color: context.appPrimary,
        ),
        const SizedBox(width: 4),
        if (locationName.isNotEmpty) ...[
          Text(locationName, style: textStyle),
          if (hasValidDistance) Text(' · ', style: textStyle),
        ],
        if (hasValidDistance)
          Text(
            distanceEvaluation!.formatted,
            style: textStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
      ],
    );
  }

  Widget _buildReputationChip(BuildContext context, AppLocalizations l10n) {
    final summary = reputation!;
    final value = summary.hasRatings
        ? '${summary.averageRating.toStringAsFixed(1)} (${summary.totalReviews})'
        : l10n.reputation_new;
    final triad = context.appWarningTriad;

    return _Chip(
      key: ValueKey('crop_reputation_${crop.id}'),
      background: triad.background,
      border: triad.border,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '★ ',
                style: TextStyle(color: triad.foreground),
              ),
              TextSpan(text: value),
            ],
          ),
          style: AppTextStyles.labelMedium.copyWith(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return const CropPhotoPlaceholder();
  }
}

class _Chip extends StatelessWidget {
  final Color background;
  final Color border;
  final List<Widget> children;

  const _Chip({
    super.key,
    required this.background,
    required this.border,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
