import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../loading/app_skeleton.dart';

/// Un widget de avatar reutilizable para usuarios y agricultores,
/// con shimmer mientras descarga la imagen, fallback limpio ante ausencia o
/// error de imagen, y dimensiones configurables mediante [radius].
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
    final diameter = radius * 2;
    final iconSize = radius * 0.95;

    final effectiveBgColor = backgroundColor ?? context.appSurfaceVariant;
    final effectiveBorderColor = borderColor ?? context.appBorder;
    final effectiveIconColor = iconColor ?? context.appTextMuted;

    String? resolvedUrl = imageUrl?.trim();
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      if (!resolvedUrl.startsWith('http://') &&
          !resolvedUrl.startsWith('https://')) {
        try {
          resolvedUrl = Supabase.instance.client.storage
              .from('profiles')
              .getPublicUrl(resolvedUrl);
        } catch (_) {}
      }
    }

    final hasValidUrl = resolvedUrl != null && resolvedUrl.isNotEmpty;

    final fallback = Center(
      child: Icon(
        LucideIcons.userRound,
        color: effectiveIconColor,
        size: iconSize,
      ),
    );

    final avatarContent = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth ?? (radius > 30 ? 2 : 1),
        ),
      ),
      child: ClipOval(
        child: hasValidUrl
            ? Image.network(
                resolvedUrl,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => fallback,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: AppMotion.of(context, AppMotion.standard),
                    curve: AppMotion.easeOut,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return AppShimmer(
                    child: AppSkeletonBlock.circle(size: diameter),
                  );
                },
              )
            : fallback,
      ),
    );

    final semanticLabel = AppLocalizations.of(context)?.user_avatar_semantics;
    final labelled = Semantics(
      label: semanticLabel,
      image: true,
      button: onTap != null,
      child: avatarContent,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: labelled);
    }
    return labelled;
  }
}
