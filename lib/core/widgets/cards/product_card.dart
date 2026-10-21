import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../badges/altitude_badge.dart';

/// Main reusable product card for the market screen.
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final Widget statusBadge;
  final String altitude;
  final String title;
  final String variety;
  final String price;
  final String priceUnit;
  final String sellerType;
  final VoidCallback onDetailsTap;
  final Widget? sellerDetailsBox;
  final bool isExpanded;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.statusBadge,
    required this.altitude,
    required this.title,
    required this.variety,
    required this.price,
    required this.priceUnit,
    required this.sellerType,
    required this.onDetailsTap,
    this.sellerDetailsBox,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.appShadow,
            blurRadius: AppDimensions.space12,
            offset: const Offset(0, AppDimensions.space4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image and badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusLG),
                  topRight: Radius.circular(AppDimensions.radiusLG),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppDimensions.space12,
                left: AppDimensions.space12,
                child: statusBadge,
              ),
              Positioned(
                bottom: AppDimensions.space12,
                right: AppDimensions.space12,
                child: AltitudeBadge(text: altitude),
              ),
            ],
          ),

          // Content
          Padding(
            padding: AppDimensions.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space4),
                          Text(
                            l10n.product_card_variety(variety),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          priceUnit,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: AppDimensions.iconXS,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppDimensions.space4 + 2),
                        Text(
                          sellerType,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onDetailsTap,
                      child: Row(
                        children: [
                          Text(
                            l10n.product_card_view_details,
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colors.primary,
                            size: AppDimensions.iconSM,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isExpanded && sellerDetailsBox != null) ...[
                  const SizedBox(height: AppDimensions.space16),
                  sellerDetailsBox!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
