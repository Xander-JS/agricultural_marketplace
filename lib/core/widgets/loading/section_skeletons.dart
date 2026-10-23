import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import 'app_skeleton.dart';

/// Shape of the content a [SectionSkeleton] stands in for.
enum SectionSkeletonKind {
  /// Catalog card: photo, title, chips and the stock / price row.
  cropCards,

  /// Compact row card: leading squircle, two text lines, trailing figure.
  rowCards,

  /// Profile header, metric tiles and a grouped settings list.
  profile,
}

/// Shimmering silhouette shown the instant a bottom-bar section starts
/// loading.
///
/// Every block sits at the real size of the content it replaces, so the
/// layout does not jump when data lands. Card frames stay outside the
/// shimmer: only the placeholder blocks sweep, the surfaces stay put.
class SectionSkeleton extends StatelessWidget {
  final SectionSkeletonKind kind;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const SectionSkeleton({
    super.key,
    required this.kind,
    this.itemCount = 3,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final children = switch (kind) {
      SectionSkeletonKind.cropCards => [
        for (var i = 0; i < itemCount; i++) ...[
          const _CropCardSkeleton(),
          const SizedBox(height: AppDimensions.space16),
        ],
      ],
      SectionSkeletonKind.rowCards => [
        for (var i = 0; i < itemCount; i++) ...[
          const _RowCardSkeleton(),
          const SizedBox(height: AppDimensions.space12),
        ],
      ],
      SectionSkeletonKind.profile => const [_ProfileSkeleton()],
    };

    return Semantics(
      label: l10n?.loading_skeleton_semantics,
      liveRegion: true,
      // A non-scrolling single-child viewport sizes to its content inside
      // slivers and clips cleanly when a screen is shorter than the
      // silhouette.
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _SkeletonFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _SkeletonFrame({
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.appBorder),
      ),
      child: child,
    );
  }
}

class _CropCardSkeleton extends StatelessWidget {
  const _CropCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return _SkeletonFrame(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AppSkeletonBlock(height: 156, radius: 0),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBlock(width: 180, height: 16),
                    SizedBox(height: AppDimensions.space8),
                    AppSkeletonBlock(width: 96, height: 12),
                    SizedBox(height: AppDimensions.space12),
                    Row(
                      children: [
                        AppSkeletonBlock(
                          width: 112,
                          height: 24,
                          radius: AppDimensions.radiusFull,
                        ),
                        SizedBox(width: AppDimensions.space8),
                        AppSkeletonBlock(
                          width: 64,
                          height: 24,
                          radius: AppDimensions.radiusFull,
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppSkeletonBlock(width: 84, height: 30),
                        AppSkeletonBlock(width: 104, height: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowCardSkeleton extends StatelessWidget {
  const _RowCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonFrame(
      child: AppShimmer(
        child: Row(
          children: [
            AppSkeletonBlock(width: 44, height: 44, radius: 12),
            SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBlock(width: 160, height: 14),
                  SizedBox(height: AppDimensions.space8),
                  AppSkeletonBlock(width: 108, height: 11),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.space12),
            AppSkeletonBlock(width: 72, height: 18),
          ],
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget tile() => const Expanded(
      child: _SkeletonFrame(
        radius: 16,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: AppShimmer(
          child: Column(
            children: [
              AppSkeletonBlock(width: 28, height: 20),
              SizedBox(height: AppDimensions.space8),
              AppSkeletonBlock(width: 56, height: 10),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        const SizedBox(height: AppDimensions.space8),
        const AppShimmer(
          child: Column(
            children: [
              AppSkeletonBlock.circle(size: 88),
              SizedBox(height: AppDimensions.space16),
              AppSkeletonBlock(width: 168, height: 18),
              SizedBox(height: AppDimensions.space8),
              AppSkeletonBlock(width: 112, height: 12),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space32),
        Row(
          children: [
            tile(),
            const SizedBox(width: AppDimensions.space12),
            tile(),
            const SizedBox(width: AppDimensions.space12),
            tile(),
          ],
        ),
        const SizedBox(height: AppDimensions.space24),
        const _SkeletonFrame(
          child: AppShimmer(
            child: Column(
              children: [
                _ProfileRowBlock(),
                SizedBox(height: AppDimensions.space20),
                _ProfileRowBlock(),
                SizedBox(height: AppDimensions.space20),
                _ProfileRowBlock(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileRowBlock extends StatelessWidget {
  const _ProfileRowBlock();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppSkeletonBlock(width: 28, height: 28, radius: 8),
        SizedBox(width: AppDimensions.space12),
        Expanded(child: AppSkeletonBlock(height: 12)),
        SizedBox(width: AppDimensions.space48),
      ],
    );
  }
}
