import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../badges/altitude_badge.dart';
import '../loading/app_skeleton.dart';
import '../misc/pressable_scale.dart';

/// Main reusable product card for the market screen.
///
/// Flat surface with a 1px border (no shadow), photo first, then the crop
/// name and its price in tabular figures so prices align across cards.
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

  static const double _imageHeight = 180;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppDimensions.borderRadiusLG,
        border: Border.all(color: context.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: _imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: _imageHeight,
                    child: AppShimmer(
                      child: AppSkeletonBlock(
                        width: double.infinity,
                        height: _imageHeight,
                        radius: 0,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: _imageHeight,
                  color: context.appSurfaceVariant,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.imageOff,
                        size: AppDimensions.iconMD,
                        color: context.appTextMuted,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        l10n.product_card_image_unavailable,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
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
          Padding(
            padding: AppDimensions.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space4),
                          Text(
                            l10n.product_card_variety(variety),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.appTextSecondary,
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
                          style: AppTextStyles.figureMedium.copyWith(
                            color: context.appTextPrimary,
                          ),
                        ),
                        Text(
                          priceUnit,
                          style: AppTextStyles.caption.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                Divider(height: 1, color: context.appDivider),
                const SizedBox(height: AppDimensions.space4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.badgeCheck,
                      size: AppDimensions.iconXS,
                      color: context.appSuccess,
                    ),
                    const SizedBox(width: AppDimensions.space4 + 2),
                    Expanded(
                      child: Text(
                        sellerType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                    PressableScale(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onDetailsTap,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppDimensions.minTouchTarget,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.product_card_view_details,
                                style: AppTextStyles.buttonMedium.copyWith(
                                  color: context.appPrimary,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space4),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: AppMotion.of(
                                  context,
                                  AppMotion.standard,
                                ),
                                curve: AppMotion.easeOut,
                                child: Icon(
                                  LucideIcons.chevronDown,
                                  color: context.appTextSecondary,
                                  size: AppDimensions.iconSM,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpanded && sellerDetailsBox != null) ...[
                  const SizedBox(height: AppDimensions.space12),
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
