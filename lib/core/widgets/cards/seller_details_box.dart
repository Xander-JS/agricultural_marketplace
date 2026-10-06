import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A reusable widget to display detailed seller information within a product card
class SellerDetailsBox extends StatelessWidget {
  final String sellerName;
  final String sellerLocation;
  final String reliability;
  final String volumeAvailable;
  final String minimumOrder;
  final String logisticsCondition;

  const SellerDetailsBox({
    Key? key,
    required this.sellerName,
    required this.sellerLocation,
    required this.reliability,
    required this.volumeAvailable,
    required this.minimumOrder,
    required this.logisticsCondition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSecondary.withOpacity(0.3), // Soft green tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightSecondary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon and Reliability
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: AppColors.lightTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sellerName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    Text(
                      sellerLocation,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      reliability,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Confiabilidad',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.lightTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.lightDivider, height: 1),
          const SizedBox(height: 16),
          // Volume and Order Info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volumen Disponible',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volumeAvailable,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.lightTextPrimary,
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
                      'Pedido Mínimo',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      minimumOrder,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Condition & Logistics
          Text(
            'Condición & Logística',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            logisticsCondition,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
