import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Centralized ThemeData definitions for the application.
///
/// Provides light (primary) and dark (secondary) theme configurations
/// utilizing tokens from [AppColors], [AppDimensions], and [AppTextStyles].
abstract final class AppTheme {
  // ---------------------------------------------------------
  // Light Theme (Primary)
  // ---------------------------------------------------------
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightTertiary, // High contrast interactive green
      onPrimary: AppColors.lightPrimary,
      primaryContainer: AppColors.lightSecondary,
      onPrimaryContainer: AppColors.lightTertiary,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightTertiary,
      secondaryContainer: AppColors.lightNeutral,
      onSecondaryContainer: AppColors.lightTextPrimary,
      tertiary: AppColors.lightTertiary,
      onTertiary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,

      // Typography
      fontFamily: AppTextStyles.fontFamilyMontserrat,
      textTheme: AppTextStyles.createTextTheme(
        textColor: AppColors.lightTextPrimary,
        secondaryTextColor: AppColors.lightTextSecondary,
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamilyPlayfair,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.lightTertiary,
          foregroundColor: AppColors.lightPrimary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMedium),
          padding: AppDimensions.paddingButtonMedium,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMD,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTertiary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMedium),
          padding: AppDimensions.paddingButtonMedium,
          textStyle: AppTextStyles.buttonMedium,
          side: const BorderSide(
            color: AppColors.lightTertiary,
            width: AppDimensions.borderWidthThin,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMD,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightTertiary,
          padding: AppDimensions.paddingButtonSmall,
          textStyle: AppTextStyles.buttonSmall,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSM,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextDisabled),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.lightTertiary,
            width: AppDimensions.borderWidthMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthMedium,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.space16,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightTertiary,
        unselectedItemColor: AppColors.lightTextDisabled,
        selectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamilyPoppins,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamilyPoppins,
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ---------------------------------------------------------
  // Dark Theme (Secondary)
  // ---------------------------------------------------------
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkTertiary, // High contrast legible sage green
      onPrimary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkSecondary,
      onPrimaryContainer: AppColors.darkTertiary,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkTertiary,
      secondaryContainer: AppColors.darkNeutral,
      onSecondaryContainer: AppColors.darkTextPrimary,
      tertiary: AppColors.darkTertiary,
      onTertiary: AppColors.darkPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkDivider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Typography
      fontFamily: AppTextStyles.fontFamilyMontserrat,
      textTheme: AppTextStyles.createTextTheme(
        textColor: AppColors.darkTextPrimary,
        secondaryTextColor: AppColors.darkTextSecondary,
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamilyPlayfair,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkTertiary,
          foregroundColor: AppColors.darkPrimary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMedium),
          padding: AppDimensions.paddingButtonMedium,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMD,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTertiary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMedium),
          padding: AppDimensions.paddingButtonMedium,
          textStyle: AppTextStyles.buttonMedium,
          side: const BorderSide(
            color: AppColors.darkTertiary,
            width: AppDimensions.borderWidthThin,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMD,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkTertiary,
          padding: AppDimensions.paddingButtonSmall,
          textStyle: AppTextStyles.buttonSmall,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSM,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextDisabled),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.darkTertiary,
            width: AppDimensions.borderWidthMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMD,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthMedium,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.space16,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkTertiary,
        unselectedItemColor: AppColors.darkTextDisabled,
        selectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamilyPoppins,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamilyPoppins,
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
