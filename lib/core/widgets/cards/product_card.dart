import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../badges/status_badge.dart';
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image and Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AppColors.lightDivider,
                    child: const Icon(Icons.image_not_supported, color: AppColors.lightTextDisabled),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: statusBadge,
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: AltitudeBadge(text: altitude),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Variedad: $variety',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.lightTertiary, // Green price
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          priceUnit,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sellerType,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onDetailsTap,
                      child: Row(
                        children: [
                          Text(
                            'Ver detalles',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.lightTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.lightTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isExpanded && sellerDetailsBox != null) ...[
                  const SizedBox(height: 16),
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
