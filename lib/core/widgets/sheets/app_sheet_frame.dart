import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// iOS floating sheet anatomy shared by the commerce and assistant sheets.
///
/// 28px top corners, frosted `surface` material (blur under a 94% surface
/// fill, so text contrast never depends on what sits behind), a 1px
/// hairline and a 36x5 drag handle. Open it with
/// `showModalBottomSheet(showDragHandle: false, backgroundColor:
/// AppColors.transparent)` so the theme's own handle is not drawn twice.
///
/// When [footer] is given, [body] scrolls and the footer stays pinned
/// above the keyboard and the home indicator.
class AppSheetFrame extends StatelessWidget {
  final Widget body;
  final Widget? footer;
  final EdgeInsetsGeometry bodyPadding;

  const AppSheetFrame({
    super.key,
    required this.body,
    this.footer,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
  });

  static const double handleWidth = 36;
  static const double handleHeight = 5;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    const radius = BorderRadius.vertical(
      top: Radius.circular(AppDimensions.radiusSheet),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92 - keyboard,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appSurface.withValues(alpha: 0.94),
                borderRadius: radius,
                border: Border.all(
                  color: context.appBorder,
                  width: AppDimensions.borderWidthThin,
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: keyboard == 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _DragHandle(),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: bodyPadding,
                        child: body,
                      ),
                    ),
                    if (footer != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: context.appDivider),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: footer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Center(
        child: Container(
          width: AppSheetFrame.handleWidth,
          height: AppSheetFrame.handleHeight,
          decoration: BoxDecoration(
            color: context.appTextMuted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSheetFrame.handleHeight),
          ),
        ),
      ),
    );
  }
}
