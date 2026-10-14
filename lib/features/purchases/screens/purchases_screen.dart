import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Pantalla base para el módulo de Compras del rol Comerciante/Comprador.
///
/// Preparada modularmente durante la Etapa 2 de Navegación, lista para albergar
/// la lógica de consulta y seguimiento de compras acordadas en la Etapa 6.
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;

    final titleText = l10n?.purchases_title ?? 'Compras';
    final placeholderTitle = l10n?.purchases_placeholder_title ?? 'Módulo de Compras';
    final placeholderDesc = l10n?.purchases_placeholder_desc ??
        'Aquí podrás consultar tus compras acordadas y el historial de operaciones completadas.';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          titleText,
          style: AppTextStyles.displaySmall.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppDimensions.paddingScreen,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space32,
              ),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: AppDimensions.borderRadiusLG,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: AppDimensions.iconXL,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    placeholderTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    placeholderDesc,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: AppDimensions.space8,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
                          .withValues(alpha: 0.5),
                      borderRadius: AppDimensions.borderRadiusFull,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: AppDimensions.iconXS,
                          color: primaryColor,
                        ),
                        const SizedBox(width: AppDimensions.space4),
                        Text(
                          'Rol Comerciante',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
