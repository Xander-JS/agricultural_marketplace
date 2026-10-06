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
import '../../../../core/widgets/misc/viewfinder_painter.dart';
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
        if (!mounted) return;
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
      backgroundColor: AppColors.lightSurface,
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
                    l10n.capture_back_description,
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
              
              CustomPaint(
                foregroundPainter: ViewfinderPainter(
                  color: AppColors.lightTextSecondary,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: _image != null
                          ? DecorationImage(
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: AssetImage(
                                  widget.data.documentType == 'CC'
                                      ? 'assets/images/cc_reverso.png'
                                      : 'assets/images/licencia_reverso.png',
                              ),
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TipPill(icon: Icons.light_mode_outlined, text: l10n.capture_back_tip_light),
                  const SizedBox(width: 8),
                  TipPill(icon: Icons.aspect_ratio, text: l10n.capture_back_tip_fit),
                  const SizedBox(width: 8),
                  TipPill(icon: Icons.auto_awesome, text: l10n.capture_back_tip_barcode),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Text(
                l10n.capture_back_tap_to_capture,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              
                    PrimaryActionButton(
                      onPressed: _takePicture,
                      icon: Icons.document_scanner_outlined,
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
