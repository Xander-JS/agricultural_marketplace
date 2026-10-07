import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/crop_cost_model.dart';
import '../services/crop_cost_service.dart';

class AddCropCostScreen extends StatefulWidget {
  final String cropId;
  final CropCostModel? costToEdit;

  const AddCropCostScreen({
    super.key,
    required this.cropId,
    this.costToEdit,
  });

  @override
  State<AddCropCostScreen> createState() => _AddCropCostScreenState();
}

class _AddCropCostScreenState extends State<AddCropCostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costService = CropCostService();

  late CostCategory _selectedCategory;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.costToEdit?.category ?? CostCategory.jornales;
    _descriptionController = TextEditingController(text: widget.costToEdit?.description ?? '');
    _amountController = TextEditingController(
      text: widget.costToEdit != null ? widget.costToEdit!.amount.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveCost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.parse(amountStr);

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
            const SnackBar(content: Text('Costo agregado exitosamente')),
          );
        }
      } else {
        await _costService.updateCost(cost);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Costo actualizado exitosamente')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Costo' : 'Agregar Costo'),
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
                    const Text(
                      'Categoría',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    const Text(
                      'Descripción',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Mano de obra para recolección',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa una descripción';
                        }
                        return null;
                      },
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Valor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un valor';
                        }
                        final numValue = double.tryParse(value);
                        if (numValue == null || numValue <= 0) {
                          return 'El valor debe ser mayor a 0';
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
                        isEditing ? 'Actualizar costo' : 'Guardar costo',
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
