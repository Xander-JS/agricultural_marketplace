import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/registration_data.dart';
import 'capture_front_screen.dart';

class DocumentSelectionScreen extends StatefulWidget {
  final RegistrationData data;
  const DocumentSelectionScreen({Key? key, required this.data})
    : super(key: key);

  @override
  State<DocumentSelectionScreen> createState() =>
      _DocumentSelectionScreenState();
}

class _DocumentSelectionScreenState extends State<DocumentSelectionScreen> {
  String? _selectedDocument;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.data.documentType;
  }

  void _onNext() {
    if (_selectedDocument != null) {
      widget.data.documentType = _selectedDocument;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptureFrontScreen(data: widget.data),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un tipo de documento'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verification Code', // It says 'Verification Code' in the mockup header but 'Document Verification' as title
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.success,
              radius: 16,
              child: const Icon(
                Icons.person_outline,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(height: 4, color: AppColors.success),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(height: 4, color: AppColors.lightBorder),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(height: 4, color: AppColors.lightBorder),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'Document Verification',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We need to confirm your legal identity before activating your account.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'SELECT YOUR ID TYPE',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDocCard(
                    type: 'CC',
                    title: 'CC',
                    subtitle: 'Cédula de Ciudadanía / National ID',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDocCard(
                    type: 'Driver License',
                    title: 'Driver\'s License',
                    subtitle: 'Official state or national driving permit',
                    icon: Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '256-bit encrypted identity verification',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedDocument == type;
    final bgColor = isSelected
        ? AppColors.lightSecondary
        : AppColors.infoLight.withOpacity(0.3);
    final borderColor = isSelected ? AppColors.success : Colors.transparent;
    final iconBgColor = isSelected ? AppColors.success : Colors.transparent;
    final iconColor = isSelected ? Colors.white : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDocument = type;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.lightTextPrimary),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isSelected
                          ? AppColors.success
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.success
                    : AppColors.lightBorder.withOpacity(0.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
