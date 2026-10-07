import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../../../core/theme/app_theme.dart';

class CropStatusBadge extends StatelessWidget {
  final CropStatus status;

  const CropStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case CropStatus.borrador:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Borrador';
        break;
      case CropStatus.activa:
        backgroundColor = const Color(0xFFE8F5E9); // Light Green
        textColor = const Color(0xFF2E7D32); // Dark Green
        label = 'Activa';
        break;
      case CropStatus.pausada:
        backgroundColor = const Color(0xFFFFF3E0); // Light Orange
        textColor = const Color(0xFFE65100); // Dark Orange
        label = 'Pausada';
        break;
      case CropStatus.agotada:
        backgroundColor = const Color(0xFFFFEBEE); // Light Red
        textColor = const Color(0xFFC62828); // Dark Red
        label = 'Agotada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
