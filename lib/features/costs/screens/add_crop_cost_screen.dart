import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../widgets/cost_category_style.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/unit_formatters.dart';
import '../models/crop_cost_model.dart';
import '../services/crop_cost_calculator.dart';
import '../services/crop_cost_service.dart';

class AddCropCostScreen extends StatefulWidget {
  final String cropId;
  final CropCostModel? costToEdit;
  final CropCostService? costService;

  const AddCropCostScreen({
    super.key,
    required this.cropId,
    this.costToEdit,
    this.costService,
  });

  @override
  State<AddCropCostScreen> createState() => _AddCropCostScreenState();
}

class _AddCropCostScreenState extends State<AddCropCostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CropCostService _costService;

  late CostCategory _selectedCategory;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _costService = widget.costService ?? CropCostService();
    _selectedCategory = widget.costToEdit?.category ?? CostCategory.jornales;
    _descriptionController = TextEditingController(
      text: widget.costToEdit?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.costToEdit != null
          ? UnitFormatters.formatCleanValue(
              widget.costToEdit!.amount,
              useLocaleSeparators: false,
            )
          : '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveCost() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final amount = CropCostCalculator.parseAmount(_amountController.text);
      if (amount == null) {
        _formKey.currentState?.validate();
        return;
      }

      final cost = CropCostModel(
        id: widget.costToEdit?.id ?? '',
        cropId: widget.cropId,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        amount: amount,
        createdAt: widget.costToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.costToEdit == null) {
        await _costService.createCost(cost);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.costs_added)));
        }
      } else {
        await _costService.updateCost(cost);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.costs_updated)));
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.costs_save_error(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.costToEdit != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(isEditing ? l10n.costs_edit_title : l10n.costs_add_title),
      ),
      body: _isSaving
          ? const Center(child: CupertinoActivityIndicator(radius: 12))
          : SingleChildScrollView(
              physics: AppMotion.scrollPhysics,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel(l10n.costs_category),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppDimensions.space8;
                        final width = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final category in CostCategory.values)
                              SizedBox(
                                width: width,
                                child: _CategoryTile(
                                  category: category,
                                  selected: category == _selectedCategory,
                                  onTap: () {
                                    if (category == _selectedCategory) return;
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    _buildLabel(l10n.costs_description),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: l10n.costs_description_hint,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.costs_description_required;
                        }
                        return null;
                      },
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    _buildLabel(l10n.costs_value),
                    TextFormField(
                      controller: _amountController,
                      style: AppTextStyles.figureMedium.copyWith(
                        color: context.appTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.costs_value_hint,
                        prefixText: '\$ ',
                        suffixText: 'COP',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.costs_value_required;
                        }
                        if (CropCostCalculator.parseAmount(value) == null) {
                          return l10n.costs_value_invalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.space40),
                    ElevatedButton.icon(
                      onPressed: _saveCost,
                      icon: Icon(
                        isEditing ? LucideIcons.check : LucideIcons.plus,
                        size: 18,
                      ),
                      label: Text(
                        isEditing ? l10n.costs_update : l10n.costs_save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.space8),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

/// Selectable expense category: a neutral editorial squircle and its name.
/// Every category shares one selected state — a brand-green hairline over
/// a faint brand wash — so the grid reads as a single control.
class _CategoryTile extends StatelessWidget {
  final CostCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.appPrimary;

    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.standard),
            curve: AppMotion.easeOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? Color.alphaBlend(
                      primary.withValues(
                        alpha: context.appIsDark ? 0.12 : 0.06,
                      ),
                      context.appSurface,
                    )
                  : context.appSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? primary : context.appBorder,
                width: selected
                    ? AppDimensions.borderWidthMedium
                    : AppDimensions.borderWidthThin,
              ),
            ),
            child: Row(
              children: [
                IconSquircle(icon: category.icon, size: 36),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Text(
                    category.toDisplayName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.circleCheck, size: 18, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
