import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/navigation/app_bottom_navigation.dart';
import '../../profile/screens/farmer_profile_screen.dart';
import '../../crop/screens/marketplace_screen.dart';
import '../../costs/screens/costs_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String role;

  const MainDashboardScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const MarketplaceScreen(), // Índice 0 es Mercado
      const Center(child: Text('Tratos')),
      const CostsScreen(), // Índice 2 es Costos

      const FarmerProfileScreen(), // Índice 3 es Mi Finca
    ];
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
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
