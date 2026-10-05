import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileIcon;
  final VoidCallback? onBackPressed;
  final Widget? trailingIcon;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showProfileIcon = true,
    this.onBackPressed,
    this.trailingIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.lightTextPrimary,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (trailingIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: trailingIcon,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
