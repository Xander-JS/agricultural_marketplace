import 'package:flutter/material.dart';
import '../../../../core/widgets/navigation/app_bottom_navigation.dart';
import '../../profile/screens/farmer_profile_screen.dart';
import '../../crop/screens/marketplace_screen.dart';
import '../../costs/screens/costs_screen.dart';
import '../../deals/screens/deals_screen.dart';
import '../../purchases/screens/purchases_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String role;

  const MainDashboardScreen({super.key, required this.role});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  bool get _isBuyer {
    final normalized = widget.role.trim().toLowerCase();
    return normalized == 'comprador' || normalized == 'comerciante';
  }

  @override
  void initState() {
    super.initState();
    if (_isBuyer) {
      _screens = [
        MarketplaceScreen(role: widget.role),
        const DealsScreen(),
        const PurchasesScreen(),
        const FarmerProfileScreen(),
      ];
    } else {
      _screens = [
        MarketplaceScreen(role: widget.role),
        const DealsScreen(),
        const CostsScreen(),
        const FarmerProfileScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        role: widget.role,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

