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
import 'facial_verification_screen.dart';

class CaptureBackScreen extends StatefulWidget {
  final RegistrationData data;
  const CaptureBackScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<CaptureBackScreen> createState() => _CaptureBackScreenState();
}

class _CaptureBackScreenState extends State<CaptureBackScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
      widget.data.documentBack = _image;

      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FacialVerificationScreen(data: widget.data),
          ),
        );
      });
    }
  }

  Future<void> _pickGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      widget.data.documentBack = _image;

      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FacialVerificationScreen(data: widget.data),
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
      appBar: CustomAppBar(title: l10n.capture_back_header_title),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(totalSteps: 4, currentStep: 3),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    l10n.capture_back_title,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.capture_back_description,
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
                            Icons.crop_free,
                            size: 200,
                            color: AppColors.success,
                          ),
                          Positioned(
                            bottom: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.capture_back_steady,
                                    style: const TextStyle(
                                      color: AppColors.success,
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
                  TipPill(icon: Icons.light_mode, text: l10n.capture_back_tip_light),
                  TipPill(icon: Icons.aspect_ratio, text: l10n.capture_back_tip_fit),
                  TipPill(icon: Icons.qr_code_scanner, text: l10n.capture_back_tip_barcode),
                ],
              ),
            ),

            Text(
              l10n.capture_back_tap_to_capture,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

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
                  onPressed: _pickGallery,
                  icon: const Icon(Icons.photo_library),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightSecondary,
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
