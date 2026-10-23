import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../brand/kus_brand_logo.dart';

/// iOS navigation bar for pushed flow screens.
///
/// Tinted back chevron, centered title on the grouped ground, and the KUS
/// mark on the right when the screen supplies no trailing action.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileIcon;
  final VoidCallback? onBackPressed;
  final Widget? trailingIcon;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showProfileIcon = true,
    this.onBackPressed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppBar(
      backgroundColor: context.appBackground,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: l10n?.common_back,
        icon: Icon(
          LucideIcons.chevronLeft,
          size: 26,
          color: context.appPrimary,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headlineMedium.copyWith(
          fontSize: 17,
          color: context.appTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.space16),
          child: Center(
            child:
                trailingIcon ?? const KusBrandLogo.compact(showWordmark: false),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
