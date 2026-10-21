import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.costs_added)),
          );
        }
      } else {
        await _costService.updateCost(cost);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.costs_updated)),
          );
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.costs_category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CostCategory>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: CostCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.toDisplayName()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.costs_description,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: l10n.costs_description_hint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    const SizedBox(height: 24),
                    Text(
                      l10n.costs_value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: l10n.costs_value_hint,
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveCost,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? l10n.costs_update : l10n.costs_save,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
