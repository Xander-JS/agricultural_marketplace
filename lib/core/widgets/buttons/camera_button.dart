import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

class CameraButton extends StatelessWidget {
  final VoidCallback onTap;

  const CameraButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.space64 + AppDimensions.space8,
        height: AppDimensions.space64 + AppDimensions.space8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.appSuccess.withValues(alpha: 0.3),
            width: AppDimensions.space4,
          ),
          color: context.appSuccess,
        ),
        child: const Icon(
          Icons.camera_alt,
          color: AppColors.onBrand,
          size: AppDimensions.iconLG,
        ),
      ),
    );
  }
}
