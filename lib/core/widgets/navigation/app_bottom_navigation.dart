import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A reusable bottom navigation bar for the application.
/// It is shared across roles (agricultor, comerciante/comprador).
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: AppColors.lightSurface,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.lightTertiary,
          unselectedItemColor: AppColors.lightTextSecondary,
          selectedLabelStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTextStyles.labelMedium,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Mercado',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake_outlined),
              activeIcon: Icon(Icons.handshake),
              label: 'Tratos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Costos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined), // Finca/Plant icon
              activeIcon: Icon(Icons.spa),
              label: 'Mi Finca',
            ),
          ],
        ),
      ),
    );
  }
}
