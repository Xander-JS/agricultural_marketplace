import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

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
/// comes from the photo, not from shadows. The photo carries everything
/// that describes the lot: status top-left, crop type top-right, and where
/// and who (location, reputation) bottom-left in light translucent pills.
/// Below it, one compact row: title and available kilograms on the left,
/// price per kilogram on the right, set in tabular figures.
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
  static const double _photoHeight = 140;

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
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
    final cropType = crop.cropType.trim();
    final location = _buildLocationChip(context);
    final placeChips = <Widget>[
      ?location,
      if (reputation != null) _buildReputationChip(context, l10n),
    ];

    // The photo grows with the text size so the overlay pills keep room.
    final photoHeight = MediaQuery.textScalerOf(context).scale(_photoHeight);

    return SizedBox(
      height: photoHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return AppShimmer(
                  child: AppSkeletonBlock(height: photoHeight, radius: 0),
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
          if (badges.isNotEmpty || cropType.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ),
                  if (cropType.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(flex: 2, child: _buildCropTypeBadge(cropType)),
                  ],
                ],
              ),
            ),
          if (placeChips.isNotEmpty)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Wrap(spacing: 6, runSpacing: 6, children: placeChips),
            ),
        ],
      ),
    );
  }

  /// Crop type on a solid white pill: always over the photo, so it keeps
  /// the light palette in both themes.
  Widget _buildCropTypeBadge(String cropType) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          cropType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.lightBrandPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, AppLocalizations l10n) {
    final available = crop.availableStock;
    final availableColor = available <= 0
        ? context.appErrorText
        : context.appTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                crop.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    l10n.crop_card_available,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: availableColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      UnitFormatters.formatKg(available),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.figureSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: available <= 0
                            ? availableColor
                            : context.appTextPrimary,
                      ),
                    ),
                  ),
                ],
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
              style: AppTextStyles.figureMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              l10n.crop_card_per_kg,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appPrimary,
                fontWeight: FontWeight.w600,
              ),
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
      color: AppColors.lightTextPrimary,
      fontWeight: FontWeight.w600,
    );

    return _Chip(
      children: [
        Icon(
          hasValidDistance ? LucideIcons.navigation : LucideIcons.mapPin,
          size: 13,
          color: AppColors.lightTextPrimary,
        ),
        const SizedBox(width: 4),
        if (locationName.isNotEmpty) ...[
          Flexible(
            child: Text(
              locationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          if (hasValidDistance) Text(' · ', style: textStyle),
        ],
        if (hasValidDistance)
          Text(
            distanceEvaluation!.formatted,
            style: textStyle.copyWith(
              fontWeight: FontWeight.w700,
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
    return _Chip(
      key: ValueKey('crop_reputation_${crop.id}'),
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '★ ',
                style: const TextStyle(color: AppColors.ratingGoldLight),
              ),
              TextSpan(text: value),
            ],
          ),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.lightTextPrimary,
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

/// Pill drawn over the photo: white at 88% so it reads over any image,
/// with no border.
class _Chip extends StatelessWidget {
  final List<Widget> children;

  const _Chip({super.key, required this.children});

  static const Color _background = Color(0xE0FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
