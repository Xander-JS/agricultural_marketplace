import 'package:flutter/material.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/widgets/navigation/app_bottom_navigation.dart';
import '../../profile/screens/farmer_profile_screen.dart';
import '../../crop/screens/marketplace_screen.dart';
import '../../costs/screens/costs_screen.dart';
import '../../deals/screens/deals_screen.dart';
import '../../purchases/screens/purchases_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String role;
  final Future<void> Function()? onSignOut;

  const MainDashboardScreen({
    super.key,
    required this.role,
    this.onSignOut,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  bool get _isBuyer => UserRole.isBuyerRole(widget.role);

  @override
  void initState() {
    super.initState();
    void goToProfileTab() {
      setState(() {
        _currentIndex = 3;
      });
    }

    if (_isBuyer) {
      _screens = [
        MarketplaceScreen(
          role: widget.role,
          onProfileTap: goToProfileTab,
        ),
        DealsScreen(role: widget.role),
        PurchasesScreen(
          onExploreMarket: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
        FarmerProfileScreen(onSignOut: widget.onSignOut),
      ];
    } else {
      _screens = [
        MarketplaceScreen(
          role: widget.role,
          onProfileTap: goToProfileTab,
        ),
        DealsScreen(role: widget.role),
        const CostsScreen(),
        FarmerProfileScreen(onSignOut: widget.onSignOut),
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

