import 'package:flutter/material.dart';

/// KUS color system ("Apple Agri-Fintech").
///
/// Primitive values for Light and Dark modes plus the semantic triads used by
/// badges, banners and alerts: soft background + 1px border + strong
/// foreground. Widgets should read colors through [AppThemeColors] so both
/// modes stay consistent; the `light*`/`dark*` primitives exist for
/// [ThemeData] construction and legacy call sites.
abstract final class AppColors {
  // ---------------------------------------------------------
  // Light Palette
  // ---------------------------------------------------------
  static const Color lightBackground = Color(0xFFF4F6F4); // iOS grouped ground
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE8ECE9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFEBEEEC);

  static const Color lightBrandPrimary = Color(0xFF14532D); // Forest green
  static const Color lightOnBrandPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimarySoft = Color(0xFFDCFCE7);
  static const Color lightOnPrimarySoft = Color(0xFF14532D);
  static const Color lightHarvestAmber = Color(0xFFD97706);
  static const Color lightAccentAi = Color(0xFF0284C7); // Sapphire AI

  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF6B7280);
  static const Color lightTextDisabled = lightTextMuted;

  // ---------------------------------------------------------
  // Dark Palette
  // ---------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B110E); // Forest obsidian
  static const Color darkSurface = Color(0xFF151F1A);
  static const Color darkSurfaceVariant = Color(0xFF1F2D26);
  static const Color darkBorder = Color(0xFF26352D);
  static const Color darkDivider = Color(0xFF1F2B25);

  static const Color darkBrandPrimary = Color(0xFF34D399); // Luminous emerald
  static const Color darkOnBrandPrimary = Color(0xFF062E1E);
  static const Color darkPrimarySoft = Color(0xFF064E3B);
  static const Color darkOnPrimarySoft = Color(0xFF6EE7B7);
  static const Color darkHarvestAmber = Color(0xFFFBBF24);
  static const Color darkAccentAi = Color(0xFF38BDF8);

  /// Segmented-control thumb: one lightness step above the track, the way
  /// iOS lifts the selected segment in Dark Mode.
  static const Color darkSegmentThumb = Color(0xFF34473D);

  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);
  static const Color darkTextDisabled = darkTextMuted;

  // ---------------------------------------------------------
  // Legacy aliases (kept so existing screens compile unchanged)
  // ---------------------------------------------------------
  static const Color lightPrimary = lightBackground;
  static const Color lightSecondary = lightPrimarySoft;
  static const Color lightTertiary = lightBrandPrimary;
  static const Color lightNeutral = Color(0xFFFEF3C7);
  static const Color darkPrimary = darkOnBrandPrimary;
  static const Color darkSecondary = darkPrimarySoft;
  static const Color darkTertiary = darkBrandPrimary;
  static const Color darkNeutral = Color(0xFF3A2E12);

  // ---------------------------------------------------------
  // Brand stage
  // ---------------------------------------------------------
  /// Full-bleed brand ground for splash and blocking loaders. White text and
  /// marks ([onBrand]) keep AAA contrast on both stages.
  static const Color brandEmerald = lightBrandPrimary;
  static const Color loadingBackground = lightBrandPrimary;
  static const Color darkBrandStage = Color(0xFF0F2A1C);

  static const List<Color> brandGradient = <Color>[
    lightPrimarySoft,
    lightPrimarySoft,
  ];

  /// Auth header field: institutional forest falling into deep emerald.
  /// [onBrand] text and marks keep AAA contrast over both stops.
  static const Color authHeaderTopLight = lightBrandPrimary;
  static const Color authHeaderBottomLight = Color(0xFF0A3320);
  static const Color authHeaderTopDark = darkBrandStage;
  static const Color authHeaderBottomDark = Color(0xFF07150E);

  // Text/icon colors used on top of brand or media backgrounds
  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color onBrandSecondary = Color(0xFFD1FAE5);
  static const Color transparent = Color(0x00000000);

  // WhatsApp brand color
  static const Color whatsapp = Color(0xFF25D366);

  // ---------------------------------------------------------
  // Semantic triads: background / border / foreground
  // ---------------------------------------------------------
  static const Color errorBgLight = Color(0xFFFEF2F2);
  static const Color errorBorderLight = Color(0xFFFECACA);
  static const Color errorFgLight = Color(0xFFDC2626);
  static const Color errorBgDark = Color(0xFF2A1215);
  static const Color errorBorderDark = Color(0xFF7F1D1D);
  static const Color errorFgDark = Color(0xFFF87171);

  static const Color infoBgLight = Color(0xFFF0F9FF);
  static const Color infoBorderLight = Color(0xFFBAE6FD);
  static const Color infoFgLight = Color(0xFF0284C7);
  static const Color infoBgDark = Color(0xFF0C2536);
  static const Color infoBorderDark = Color(0xFF0369A1);
  static const Color infoFgDark = Color(0xFF38BDF8);

  static const Color warningBgLight = Color(0xFFFFFBEB);
  static const Color warningBorderLight = Color(0xFFFDE68A);
  static const Color warningFgLight = Color(0xFFD97706);
  static const Color warningBgDark = Color(0xFF29200B);
  static const Color warningBorderDark = Color(0xFF78350F);
  static const Color warningFgDark = Color(0xFFFBBF24);

  static const Color successBgLight = Color(0xFFF0FDF4);
  static const Color successBorderLight = Color(0xFFBBF7D0);
  static const Color successFgLight = Color(0xFF15803D);
  static const Color successBgDark = Color(0xFF0D2818);
  static const Color successBorderDark = Color(0xFF14532D);
  static const Color successFgDark = Color(0xFF4ADE80);

  // Light-mode text tones for small semantic text. The specified foregrounds
  // above stay for icons and borders; these deeper shades of the same hues
  // keep 12px labels at or above 4.5:1 on their soft backgrounds.
  static const Color errorTextLight = Color(0xFFB91C1C);
  static const Color infoTextLight = Color(0xFF0369A1);
  static const Color warningTextLight = Color(0xFFB45309);

  // Legacy semantic names mapped onto the triads
  static const Color success = successFgLight;
  static const Color warning = warningFgLight;
  static const Color error = errorFgLight;
  static const Color info = infoFgLight;

  static const Color successLight = successBgLight;
  static const Color warningLight = warningBgLight;
  static const Color errorLight = errorBgLight;
  static const Color infoLight = infoBgLight;

  static const Color successDark = successFgDark;
  static const Color warningDark = warningFgDark;
  static const Color errorDark = errorFgDark;
  static const Color infoDark = infoFgDark;

  static const Color successDarkContainer = successBgDark;
  static const Color warningDarkContainer = warningBgDark;
  static const Color errorDarkContainer = errorBgDark;
  static const Color infoDarkContainer = infoBgDark;

  // ---------------------------------------------------------
  // Status badge tokens (light primitives; badges resolve per theme)
  // ---------------------------------------------------------
  static const Color statusPreventaBackground = warningBgLight;
  static const Color statusPreventaText = Color(0xFFB45309);
  static const Color statusReadyBackground = successBgLight;
  static const Color statusReadyText = successFgLight;
}

