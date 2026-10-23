import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../models/crop_cost_model.dart';

/// Icon and tint for each expense category, shared by the cost list and
/// the add / edit form so a category reads the same everywhere.
extension CostCategoryStyle on CostCategory {
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
}
