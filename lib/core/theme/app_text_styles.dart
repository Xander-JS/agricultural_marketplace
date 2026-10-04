import 'package:flutter/material.dart';

/// Centralized typographic styles using Playfair Display, Montserrat, and Poppins.
///
/// Fonts used:
/// - Playfair Display: Titles and principal headlines.
/// - Montserrat: General body copy, forms, and informational content.
/// - Poppins: Buttons, tags, subheadings, and interactive elements.
abstract final class AppTextStyles {
  // ---------------------------------------------------------
  // Font Family Names
  // ---------------------------------------------------------
  static const String fontFamilyPlayfair = 'Playfair Display';
  static const String fontFamilyMontserrat = 'Montserrat';
  static const String fontFamilyPoppins = 'Poppins';

  // ---------------------------------------------------------
  // Titles & Headlines (Playfair Display)
  // ---------------------------------------------------------
  /// Large main display titles (e.g., Hero headers, onboarding welcome)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyPlayfair,
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  /// Section headers and screen titles
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyPlayfair,
    fontSize: 26.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.3,
  );

  /// Subsection titles and main card headers
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyPlayfair,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// Modal titles and compact group headings
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyPlayfair,
    fontSize: 19.0,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // ---------------------------------------------------------
  // Subtitles & Interactive Highlights (Poppins)
  // ---------------------------------------------------------
  /// Primary subtitle or featured lead text
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// Medium card titles and list section headers
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// Small subtitle and emphasis metadata
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  // ---------------------------------------------------------
  // Body & General Content (Montserrat)
  // ---------------------------------------------------------
  /// Main readable body text (articles, detailed descriptions)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyMontserrat,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// Default text for interface, inputs, and listings
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyMontserrat,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.45,
  );

  /// Secondary info, captions, and hint text
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyMontserrat,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.4,
  );

  // ---------------------------------------------------------
  // Buttons & Interactive Elements (Poppins)
  // ---------------------------------------------------------
  /// Large CTA buttons
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Standard buttons
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
  );

  /// Small action buttons and text buttons
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ---------------------------------------------------------
  // Badges, Chips & Auxiliary Text (Poppins / Montserrat)
  // ---------------------------------------------------------
  /// Tags, badges, and pill indicators
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  /// Smallest status chips, timestamps, or footnote indicators
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyPoppins,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  /// Auxiliary helper text, errors, or captions
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyMontserrat,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.35,
  );

  // ---------------------------------------------------------
  // TextTheme Builder for Material Theme integration
  // ---------------------------------------------------------
  /// Creates a [TextTheme] bound to the given base [textColor].
  static TextTheme createTextTheme({required Color textColor, required Color secondaryTextColor}) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      displaySmall: displaySmall.copyWith(color: textColor),
      headlineMedium: headlineMedium.copyWith(color: textColor),
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
