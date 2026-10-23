import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../misc/app_entrance.dart';

/// Size presets for [KusBrandLogo].
enum KusBrandLogoVariant {
  /// Navigation bars and tight rows: 30px mark, inline wordmark.
  compact,

  /// Auth headers: 44px mark, wordmark plus "KUMPA SUMAQ" tagline.
  header,

  /// Splash and welcome: 88px mark stacked over a large wordmark.
  hero,
}

/// KUS brand lockup: the isotype inside an iOS squircle plus the "KUS"
/// logotype.
///
/// The isotype asset is a white silhouette, tinted here so the mark keeps
/// contrast on light grounds, dark grounds, the topographic header and the
/// full-bleed brand stage ([onBrandStage]).
class KusBrandLogo extends StatelessWidget {
  final KusBrandLogoVariant variant;

  /// Shows the "KUS" logotype next to (or under) the mark.
  final bool showWordmark;

  /// Shows the "KUMPA SUMAQ" tagline. Defaults to on for header and hero.
  final bool? showTagline;

  /// Inverts the lockup for the brand stage (splash, blocking loaders):
  /// light squircle, stage-colored mark, light type.
  final bool onBrandStage;

  /// Plays a one-time entrance (fade + settle). Used on rare brand moments.
  final bool animateEntrance;

  /// Overrides the variant's squircle size (the radius keeps its ratio).
  final double? markSize;

  const KusBrandLogo({
    super.key,
    this.variant = KusBrandLogoVariant.header,
    this.showWordmark = true,
    this.showTagline,
    this.onBrandStage = false,
    this.animateEntrance = false,
    this.markSize,
  });

  const KusBrandLogo.compact({
    super.key,
    this.showWordmark = true,
    this.onBrandStage = false,
  }) : variant = KusBrandLogoVariant.compact,
       showTagline = false,
       animateEntrance = false,
       markSize = null;

  const KusBrandLogo.hero({
    super.key,
    this.showWordmark = true,
    this.showTagline = true,
    this.onBrandStage = false,
    this.animateEntrance = true,
  }) : variant = KusBrandLogoVariant.hero,
       markSize = null;

  _KusLogoMetrics get _metrics => switch (variant) {
    KusBrandLogoVariant.compact => const _KusLogoMetrics(
      mark: 30,
      wordmark: 18,
      tagline: 9,
      gap: 8,
      asset: 'assets/images/app_movil_only_sm.png',
    ),
    KusBrandLogoVariant.header => const _KusLogoMetrics(
      mark: 44,
      wordmark: 24,
      tagline: 9.5,
      gap: 12,
      asset: 'assets/images/app_movil_only_lg.png',
    ),
    KusBrandLogoVariant.hero => const _KusLogoMetrics(
      mark: 88,
      wordmark: 44,
      tagline: 11,
      gap: 20,
      asset: 'assets/images/app_movil_only_xl.png',
    ),
  };

  @override
  Widget build(BuildContext context) {
    // Nullable so the mark still renders in widget trees without
    // localization delegates (isolated component tests).
    final l10n = AppLocalizations.of(context);
    final metrics = _metrics;
    final m = markSize == null ? metrics : metrics.withMark(markSize!);
    final isHero = variant == KusBrandLogoVariant.hero;
    final tagline = showTagline ?? variant != KusBrandLogoVariant.compact;

    final Color tile;
    final Color markColor;
    final Color tileBorder;
    final Color wordColor;
    final Color taglineColor;
    if (onBrandStage) {
      tile = AppColors.onBrand;
      markColor = context.appBrandStage;
      tileBorder = AppColors.transparent;
      wordColor = AppColors.onBrand;
      taglineColor = AppColors.onBrandSecondary;
    } else {
      tile = context.appPrimary;
      markColor = context.appOnPrimary;
      tileBorder = context.appOnPrimary.withValues(alpha: 0.16);
      wordColor = context.appTextPrimary;
      taglineColor = context.appTextSecondary;
    }

    // The 14px radius is specified at the 44px header size; other sizes keep
    // the same proportion so the squircle reads identically at every scale.
    final radius = m.mark * (14 / 44);

    Widget mark = Container(
      width: m.mark,
      height: m.mark,
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tileBorder),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        m.asset,
        height: m.mark * 0.62,
        color: markColor,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) =>
            SizedBox(height: m.mark * 0.62, width: m.mark * 0.56),
      ),
    );

    Widget? words;
    if (showWordmark && l10n != null) {
      words = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isHero
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.brand_name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: m.wordmark,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.0,
              color: wordColor,
            ),
          ),
          if (tagline) ...[
            SizedBox(height: isHero ? 8 : 4),
            Text(
              l10n.brand_tagline,
              style: GoogleFonts.plusJakartaSans(
                fontSize: m.tagline,
                fontWeight: FontWeight.w700,
                letterSpacing: m.tagline * 0.18,
                height: 1.0,
                color: taglineColor,
              ),
            ),
          ],
        ],
      );
    }

    if (animateEntrance) {
      mark = AppEntrance(offsetY: 0, beginScale: 0.92, child: mark);
      if (words != null) {
        words = AppEntrance(
          delay: const Duration(milliseconds: 80),
          child: words,
        );
      }
    }

    final lockup = words == null
        ? mark
        : isHero
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              SizedBox(height: m.gap),
              words,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              SizedBox(width: m.gap),
              words,
            ],
          );

    return Semantics(
      label: l10n?.brand_logo_semantics,
      image: true,
      excludeSemantics: true,
      child: lockup,
    );
  }
}

class _KusLogoMetrics {
  final double mark;

  _KusLogoMetrics withMark(double size) => _KusLogoMetrics(
    mark: size,
    wordmark: wordmark,
    tagline: tagline,
    gap: gap,
    asset: asset,
  );

  final double wordmark;
  final double tagline;
  final double gap;
  final String asset;

  const _KusLogoMetrics({
    required this.mark,
    required this.wordmark,
    required this.tagline,
    required this.gap,
    required this.asset,
  });
}
