import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    if (_selectedRole != null) {
      widget.data.role = _selectedRole;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentSelectionScreen(data: widget.data),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un rol')),
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
          'Account Credentials',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundColor: AppColors.success, radius: 16),
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
                    child: Container(height: 4, color: AppColors.success),
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
                    'Choose the role that best describes your activity on the platform.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildRoleCard(
                    role: 'agricultor',
                    title: 'Producer',
                    subtitle: 'Sell & Distribute',
                    description: 'Direct marketplace listing & analytics',
                    icon: Icons.agriculture,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    role: 'comprador',
                    title: 'Buyer',
                    subtitle: 'Source & Purchase',
                    description: 'Transparent logistics & batch provenance',
                    icon: Icons.shopping_basket_outlined,
                  ),
                  const SizedBox(height: 24),

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
                        'KYC Verification applies after role selection',
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

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final bgColor = isSelected
        ? AppColors.lightSecondary
        : AppColors.infoLight.withOpacity(0.3);
    final borderColor = isSelected ? AppColors.success : Colors.transparent;
    final iconBgColor = isSelected ? AppColors.success : AppColors.infoLight;
    final iconColor = isSelected ? Colors.white : AppColors.lightTextPrimary;

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
                    borderRadius: BorderRadius.circular(16),
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
                              ? AppColors.successLight
                              : AppColors.lightBorder.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subtitle,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.success
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.lightTextPrimary,
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.verified_user_outlined
                        : Icons.local_shipping_outlined,
                    size: 16,
                    color: AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.lightTextSecondary,
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
