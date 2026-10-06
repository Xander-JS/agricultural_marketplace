import 'dart:io';

import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/progress/step_progress_bar.dart';
import '../../../../core/widgets/info/tip_pill.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
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
        if (!mounted) return;
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
      backgroundColor: AppColors.lightSurface,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(),
              
              if (_image == null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 250,
                      child: CustomPaint(
                        painter: FaceOutlinePainter(),
                      ),
                    ),
                    const Icon(
                      Icons.person,
                      size: 160,
                      color: AppColors.lightBorder,
                    ),
                  ],
                )
              else
                Container(
                  width: 200,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    image: DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TipPill(icon: Icons.light_mode_outlined, text: l10n.facial_verification_tip_light),
                  const SizedBox(width: 8),
                  TipPill(icon: Icons.visibility_off_outlined, text: l10n.facial_verification_tip_glasses),
                  const SizedBox(width: 8),
                  TipPill(icon: Icons.sentiment_satisfied_alt, text: l10n.facial_verification_tip_straight),
                ],
              ),
              const SizedBox(height: 32),
              
                    PrimaryActionButton(
                      onPressed: _takePicture,
                      text: l10n.facial_verification_start_button,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaceOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double arcLength = 3.14159 / 3;

    canvas.drawArc(rect, 3.14159 + 3.14159 / 12, arcLength, false, paint);
    canvas.drawArc(rect, 1.5 * 3.14159 + 3.14159 / 12, arcLength, false, paint);
    canvas.drawArc(rect, 0.5 * 3.14159 + 3.14159 / 12, arcLength, false, paint);
    canvas.drawArc(rect, 0 + 3.14159 / 12, arcLength, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
