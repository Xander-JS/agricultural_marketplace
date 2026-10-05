import 'dart:io';

import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/progress/step_progress_bar.dart';
import '../../../../core/widgets/info/tip_pill.dart';
import '../../../../core/widgets/buttons/camera_button.dart';
import '../models/registration_data.dart';
import 'processing_screen.dart';

class FacialVerificationScreen extends StatefulWidget {
  final RegistrationData data;
  const FacialVerificationScreen({Key? key, required this.data})
    : super(key: key);

  @override
  State<FacialVerificationScreen> createState() =>
      _FacialVerificationScreenState();
}

class _FacialVerificationScreenState extends State<FacialVerificationScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
      widget.data.selfie = _image;

      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(data: widget.data),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: CustomAppBar(title: l10n.facial_verification_header_title),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(totalSteps: 4, currentStep: 4),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    l10n.facial_verification_description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.face_retouching_natural,
                            size: 200,
                            color: AppColors.success,
                          ),
                          Positioned(
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: AppColors.success,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.facial_verification_face_detected,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.facial_verification_liveness,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TipPill(icon: Icons.light_mode, text: l10n.facial_verification_tip_light),
                  TipPill(icon: Icons.visibility_off, text: l10n.facial_verification_tip_glasses),
                  TipPill(icon: Icons.face, text: l10n.facial_verification_tip_straight),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.flash_off),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightSecondary,
                  ),
                ),
                const SizedBox(width: 32),
                CameraButton(onTap: _takePicture),
                const SizedBox(width: 32),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.flip_camera_ios),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.facial_verification_encryption_notice,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
