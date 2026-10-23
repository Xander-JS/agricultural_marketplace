import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

/// Seller detail panel shown inside an expanded product card.
///
/// Grouped inset on the brand triad: identity first, then volume and minimum
/// order as aligned figures, then logistics.
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
    final l10n = AppLocalizations.of(context)!;
    final brand = context.appBrandTriad;

    return Container(
      padding: AppDimensions.paddingCard,
      decoration: BoxDecoration(
        color: brand.background.withValues(
          alpha: context.appIsDark ? 0.5 : 0.55,
        ),
        borderRadius: AppDimensions.borderRadiusMD,
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: brand.border),
                ),
                child: Icon(
                  LucideIcons.truck,
                  size: AppDimensions.iconXS + 2,
                  color: brand.foreground,
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
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space4),
                        Icon(
                          LucideIcons.badgeCheck,
                          size: AppDimensions.iconXS,
                          color: context.appSuccess,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sellerLocation,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: AppDimensions.borderRadiusSM,
                  border: Border.all(color: context.appBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      reliability,
                      style: AppTextStyles.figureSmall.copyWith(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.seller_details_reliability,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Divider(color: brand.border, height: AppDimensions.dividerThickness),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: l10n.seller_details_volume,
                  value: volumeAvailable,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: l10n.seller_details_min_order,
                  value: minimumOrder,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            l10n.seller_details_condition,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            logisticsCondition,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;

  const _Figure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.space4),
        Text(
          value,
          style: AppTextStyles.figureSmall.copyWith(
            color: context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}
