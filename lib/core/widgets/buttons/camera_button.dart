import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CameraButton extends StatelessWidget {
  final VoidCallback onTap;

  const CameraButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.success.withOpacity(0.3),
            width: 4,
          ),
          color: AppColors.success,
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
