import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// A reusable widget to display detailed seller information within a product card.
class SellerDetailsBox extends StatelessWidget {
  final String sellerName;
  final String sellerLocation;
  final String reliability;
  final String volumeAvailable;
  final String minimumOrder;
  final String logisticsCondition;

  const SellerDetailsBox({
    super.key,
    required this.sellerName,
    required this.sellerLocation,
    required this.reliability,
    required this.volumeAvailable,
    required this.minimumOrder,
    required this.logisticsCondition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.colorScheme;

    return Container(
      padding: AppDimensions.paddingCard,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(color: colors.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and reliability
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: AppDimensions.paddingAll8,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: AppDimensions.iconSM,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sellerName,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space4),
                        Icon(
                          Icons.verified,
                          size: AppDimensions.iconXS,
                          color: context.appSuccess,
                        ),
                      ],
                    ),
                    Text(
                      sellerLocation,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppDimensions.borderRadiusSM,
                ),
                child: Column(
                  children: [
                    Text(
                      reliability,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.seller_details_reliability,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Divider(color: colors.outlineVariant, height: AppDimensions.dividerThickness),
          const SizedBox(height: AppDimensions.space16),
          // Volume and order info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.seller_details_volume,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Text(
                      volumeAvailable,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.seller_details_min_order,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Text(
                      minimumOrder,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          // Condition & logistics
          Text(
            l10n.seller_details_condition,
            style: AppTextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            logisticsCondition,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