/// Resolved soft background / border / foreground for one semantic state.
///
/// [foreground] colors icons and large text; [text] is the AA-safe tone for
/// small text on [background] (identical to [foreground] where it already
/// passes).
@immutable
class AppSemanticTriad {
  final Color background;
  final Color border;
  final Color foreground;
  final Color text;

  const AppSemanticTriad({
    required this.background,
    required this.border,
    required this.foreground,
    Color? text,
  }) : text = text ?? foreground;
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
  Color get appTextMuted =>
      appIsDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get appTextDisabled => appTextMuted;
  Color get appPrimary => appColorScheme.primary;
  Color get appOnPrimary => appColorScheme.onPrimary;
  Color get appPrimaryContainer => appColorScheme.primaryContainer;
  Color get appOnPrimaryContainer => appColorScheme.onPrimaryContainer;
  Color get appPrimarySoft => appColorScheme.primaryContainer;
  Color get appOnPrimarySoft => appColorScheme.onPrimaryContainer;
  Color get appSecondary => appColorScheme.secondary;
  Color get appAccentAi => appColorScheme.tertiary;
  Color get appBorder => appColorScheme.outline;
  Color get appDivider => appColorScheme.outlineVariant;

  /// Ground for full-bleed brand moments (splash, blocking loaders).
  Color get appBrandStage =>
      appIsDark ? AppColors.darkBrandStage : AppColors.loadingBackground;

