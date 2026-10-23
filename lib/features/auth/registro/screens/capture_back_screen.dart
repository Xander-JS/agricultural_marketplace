import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/document_capture_step.dart';
import '../models/registration_data.dart';
import 'facial_verification_screen.dart';

class CaptureBackScreen extends StatefulWidget {
  final RegistrationData data;
  const CaptureBackScreen({super.key, required this.data});

  @override
  State<CaptureBackScreen> createState() => _CaptureBackScreenState();
}

class _CaptureBackScreenState extends State<CaptureBackScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = widget.data.documentBack;
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() {
        _image = File(photo.path);
      });
      widget.data.documentBack = _image;
    }
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FacialVerificationScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DocumentCaptureStep(
      title: l10n.capture_back_title,
      description: l10n.capture_back_description,
      guideAsset: widget.data.documentType == 'CC'
          ? 'assets/images/cc_reverso.png'
          : 'assets/images/licencia_reverso.png',
      guideChipLabel: l10n.capture_back_guide_chip,
      tips: [
        CaptureTip(LucideIcons.sun, l10n.capture_back_tip_light),
        CaptureTip(LucideIcons.scan, l10n.capture_back_tip_fit),
        CaptureTip(LucideIcons.barcode, l10n.capture_back_tip_barcode),
      ],
      photo: _image,
      onCapture: _takePicture,
      onContinue: _continue,
    );
  }
}
