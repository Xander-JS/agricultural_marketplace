import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'inset_group_card.dart';

/// iOS inset grouped list section: an optional header above, the rows on
/// one flat `surface` card split by hairlines, and an optional footnote.
///
/// Hairlines start where the row text starts ([dividerIndent]), the way
/// Settings indents them past the leading icon.
class InsetGroupSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final double dividerIndent;

  const InsetGroupSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.dividerIndent = 58,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              0,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            child: Text(
              header!,
              style: AppTextStyles.titleSmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
        Material(
          color: context.appSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(InsetGroupCard.radius),
            side: BorderSide(color: context.appBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: dividerIndent,
                    color: context.appDivider,
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space8,
              AppDimensions.space16,
              0,
            ),
            child: Text(
              footer!,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// One row of an [InsetGroupSection]: leading mark, title with an optional
/// subtitle, and a trailing control or value.
///
/// With [onTap] and no [trailing], the row draws a disclosure chevron.
/// [destructive] rows center their title in the error tone, like
/// "Sign Out" at the end of iOS Settings.
class InsetGroupRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final IconData? destructiveIcon;

  const InsetGroupRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.destructiveIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;

    if (destructive) {
      final color = context.appErrorText;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (destructiveIcon != null) ...[
            Icon(destructiveIcon, size: AppDimensions.iconSM, color: color),
            const SizedBox(width: AppDimensions.space8),
          ],
          Text(title, style: AppTextStyles.titleMedium.copyWith(color: color)),
        ],
      );
    } else {
      final trailingWidget =
          trailing ??
          (onTap != null
              ? Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: context.appTextMuted,
                )
              : null);

      content = Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppDimensions.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.appTextPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: AppDimensions.space12),
            trailingWidget,
          ],
        ],
      );
    }

    final padded = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8 + 2,
        ),
        child: Align(alignment: Alignment.centerLeft, child: content),
      ),
    );

    if (onTap == null) return padded;
    return InkWell(onTap: onTap, child: padded);
  }
}
