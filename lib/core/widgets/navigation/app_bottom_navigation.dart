import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../theme/app_icons.dart';

import '../../constants/user_roles.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';

/// iOS-style tab bar for the four top-level sections.
///
/// Frosted surface with a 1px top hairline. Tabs adapt to the farmer or
/// buyer role. Selecting a tab tints its icon and label over 200ms and
/// settles the icon in with a small scale, so the change reads without
/// slowing down a control used dozens of times a day.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'agricultor',
  });

  bool get _isBuyer => UserRole.isBuyerRole(role);

  static const double _barHeight = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = <_TabData>[
      _TabData(
        icon: _isBuyer ? LucideIcons.store : LucideIcons.sprout,
        label: _isBuyer ? l10n.nav_my_market : l10n.nav_market,
      ),
      _TabData(icon: LucideIcons.handshake, label: l10n.nav_deals),
      _TabData(
        icon: _isBuyer
            ? LucideIcons.packageCheck
            : LucideIcons.chartNoAxesCombined,
        label: _isBuyer ? l10n.nav_purchases : l10n.nav_costs,
      ),
      _TabData(
        icon: CupertinoIcons.person_crop_circle,
        label: l10n.nav_my_farm,
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurface.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: context.appBorder,
                width: AppDimensions.borderWidthThin,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _TabButton(
                        data: items[i],
                        selected: i == currentIndex,
                        onTap: () {
                          if (i != currentIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onTap(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;

  const _TabData({required this.icon, required this.label});
}

class _TabButton extends StatefulWidget {
  final _TabData data;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(CurvedAnimation(parent: _settle, curve: AppMotion.easeOut));

  @override
  void didUpdateWidget(covariant _TabButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected && !AppMotion.reduced(context)) {
      _settle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = selected ? context.appPrimary : context.appTextSecondary;
    final duration = AppMotion.of(context, AppMotion.standard);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: duration,
          curve: AppMotion.easeOut,
          builder: (context, tint, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Icon(widget.data.icon, size: 24, color: tint),
              ),
              const SizedBox(height: 3),
              Text(
                widget.data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: tint,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
