import 'package:flutter/material.dart';
import '../../constants/user_roles.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Reusable bottom navigation bar for the application.
///
/// Adapts its four items to the farmer or buyer role and follows the active
/// light/dark theme.
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

  bool get _isBuyer => UserRole.isBuyerRole(role);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final marketLabel = _isBuyer ? l10n.nav_my_market : l10n.nav_market;
    final thirdTabLabel = _isBuyer ? l10n.nav_purchases : l10n.nav_costs;

    final thirdTabIcon = _isBuyer
        ? const Icon(Icons.shopping_bag_outlined)
        : const Icon(Icons.bar_chart_outlined);
    final thirdTabActiveIcon = _isBuyer
        ? const Icon(Icons.shopping_bag)
        : const Icon(Icons.bar_chart);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.appShadow,
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: colors.surface,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.onSurfaceVariant,
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
              label: l10n.nav_deals,
            ),
            BottomNavigationBarItem(
              icon: thirdTabIcon,
              activeIcon: thirdTabActiveIcon,
              label: thirdTabLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.spa_outlined),
              activeIcon: const Icon(Icons.spa),
              label: l10n.nav_my_farm,
            ),
          ],
        ),
      ),
    );
  }
}
