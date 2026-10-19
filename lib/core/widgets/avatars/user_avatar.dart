import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Un widget de avatar reutilizable para usuarios y agricultores,
/// con soporte de carga, fallback predeterminado ante ausencia o error de imagen,
/// y dimensiones configurables mediante [radius].
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final Color? iconColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.onTap,
    this.radius = 20,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final diameter = radius * 2;
    final iconSize = radius * 1.1;

    final effectiveBgColor = backgroundColor ??
        (isDark ? AppColors.darkSurfaceVariant : AppColors.lightTertiary);
    final effectiveBorderColor = borderColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightTertiary.withOpacity(0.3));
    final effectiveIconColor = iconColor ??
        (isDark ? AppColors.darkTextDisabled : AppColors.lightSurface);

    final avatarContent = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth ?? (radius > 30 ? 3 : 2),
        ),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? Image.network(
                imageUrl!,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    color: effectiveIconColor,
                    size: iconSize,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius,
                      height: radius,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: effectiveIconColor,
                      ),
                    ),
                  );
                },
              )
            : Icon(
                Icons.person,
                color: effectiveIconColor,
                size: iconSize,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarContent,
      );
    }
    return avatarContent;
  }
}
