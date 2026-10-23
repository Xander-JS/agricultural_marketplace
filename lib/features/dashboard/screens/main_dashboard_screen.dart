import 'package:flutter/material.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/navigation/app_bottom_navigation.dart';
import '../../profile/screens/farmer_profile_screen.dart';
import '../../crop/screens/marketplace_screen.dart';
import '../../costs/screens/costs_screen.dart';
import '../../deals/screens/deals_screen.dart';
import '../../purchases/screens/purchases_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String role;
  final Future<void> Function()? onSignOut;

  const MainDashboardScreen({super.key, required this.role, this.onSignOut});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  /// Drives the entrance of the section that just became active: a
  /// 220ms cross-fade with a 2% rise, the way a native tab settles.
  late final AnimationController _tabController = AnimationController(
    vsync: this,
    duration: AppMotion.tabSwitch,
    value: 1,
  );
  late final Animation<double> _tabCurve = CurvedAnimation(
    parent: _tabController,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _tabSlide = Tween<Offset>(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).animate(_tabCurve);

  bool get _isBuyer => UserRole.isBuyerRole(widget.role);

  @override
  void initState() {
    super.initState();
    if (_isBuyer) {
      _screens = [
        MarketplaceScreen(role: widget.role, onProfileTap: () => _selectTab(3)),
        DealsScreen(role: widget.role, onEmptyAction: () => _selectTab(0)),
        PurchasesScreen(onExploreMarket: () => _selectTab(0)),
        FarmerProfileScreen(onSignOut: widget.onSignOut),
      ];
    } else {
      _screens = [
        MarketplaceScreen(role: widget.role, onProfileTap: () => _selectTab(3)),
        DealsScreen(role: widget.role, onEmptyAction: () => _selectTab(0)),
        const CostsScreen(),
        FarmerProfileScreen(onSignOut: widget.onSignOut),
      ];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    if (AppMotion.reduced(context)) {
      _tabController.value = 1;
    } else {
      _tabController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Every section stays mounted (IndexedStack) so search terms, scroll
    // offsets and loaded data survive a tab switch; only the incoming
    // section animates. Each child keeps the same wrapper on every build,
    // so switching never remounts a section. Hidden sections have their
    // tickers muted, which also pauses their shimmer while offstage.
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            TickerMode(
              enabled: i == _currentIndex,
              child: FadeTransition(
                opacity: i == _currentIndex
                    ? _tabCurve
                    : kAlwaysCompleteAnimation,
                child: SlideTransition(
                  position: i == _currentIndex
                      ? _tabSlide
                      : const AlwaysStoppedAnimation(Offset.zero),
                  child: _screens[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        role: widget.role,
        currentIndex: _currentIndex,
        onTap: _selectTab,
      ),
    );
  }
}
