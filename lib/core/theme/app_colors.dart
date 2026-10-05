import 'package:flutter/material.dart';

/// Centralized color palette for Agricultural Marketplace.
///
/// Contains primitive color definitions as well as semantically structured
/// color schemes for Light and Dark modes.
abstract final class AppColors {
  // ---------------------------------------------------------
  // Light Palette (Primary Theme)
  // ---------------------------------------------------------
  static const Color lightPrimary = Color(0xFFF5F5DC); // Beige / Crema suave
  static const Color lightSecondary = Color(0xFFE6F8E4); // Menta claro / Verde pastel
  static const Color lightTertiary = Color(0xFF2A5324); // Verde bosque / Tono acento oscuro
  static const Color lightNeutral = Color(0xFFFFDBC1); // Melocotón suave / Tono tierra claro

  // Surfaces and Texts for Light Theme
  static const Color lightBackground = Color(0xFFFCFDF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1B2218);
  static const Color lightTextSecondary = Color(0xFF4C5B48);
  static const Color lightTextDisabled = Color(0xFF8F9C8B);
  static const Color lightDivider = Color(0xFFE0E5DD);
  static const Color lightBorder = Color(0xFFD0D7CC);

  // Loading Screen Color
  static const Color loadingBackground = Color(0xFF04894D);

  // ---------------------------------------------------------
  // Dark Palette (Secondary Theme)
  // ---------------------------------------------------------
  static const Color darkPrimary = Color(0xFF263322); // Verde oliva muy oscuro
  static const Color darkSecondary = Color(0xFF344A32); // Verde musgo profundo
  static const Color darkTertiary = Color(0xFFA8C99A); // Verde salvia claro
  static const Color darkNeutral = Color(0xFF5A4638); // Marrón café cálido

  // Surfaces and Texts for Dark Theme
  static const Color darkBackground = Color(0xFF131A12);
  static const Color darkSurface = Color(0xFF1A2318);
  static const Color darkSurfaceVariant = Color(0xFF232D21);
  static const Color darkTextPrimary = Color(0xFFF0F5ED);
  static const Color darkTextSecondary = Color(0xFFB5C3B1);
  static const Color darkTextDisabled = Color(0xFF6B7A68);
  static const Color darkDivider = Color(0xFF2E3A2C);
  static const Color darkBorder = Color(0xFF3B4A39);

  // ---------------------------------------------------------
  // Universal Semantic Feedback Colors
  // ---------------------------------------------------------
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color infoLight = Color(0xFFE1F5FE);
}
