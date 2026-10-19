import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import 'crop_status_badge.dart';
import '../../geo/models/simulated_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_formatters.dart';

class CropCard extends StatelessWidget {
  final CropModel crop;
  final VoidCallback onTap;
  final DistanceEvaluation? distanceEvaluation;

  const CropCard({
    super.key,
    required this.crop,
    required this.onTap,
    this.distanceEvaluation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final cropService = CropService();

    String? primaryImageUrl;
    if (crop.imageUrls.isNotEmpty) {
      primaryImageUrl = cropService.getPublicImageUrl(crop.imageUrls.first);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen de la cosecha
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: primaryImageUrl != null
                  ? Image.network(
                      primaryImageUrl,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(isDark);
                      },
                    )
                  : _buildImagePlaceholder(isDark),
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
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                      Text(
                        crop.cropType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (distanceEvaluation != null && distanceEvaluation!.hasValidDistance)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me_outlined,
                              size: 13,
                              color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distanceEvaluation!.formatted,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        context,
                        icon: Icons.inventory_2_outlined,
                        label: l10n?.crop_card_available ?? 'Disponible',
                        value: UnitFormatters.formatKg(crop.stockTotal),
                        isDark: isDark,
                      ),
                      _buildInfoItem(
                        context,
                        icon: Icons.sell_outlined,
                        label: l10n?.crop_card_price_per_kg ?? 'Precio / kg',
                        value: CurrencyFormatters.formatCop(crop.pricePerKg),
                        isDark: isDark,
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

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      height: 140,
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSecondary.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
