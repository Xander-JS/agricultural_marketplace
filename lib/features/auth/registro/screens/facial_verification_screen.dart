import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/scanner/scanner_viewfinder.dart';
import '../../widgets/document_capture_step.dart';
import '../../widgets/registration_step_scaffold.dart';
import '../models/registration_data.dart';
import 'document_review_screen.dart';

class FacialVerificationScreen extends StatefulWidget {
  final RegistrationData data;
  const FacialVerificationScreen({super.key, required this.data});

  @override
  State<FacialVerificationScreen> createState() =>
      _FacialVerificationScreenState();
}

class _FacialVerificationScreenState extends State<FacialVerificationScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = widget.data.selfie;
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (photo != null && mounted) {
      setState(() {
        _image = File(photo.path);
      });
      widget.data.selfie = _image;
    }
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentReviewScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final captured = _image != null;

    final Widget face = captured
        ? Image.file(
            _image!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              LucideIcons.imageOff,
              size: AppDimensions.iconLG,
              color: context.appTextMuted,
            ),
          )
        : Semantics(
            label: l10n.capture_guide_semantics,
            image: true,
            child: Image.asset('assets/images/face_id.png', fit: BoxFit.cover),
          );

    return RegistrationStepScaffold(
      title: l10n.facial_verification_header_title,
      step: 4,
      lead: l10n.facial_verification_description,
      bottom: CaptureActions(
        captured: captured,
        captureLabel: l10n.facial_verification_capture_button,
        onCapture: _takePicture,
        onContinue: _continue,
      ),
      children: [
        Center(
          child: BiometricFrame(
            captured: captured,
            chip: captured
                ? ScannerChip.captured(label: l10n.facial_verification_captured)
                : ScannerChip.guide(
                    label: l10n.facial_verification_guide_chip,
                    icon: LucideIcons.scanFace,
                  ),
            child: face,
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        CaptureTips(
          tips: [
            CaptureTip(LucideIcons.sun, l10n.facial_verification_tip_light),
            CaptureTip(
              LucideIcons.glasses,
              l10n.facial_verification_tip_glasses,
            ),
            CaptureTip(
              LucideIcons.smile,
              l10n.facial_verification_tip_straight,
            ),
          ],
        ),
      ],
    );
  }
}
