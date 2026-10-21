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

  // Brand / Decorative Colors
  static const Color brandEmerald = Color(0xFF04894D);
  static const Color brandGradientStart = Color(0xFFB8EDBE);
  static const Color brandGradientMiddle = Color(0xFFCBF3D0);
  static const Color brandGradientEnd = Color(0xFFE6F8E4);
  static const List<Color> brandGradient = <Color>[
    brandGradientStart,
    brandGradientMiddle,
    brandGradientEnd,
  ];

  // Loading Screen Color
  static const Color loadingBackground = brandEmerald;

  // Text/icon colors used on top of brand or media backgrounds
  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color onBrandSecondary = Color(0xFFE3F1E5);
  static const Color transparent = Color(0x00000000);

  // WhatsApp brand color
  static const Color whatsapp = Color(0xFF25D366);

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
  static const Color infoLight = Color(0xFF2A5324);

  // Feedback tokens for dark surfaces (higher luminance for contrast)
  static const Color successDark = Color(0xFF81C784);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color errorDark = Color(0xFFEF9A9A);
  static const Color infoDark = Color(0xFF64B5F6);

  static const Color successDarkContainer = Color(0xFF1B3A1E);
  static const Color warningDarkContainer = Color(0xFF3D2A11);
  static const Color errorDarkContainer = Color(0xFF3D1C1C);
  static const Color infoDarkContainer = Color(0xFF102D3D);

  // ---------------------------------------------------------
  // Semantic Status Badge Tokens
  // ---------------------------------------------------------
  static const Color statusPreventaBackground = Color(0xFFFDE8E0);
  static const Color statusPreventaText = Color(0xFFC04F15);
  static const Color statusReadyBackground = Color(0xFFE9F5E9);
  static const Color statusReadyText = success;
}

/// Theme-aware semantic colors resolved from the active [Theme].
///
/// Widgets should consume these tokens instead of choosing between the
/// fixed `light*`/`dark*` primitives, so both modes stay consistent.
extension AppThemeColors on BuildContext {
  ColorScheme get appColorScheme => Theme.of(this).colorScheme;
  bool get appIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => appColorScheme.surface;
  Color get appSurfaceVariant => appColorScheme.surfaceContainerHighest;
  Color get appTextPrimary => appColorScheme.onSurface;
  Color get appTextSecondary => appColorScheme.onSurfaceVariant;
  Color get appTextDisabled =>
      appColorScheme.onSurfaceVariant.withValues(alpha: 0.55);
  Color get appPrimary => appColorScheme.primary;
  Color get appOnPrimary => appColorScheme.onPrimary;
  Color get appPrimaryContainer => appColorScheme.primaryContainer;
  Color get appOnPrimaryContainer => appColorScheme.onPrimaryContainer;
  Color get appBorder => appColorScheme.outline;
  Color get appDivider => appColorScheme.outlineVariant;

  Color get appSuccess => appIsDark ? AppColors.successDark : AppColors.success;
  Color get appSuccessContainer =>
      appIsDark ? AppColors.successDarkContainer : AppColors.successLight;
  Color get appWarning => appIsDark ? AppColors.warningDark : AppColors.warning;
  Color get appWarningContainer =>
      appIsDark ? AppColors.warningDarkContainer : AppColors.warningLight;
  Color get appError => appColorScheme.error;
  Color get appErrorContainer =>
      appIsDark ? AppColors.errorDarkContainer : AppColors.errorLight;
  Color get appInfo => appIsDark ? AppColors.infoDark : AppColors.info;
  Color get appInfoContainer =>
      appIsDark ? AppColors.infoDarkContainer : AppColors.infoLight;

  Color get appShadow => appIsDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.05);
  Color get appOverlayText => AppColors.onBrand;
  Color get appOverlayTextSecondary => AppColors.onBrandSecondary;
}
