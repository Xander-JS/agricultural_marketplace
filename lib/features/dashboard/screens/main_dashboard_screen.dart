import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/navigation/app_bottom_navigation.dart';

class MainDashboardScreen extends StatefulWidget {
  final String role;

  const MainDashboardScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panel de ${_capitalize(widget.role)}',
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Bienvenido a tu panel de ${widget.role.toUpperCase()}',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
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
