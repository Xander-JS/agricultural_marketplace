import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/loading/app_skeleton.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../crop/models/crop_model.dart';
import '../../crop/services/crop_service.dart';

/// Small squircle picture of the lot a deal is about: its first photo, or
/// a sprout mark on the brand soft tone when the lot has none (or the photo
/// fails to load).
class DealCropThumb extends StatelessWidget {
  final CropModel? crop;
  final double size;

  const DealCropThumb({super.key, required this.crop, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final fallback = IconSquircle(
      icon: LucideIcons.sprout,
      triad: context.appBrandTriad,
      size: size,
    );

    final images = crop?.imageUrls ?? const <String>[];
    if (images.isEmpty) return fallback;

    final url = CropService().getPublicImageUrl(images.first);
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(size * 0.6),
    );

    return SizedBox.square(
      dimension: size,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return AppShimmer(child: AppSkeletonBlock(height: size, radius: 0));
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: AppMotion.of(context, AppMotion.standard),
              curve: AppMotion.easeOut,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
