import 'package:flutter/material.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';

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
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineMedium.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      actions: [
        if (trailingIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space16),
            child: trailingIcon,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
