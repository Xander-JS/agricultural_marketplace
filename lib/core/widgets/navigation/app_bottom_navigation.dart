import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Barra de navegación inferior reutilizable para la aplicación.
///
/// Soporta de forma modular tanto el rol agricultor como el rol comerciante/comprador,
/// adaptando los 4 ítems de navegación según el rol y respetando los modos claro y oscuro.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'agricultor',
  });

  bool get _isBuyer {
    final normalized = role.trim().toLowerCase();
    return normalized == 'comprador' || normalized == 'comerciante';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final selectedColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final marketLabel = _isBuyer
        ? (l10n?.nav_my_market ?? 'Mi mercado')
        : (l10n?.nav_market ?? 'Mercado');
    final dealsLabel = l10n?.nav_deals ?? 'Tratos';
    final thirdTabLabel = _isBuyer
        ? (l10n?.nav_purchases ?? 'Compras')
        : (l10n?.nav_costs ?? 'Costos');
    final farmLabel = l10n?.nav_my_farm ?? 'Mi Finca';

    final thirdTabIcon = _isBuyer
        ? const Icon(Icons.shopping_bag_outlined)
        : const Icon(Icons.bar_chart_outlined);
    final thirdTabActiveIcon = _isBuyer
        ? const Icon(Icons.shopping_bag)
        : const Icon(Icons.bar_chart);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: surfaceColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedLabelStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTextStyles.labelMedium,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_outlined),
              activeIcon: const Icon(Icons.storefront),
              label: marketLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.handshake_outlined),
              activeIcon: const Icon(Icons.handshake),
              label: dealsLabel,
            ),
            BottomNavigationBarItem(
              icon: thirdTabIcon,
              activeIcon: thirdTabActiveIcon,
              label: thirdTabLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.spa_outlined),
              activeIcon: const Icon(Icons.spa),
              label: farmLabel,
            ),
          ],
        ),
      ),
    );
  }
}
