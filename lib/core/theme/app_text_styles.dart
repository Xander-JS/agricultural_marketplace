import 'package:flutter/material.dart';

/// KUS typography: one family, Plus Jakarta Sans, bundled in
/// `assets/google_fonts/` and declared in `pubspec.yaml`.
///
/// Hierarchy comes from weight and tracking rather than mixing families:
/// - Display (800): screen heroes and brand moments, tight negative tracking.
/// - Headline / Title (600-700): section and card headers.
/// - Body (400-500): reading text, inputs and lists.
/// - Figures: prices, costs and quantities use tabular numerals so columns of
///   COP amounts align digit by digit.
abstract final class AppTextStyles {
  // ---------------------------------------------------------
  // Font Family Names
  // ---------------------------------------------------------
  static const String fontFamilyJakarta = 'Plus Jakarta Sans';

  /// Legacy names kept for compatibility; all resolve to Plus Jakarta Sans.
  static const String fontFamilyPlayfair = fontFamilyJakarta;
  static const String fontFamilyMontserrat = fontFamilyJakarta;
  static const String fontFamilyPoppins = fontFamilyJakarta;

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ---------------------------------------------------------
  // Display & Headlines
  // ---------------------------------------------------------
  /// Large hero titles (onboarding, auth screens).
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 32.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
  );

  /// Screen titles.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 26.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.2,
  );

  /// Subsection titles and main card headers.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  /// Navigation bar titles, modal titles and compact group headings.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 19.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // ---------------------------------------------------------
  // Titles
  // ---------------------------------------------------------
  /// Primary subtitle or featured lead text.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );

  /// Card titles and list section headers.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// Small subtitle and emphasised metadata.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  // ---------------------------------------------------------
  // Body
  // ---------------------------------------------------------
  /// Main reading text (descriptions, long-form content).
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Default interface text for inputs and lists.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  /// Secondary info and helper copy.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  // ---------------------------------------------------------
  // Buttons & Interactive Elements
  // ---------------------------------------------------------
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  // ---------------------------------------------------------
  // Labels, Badges & Captions
  // ---------------------------------------------------------
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.35,
  );

  // ---------------------------------------------------------
  // Figures (tabular numerals for COP prices, costs and quantities)
  // ---------------------------------------------------------
  /// Hero amounts: the headline price of a crop or a deal total.
  static const TextStyle figureLarge = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 22.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
    fontFeatures: tabularFigures,
  );

  /// Prices inside cards and list rows.
  static const TextStyle figureMedium = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 17.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
    fontFeatures: tabularFigures,
  );

  /// Quantities and secondary amounts in tables.
  static const TextStyle figureSmall = TextStyle(
    fontFamily: fontFamilyJakarta,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    fontFeatures: tabularFigures,
  );

  // ---------------------------------------------------------
  // TextTheme Builder for Material Theme integration
  // ---------------------------------------------------------
  /// Creates a [TextTheme] bound to the given text colors.
  static TextTheme createTextTheme({
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      displaySmall: displaySmall.copyWith(color: textColor),
      headlineMedium: headlineMedium.copyWith(color: textColor),
      headlineSmall: titleLarge.copyWith(color: textColor),
      titleLarge: titleLarge.copyWith(color: textColor),
      titleMedium: titleMedium.copyWith(color: textColor),
      titleSmall: titleSmall.copyWith(color: secondaryTextColor),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: textColor),
      bodySmall: bodySmall.copyWith(color: secondaryTextColor),
      labelLarge: buttonMedium.copyWith(color: textColor),
      labelMedium: labelMedium.copyWith(color: secondaryTextColor),
      labelSmall: labelSmall.copyWith(color: secondaryTextColor),
    );
  }
}