  /// Top-to-bottom stops of the auth header gradient.
  List<Color> get appAuthHeaderGradient => appIsDark
      ? const [AppColors.authHeaderTopDark, AppColors.authHeaderBottomDark]
      : const [AppColors.authHeaderTopLight, AppColors.authHeaderBottomLight];

  /// Neutral triad for states that carry no semantic tone.
  AppSemanticTriad get appNeutralTriad => AppSemanticTriad(
    background: appSurfaceVariant,
    border: appBorder,
    foreground: appTextSecondary,
  );

  AppSemanticTriad get appSuccessTriad => appIsDark
      ? const AppSemanticTriad(
          background: AppColors.successBgDark,
          border: AppColors.successBorderDark,
          foreground: AppColors.successFgDark,
        )
      : const AppSemanticTriad(
          background: AppColors.successBgLight,
          border: AppColors.successBorderLight,
          foreground: AppColors.successFgLight,
        );

  AppSemanticTriad get appWarningTriad => appIsDark
      ? const AppSemanticTriad(
          background: AppColors.warningBgDark,
          border: AppColors.warningBorderDark,
          foreground: AppColors.warningFgDark,
        )
      : const AppSemanticTriad(
          background: AppColors.warningBgLight,
          border: AppColors.warningBorderLight,
          foreground: AppColors.warningFgLight,
          text: AppColors.warningTextLight,
        );

  AppSemanticTriad get appErrorTriad => appIsDark
      ? const AppSemanticTriad(
          background: AppColors.errorBgDark,
          border: AppColors.errorBorderDark,
          foreground: AppColors.errorFgDark,
        )
      : const AppSemanticTriad(
          background: AppColors.errorBgLight,
          border: AppColors.errorBorderLight,
          foreground: AppColors.errorFgLight,
          text: AppColors.errorTextLight,
        );

  AppSemanticTriad get appInfoTriad => appIsDark
      ? const AppSemanticTriad(
          background: AppColors.infoBgDark,
          border: AppColors.infoBorderDark,
          foreground: AppColors.infoFgDark,
        )
      : const AppSemanticTriad(
          background: AppColors.infoBgLight,
          border: AppColors.infoBorderLight,
          foreground: AppColors.infoFgLight,
          text: AppColors.infoTextLight,
        );

  /// Brand triad: primarySoft ground, hairline, forest/emerald foreground.
  AppSemanticTriad get appBrandTriad => AppSemanticTriad(
    background: appPrimarySoft,
    border: appIsDark ? AppColors.successBorderDark : AppColors.successBorderLight,
    foreground: appOnPrimarySoft,
  );

  Color get appSuccessText => appSuccessTriad.text;
  Color get appWarningText => appWarningTriad.text;
  Color get appErrorText => appErrorTriad.text;
  Color get appInfoText => appInfoTriad.text;

  Color get appSuccess => appSuccessTriad.foreground;
  Color get appSuccessContainer => appSuccessTriad.background;
  Color get appSuccessBorder => appSuccessTriad.border;
  Color get appWarning => appWarningTriad.foreground;
  Color get appWarningContainer => appWarningTriad.background;
  Color get appWarningBorder => appWarningTriad.border;
  Color get appError => appColorScheme.error;
  Color get appErrorContainer => appErrorTriad.background;
  Color get appErrorBorder => appErrorTriad.border;
  Color get appInfo => appInfoTriad.foreground;
  Color get appInfoContainer => appInfoTriad.background;
  Color get appInfoBorder => appInfoTriad.border;

  Color get appShadow => appIsDark
      ? Colors.black.withValues(alpha: 0.32)
      : const Color(0xFF0B110E).withValues(alpha: 0.06);

  /// Selected segment of a sliding segmented control over [appSurfaceVariant].
  Color get appSegmentThumb =>
      appIsDark ? AppColors.darkSegmentThumb : appSurface;

  /// Base and highlight for shimmer skeletons on regular surfaces.
  Color get appSkeletonBase => appSurfaceVariant;
  Color get appSkeletonHighlight => appIsDark
      ? const Color(0xFF2A3B32)
      : const Color(0xFFF4F6F4);

  Color get appOverlayText => AppColors.onBrand;
  Color get appOverlayTextSecondary => AppColors.onBrandSecondary;
}
