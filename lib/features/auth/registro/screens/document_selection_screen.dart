import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/progress/step_progress_bar.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
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
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDocument != null) {
      widget.data.documentType = _selectedDocument;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptureFrontScreen(data: widget.data),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.document_selection_error_no_doc),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: CustomAppBar(title: l10n.document_selection_header_title),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(totalSteps: 3, currentStep: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    l10n.document_selection_title,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.document_selection_description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    l10n.document_selection_select_id,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDocCard(
                    type: 'CC',
                    title: l10n.document_selection_cc,
                    subtitle: l10n.document_selection_cc_desc,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDocCard(
                    type: 'Driver License',
                    title: l10n.document_selection_driver_license,
                    subtitle: l10n.document_selection_driver_license_desc,
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
                        l10n.document_selection_encryption_notice,
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
              child: PrimaryActionButton(
                onPressed: _onNext,
                icon: Icons.arrow_forward,
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
