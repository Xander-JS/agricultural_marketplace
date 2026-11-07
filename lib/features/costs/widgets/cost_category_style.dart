import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/crop_cost_model.dart';

/// Icon and tint for each expense category, shared by the cost list and
/// the add / edit form so a category reads the same everywhere.
extension CostCategoryStyle on CostCategory {
  String localizedName(AppLocalizations l10n) => switch (this) {
    CostCategory.jornales => l10n.cost_category_labor,
    CostCategory.fertilizantes => l10n.cost_category_fertilizers,
    CostCategory.transporte => l10n.cost_category_transport,
    CostCategory.otros => l10n.cost_category_other,
  };

  IconData get icon => switch (this) {
    CostCategory.jornales => LucideIcons.users,
    CostCategory.fertilizantes => LucideIcons.flaskConical,
    CostCategory.transporte => LucideIcons.truck,
    CostCategory.otros => LucideIcons.receiptText,
  };

  AppSemanticTriad triad(BuildContext context) => switch (this) {
    CostCategory.jornales => context.appInfoTriad,
    CostCategory.fertilizantes => context.appBrandTriad,
    CostCategory.transporte => context.appWarningTriad,
    CostCategory.otros => context.appNeutralTriad,
  };

  /// Outlined variant for the registered-expense rows: no solid background fill,
  /// leaving only a clean, colored outline (1.25px - 1.5px) and matching colored
  /// icon on a transparent / plain surface background.
  AppSemanticTriad outlineTriad(BuildContext context) {
    final Color hue = switch (this) {
      CostCategory.transporte => context.appWarningTriad.foreground,
      CostCategory.fertilizantes => context.appPrimary,
      CostCategory.jornales => context.appInfoTriad.foreground,
      CostCategory.otros => context.appTextSecondary,
    };
    return AppSemanticTriad(
      background: AppColors.transparent,
      border: AppColors.transparent,
      foreground: hue,
    );
  }
}
