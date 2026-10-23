import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/document_capture_step.dart';
import '../models/registration_data.dart';
import 'capture_back_screen.dart';

class CaptureFrontScreen extends StatefulWidget {
  final RegistrationData data;
  const CaptureFrontScreen({super.key, required this.data});

  @override
  State<CaptureFrontScreen> createState() => _CaptureFrontScreenState();
}

class _CaptureFrontScreenState extends State<CaptureFrontScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = widget.data.documentFront;
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      setState(() {
        _image = File(photo.path);
      });
      widget.data.documentFront = _image;
    }
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaptureBackScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DocumentCaptureStep(
      title: l10n.capture_front_title,
      description: l10n.capture_front_description,
      guideAsset: widget.data.documentType == 'CC'
          ? 'assets/images/cc_frontal.png'
          : 'assets/images/licencia_frontal.png',
      guideChipLabel: l10n.capture_front_guide_chip,
      tips: [
        CaptureTip(LucideIcons.sun, l10n.capture_front_tip_light),
        CaptureTip(LucideIcons.scan, l10n.capture_front_tip_fit),
        CaptureTip(LucideIcons.sunDim, l10n.capture_front_tip_glare),
      ],
      photo: _image,
      onCapture: _takePicture,
      onContinue: _continue,
    );
  }
}
