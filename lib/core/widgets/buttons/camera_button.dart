import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../misc/pressable_scale.dart';

/// Capture control for document and selfie flows.
///
/// A 52px squircle on the `primary`/`onPrimary` pair, wide enough to hit
/// without looking, with press feedback and a light haptic tick.
class CameraButton extends StatelessWidget {
  final VoidCallback onTap;

  const CameraButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: context.appPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusControl,
        ),
        child: InkWell(
          borderRadius: AppDimensions.borderRadiusControl,
          splashFactory: NoSplash.splashFactory,
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: SizedBox(
            width: AppDimensions.space64 + AppDimensions.space8,
            height: AppDimensions.buttonHeightPrimary,
            child: Icon(
              LucideIcons.camera,
              color: context.appOnPrimary,
              size: AppDimensions.iconMD,
            ),
          ),
        ),
      ),
    );
  }
}
