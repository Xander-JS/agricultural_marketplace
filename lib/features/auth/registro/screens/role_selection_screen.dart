import 'package:flutter/material.dart';
import 'package:agricultural_marketplace/core/localization/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bar/custom_app_bar.dart';
import '../../../../core/widgets/progress/step_progress_bar.dart';
import '../../../../core/widgets/buttons/primary_action_button.dart';
import '../models/registration_data.dart';
import 'document_selection_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final RegistrationData data;
  const RoleSelectionScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.data.role;
  }

  void _onNext() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRole != null) {
      widget.data.role = _selectedRole;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentSelectionScreen(data: widget.data),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.role_selection_error_no_role)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(title: l10n.role_selection_header_title),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(totalSteps: 4, currentStep: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    l10n.role_selection_title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildRoleCard(
                    context: context,
                    role: 'agricultor',
                    title: l10n.role_selection_producer,
                    subtitle: l10n.role_selection_producer_subtitle,
                    description: l10n.role_selection_producer_description,
                    icon: Icons.agriculture,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context: context,
                    role: 'comprador',
                    title: l10n.role_selection_buyer,
                    subtitle: l10n.role_selection_buyer_subtitle,
                    description: l10n.role_selection_buyer_description,
                    icon: Icons.shopping_basket_outlined,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: context.appTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.role_selection_kyc_notice,
                        style: AppTextStyles.caption.copyWith(
                          color: context.appTextSecondary,
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

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final bgColor = isSelected
        ? context.appPrimaryContainer
        : context.appInfoContainer.withValues(alpha: 0.5);
    final borderColor = isSelected ? context.appSuccess : AppColors.transparent;
    final iconBgColor = isSelected ? context.appSuccess : AppColors.transparent;
    final iconColor = isSelected ? AppColors.onBrand : context.appTextPrimary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: context.appTextPrimary),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.appSuccessContainer
                              : context.appBorder.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subtitle,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? context.appSuccess
                                : context.appTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: context.appTextPrimary,
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
                        ? context.appSuccess
                        : context.appBorder.withValues(alpha: 0.5),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: AppColors.onBrand, size: 16)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.verified_user_outlined
                        : Icons.local_shipping_outlined,
                    size: 16,
                    color: context.appTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
