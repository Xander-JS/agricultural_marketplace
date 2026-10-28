import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Centralized ThemeData for KUS.
///
/// iOS-leaning Material 3: grouped grounds, flat 1px-bordered surfaces,
/// 14px controls, floating capsule snackbars, 28px sheets and Cupertino
/// page transitions on every platform.
abstract final class AppTheme {
  static ThemeData get lightTheme => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightBrandPrimary,
      onPrimary: AppColors.lightOnBrandPrimary,
      primaryContainer: AppColors.lightPrimarySoft,
      onPrimaryContainer: AppColors.lightOnPrimarySoft,
      secondary: AppColors.lightHarvestAmber,
      onSecondary: AppColors.lightTextPrimary,
      secondaryContainer: AppColors.warningBgLight,
      onSecondaryContainer: Color(0xFF92400E),
      tertiary: AppColors.lightAccentAi,
      onTertiary: AppColors.lightOnBrandPrimary,
      tertiaryContainer: AppColors.infoBgLight,
      onTertiaryContainer: Color(0xFF075985),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      surfaceContainerHigh: AppColors.lightSurfaceVariant,
      surfaceContainer: AppColors.lightBackground,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainerLowest: AppColors.lightSurface,
      error: AppColors.errorFgLight,
      onError: AppColors.lightOnBrandPrimary,
      errorContainer: AppColors.errorBgLight,
      onErrorContainer: Color(0xFF991B1B),
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightDivider,
      shadow: Color(0xFF0B110E),
      inverseSurface: AppColors.lightTextPrimary,
      onInverseSurface: AppColors.darkTextPrimary,
      inversePrimary: AppColors.darkBrandPrimary,
      surfaceTint: AppColors.transparent,
    ),
    background: AppColors.lightBackground,
    textMuted: AppColors.lightTextMuted,
  );

  static ThemeData get darkTheme => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkBrandPrimary,
      onPrimary: AppColors.darkOnBrandPrimary,
      primaryContainer: AppColors.darkPrimarySoft,
      onPrimaryContainer: AppColors.darkOnPrimarySoft,
      secondary: AppColors.darkHarvestAmber,
      onSecondary: Color(0xFF1C1407),
      secondaryContainer: AppColors.warningBgDark,
      onSecondaryContainer: AppColors.warningFgDark,
      tertiary: AppColors.darkAccentAi,
      onTertiary: Color(0xFF062033),
      tertiaryContainer: AppColors.infoBgDark,
      onTertiaryContainer: AppColors.infoFgDark,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      surfaceContainerHigh: AppColors.darkSurfaceVariant,
      surfaceContainer: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainerLowest: AppColors.darkBackground,
      error: AppColors.errorFgDark,
      onError: AppColors.errorBgDark,
      errorContainer: AppColors.errorBgDark,
      onErrorContainer: AppColors.errorFgDark,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkDivider,
      shadow: Color(0xFF000000),
      inverseSurface: AppColors.darkTextPrimary,
      onInverseSurface: AppColors.lightTextPrimary,
      inversePrimary: AppColors.lightBrandPrimary,
      surfaceTint: AppColors.transparent,
    ),
    background: AppColors.darkBackground,
    textMuted: AppColors.darkTextMuted,
  );

  /// Equivalent of `GoogleFonts.plusJakartaSansTextTheme(base)`.
  ///
  /// google_fonts 9 types its TextTheme helpers against `package:material_ui`,
  /// whose [TextTheme] is not the framework's; applying the family per style
  /// gives the same result with the framework type.
  static TextTheme _plusJakartaSansTextTheme(TextTheme base) {
    TextStyle? apply(TextStyle? style) =>
        style == null ? null : GoogleFonts.plusJakartaSans(textStyle: style);
    return base.copyWith(
      displayLarge: apply(base.displayLarge),
      displayMedium: apply(base.displayMedium),
      displaySmall: apply(base.displaySmall),
      headlineLarge: apply(base.headlineLarge),
      headlineMedium: apply(base.headlineMedium),
      headlineSmall: apply(base.headlineSmall),
      titleLarge: apply(base.titleLarge),
      titleMedium: apply(base.titleMedium),
      titleSmall: apply(base.titleSmall),
      bodyLarge: apply(base.bodyLarge),
      bodyMedium: apply(base.bodyMedium),
      bodySmall: apply(base.bodySmall),
      labelLarge: apply(base.labelLarge),
      labelMedium: apply(base.labelMedium),
      labelSmall: apply(base.labelSmall),
    );
  }

  static ThemeData _build(
    ColorScheme colors, {
    required Color background,
    required Color textMuted,
  }) {
    final isDark = colors.brightness == Brightness.dark;
    final textTheme = _plusJakartaSansTextTheme(
      AppTextStyles.createTextTheme(
        textColor: colors.onSurface,
        secondaryTextColor: colors.onSurfaceVariant,
      ),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: AppDimensions.borderRadiusControl,
    );
    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusControl,
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      // Icons follow the user's text-size preference (MediaQuery.textScaler).
      iconTheme: const IconThemeData(applyTextScaling: true),
      canvasColor: background,
      fontFamily: AppTextStyles.fontFamilyJakarta,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: colors.onSurface.withValues(alpha: 0.04),
      dividerColor: colors.outlineVariant,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),

      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: colors.brightness,
        primaryColor: colors.primary,
        scaffoldBackgroundColor: background,
        barBackgroundColor: colors.surface,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: background,
        surfaceTintColor: AppColors.transparent,
        foregroundColor: colors.onSurface,
        iconTheme: IconThemeData(
          color: colors.onSurface,
          size: 22,
          applyTextScaling: true,
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          fontSize: 17,
          color: colors.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shadowColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLG,
          side: BorderSide(
            color: colors.outline,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: AppColors.transparent,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceContainerHighest,
          disabledForegroundColor: textMuted,
          minimumSize: const Size.fromHeight(
            AppDimensions.buttonHeightPrimary,
          ),
          padding: AppDimensions.paddingButtonMedium,
          textStyle: AppTextStyles.buttonLarge,
          shape: controlShape,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size.fromHeight(
            AppDimensions.buttonHeightPrimary,
          ),
          textStyle: AppTextStyles.buttonLarge,
          shape: controlShape,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMedium),
          padding: AppDimensions.paddingButtonMedium,
          textStyle: AppTextStyles.buttonMedium,
          side: BorderSide(
            color: colors.outline,
            width: AppDimensions.borderWidthThin,
          ),
          shape: controlShape,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: AppDimensions.paddingButtonSmall,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusSM,
          ),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurface,
          minimumSize: const Size.square(AppDimensions.minTouchTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLG,
        ),
        extendedTextStyle: AppTextStyles.buttonLarge,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space16,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.primary,
        ),
        // Secondary text keeps hints >= 4.5:1 on the input fill in both modes.
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurfaceVariant,
        ),
        helperStyle: AppTextStyles.bodySmall.copyWith(
          color: colors.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: colors.error),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
        border: inputBorder(AppColors.transparent, 0),
        enabledBorder: inputBorder(AppColors.transparent, 0),
        disabledBorder: inputBorder(AppColors.transparent, 0),
        focusedBorder: inputBorder(
          colors.primary,
          AppDimensions.borderWidthMedium,
        ),
        errorBorder: inputBorder(colors.error, AppDimensions.borderWidthThin),
        focusedErrorBorder: inputBorder(
          colors.error,
          AppDimensions.borderWidthMedium,
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.22),
        selectionHandleColor: colors.primary,
      ),

      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.space16,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: colors.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMD,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHighest,
        selectedColor: colors.primaryContainer,
        disabledColor: colors.surfaceContainerHighest,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.onPrimaryContainer,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusFull,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8),
        checkmarkColor: colors.onPrimaryContainer,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        circularTrackColor: AppColors.transparent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: colors.outline,
        dragHandleSize: const Size(36, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusSheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXL,
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: colors.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colors.inversePrimary,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          AppDimensions.space16,
          0,
          AppDimensions.space16,
          AppDimensions.space12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLG,
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: AppDimensions.borderRadiusSM,
        ),
        textStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.onInverseSurface,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: AppTextStyles.titleSmall,
        unselectedLabelStyle: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: colors.primary,
        dividerColor: colors.outlineVariant,
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }
}
