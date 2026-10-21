import 'package:flutter/material.dart';

import '../models/crop_model.dart';
import '../services/crop_service.dart';
import 'crop_status_badge.dart';
import '../../geo/models/simulated_location.dart';
import '../../review/models/review_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_formatters.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cropService = CropService();

    String? primaryImageUrl;
    if (crop.imageUrls.isNotEmpty) {
      primaryImageUrl = cropService.getPublicImageUrl(crop.imageUrls.first);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen de la cosecha
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: primaryImageUrl != null
                  ? Image.network(
                      primaryImageUrl,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(context);
                      },
                    )
                  : _buildImagePlaceholder(context),
            ),

            // Detalles de la cosecha
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          crop.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CropStatusBadge(status: crop.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          crop.cropType,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.appTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildLocationAndDistance(context),
                    ],
                  ),
                  if (reputation != null) ...[
                    const SizedBox(height: 8),
                    _buildReputationChip(context, l10n),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        icon: Icons.inventory_2_outlined,
                        label: l10n.crop_card_available,
                        value: UnitFormatters.formatKg(crop.availableStock),
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.sell_outlined,
                        label: l10n.crop_card_price_per_kg,
                        value: CurrencyFormatters.formatCop(crop.pricePerKg),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAndDistance(BuildContext context) {
    final locationName = crop.municipality.trim().isNotEmpty
        ? crop.municipality.trim()
        : crop.department.trim();
    final hasValidDistance =
        distanceEvaluation != null && distanceEvaluation!.hasValidDistance;

    if (locationName.isEmpty && !hasValidDistance) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasValidDistance ? Icons.near_me_outlined : Icons.place_outlined,
          size: 13,
          color: context.appPrimary,
        ),
        const SizedBox(width: 3),
        if (locationName.isNotEmpty) ...[
          Text(
            locationName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.appTextSecondary,
            ),
          ),
          if (hasValidDistance)
            Text(
              ' · ',
              style: TextStyle(
                fontSize: 11,
                color: context.appTextSecondary,
              ),
            ),
        ],
        if (hasValidDistance)
          Text(
            distanceEvaluation!.formatted,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.appPrimary,
            ),
          ),
      ],
    );
  }

  Widget _buildReputationChip(BuildContext context, AppLocalizations l10n) {
    final summary = reputation!;
    final label = summary.hasRatings
        ? '★ ${summary.averageRating.toStringAsFixed(1)} (${summary.totalReviews})'
        : '★ ${l10n.reputation_new}';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: ValueKey('crop_reputation_${crop.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.appWarning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appWarning.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.appTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      height: 140,
      color: context.appSurfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: context.appTextDisabled,
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.appPrimary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.appTextSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
