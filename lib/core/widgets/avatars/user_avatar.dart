import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A reusable avatar widget for the top bar
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lightTertiary,
          border: Border.all(
            color: AppColors.lightTertiary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                )
              : const Icon(
                  Icons.person,
                  color: AppColors.lightSurface,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
