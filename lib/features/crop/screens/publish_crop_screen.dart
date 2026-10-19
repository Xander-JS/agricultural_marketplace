import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../../geo/services/geo_simulation_service.dart';
import '../../../core/utils/app_formatters.dart';

class PublishCropScreen extends StatefulWidget {
  final CropModel? cropToEdit;
  final CropService? cropService;
  final String? currentUserIdForTesting;

  const PublishCropScreen({
    super.key,
    this.cropToEdit,
    this.cropService,
    this.currentUserIdForTesting,
  });

  @override
  State<PublishCropScreen> createState() => _PublishCropScreenState();
}

class _PublishCropScreenState extends State<PublishCropScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CropService _cropService = widget.cropService ?? CropService();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isEarlySale = false;

  // Controladores
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _departmentController = TextEditingController();
  final _municipalityController = TextEditingController();
  
  // Venta anticipada
  final _estimatedYieldController = TextEditingController();
  DateTime? _estimatedHarvestDate;

  final List<File> _selectedImages = [];
  late List<String> _existingImageUrls;

  @override
  void initState() {
    super.initState();
    _minOrderController.text = '1';
    _existingImageUrls = List<String>.from(widget.cropToEdit?.imageUrls ?? const []);
    
    if (widget.cropToEdit != null) {
      _loadCropData(widget.cropToEdit!);
    } else {
      _departmentController.text = 'Nariño';
    }
  }

  void _loadCropData(CropModel crop) {
    _titleController.text = crop.title;
    _descriptionController.text = crop.description;
    _cropTypeController.text = crop.cropType;
    _priceController.text = UnitFormatters.formatCleanValue(crop.pricePerKg, useLocaleSeparators: false);
    _stockController.text = UnitFormatters.formatCleanValue(crop.stockTotal, useLocaleSeparators: false);
    _minOrderController.text = UnitFormatters.formatCleanValue(crop.minOrderKg, useLocaleSeparators: false);
    _departmentController.text = crop.department;
    _municipalityController.text = crop.municipality;
    
    _isEarlySale = crop.isEarlySale;
    if (crop.estimatedYieldKg != null) {
      _estimatedYieldController.text = UnitFormatters.formatCleanValue(crop.estimatedYieldKg, useLocaleSeparators: false);
    }
    _estimatedHarvestDate = crop.estimatedHarvestDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cropTypeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minOrderController.dispose();
    _departmentController.dispose();
    _municipalityController.dispose();
    _estimatedYieldController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedHarvestDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _estimatedHarvestDate) {
      setState(() {
        _estimatedHarvestDate = picked;
      });
    }
  }

  Future<void> _saveCrop(CropStatus targetStatus) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa los campos obligatorios correctamente.')),
      );
      return;
    }

    if (_isEarlySale && _estimatedHarvestDate == null && targetStatus == CropStatus.activa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes indicar la fecha estimada de cosecha para venta anticipada.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = widget.currentUserIdForTesting ?? user?.id;
      if (userId == null) throw Exception('No autenticado');

      final originalImages = widget.cropToEdit?.imageUrls ?? const [];
      final removedImages = originalImages
          .where((path) => !_existingImageUrls.contains(path))
          .toList();

      // Preservar coordenadas existentes al editar o asignar simulación determinista para nuevo
      double? lat = widget.cropToEdit?.latitude;
      double? lon = widget.cropToEdit?.longitude;

      if (lat == null || lon == null) {
        final cropLocation = GeoSimulationService.assignSimulatedLocation(
          seed: 'crop_${userId}_${_titleController.text.trim()}',
          municipality: _municipalityController.text.trim(),
          department: _departmentController.text.trim(),
        );
        lat = cropLocation.latitude;
        lon = cropLocation.longitude;
      }

      final newCrop = CropModel(
        id: widget.cropToEdit?.id ?? '',
        farmerId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cropType: _cropTypeController.text.trim(),
        pricePerKg: double.parse(_priceController.text.trim()),
        stockTotal: double.tryParse(_stockController.text.trim()) ?? 0,
        minOrderKg: double.tryParse(_minOrderController.text.trim()) ?? 1,
        department: _departmentController.text.trim(),
        municipality: _municipalityController.text.trim(),
        latitude: lat,
        longitude: lon,
        isEarlySale: _isEarlySale,
        estimatedYieldKg: _isEarlySale && _estimatedYieldController.text.isNotEmpty 
            ? double.tryParse(_estimatedYieldController.text.trim()) 
            : null,
        estimatedHarvestDate: _isEarlySale ? _estimatedHarvestDate : null,
        status: targetStatus,
        createdAt: widget.cropToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: _existingImageUrls,
      );

      await _cropService.saveCrop(
        newCrop,
        newImages: _selectedImages.isNotEmpty ? _selectedImages : null,
        removedImages: removedImages.isNotEmpty ? removedImages : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetStatus == CropStatus.activa 
                ? '¡Cosecha publicada exitosamente!' 
                : 'Borrador guardado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cropToEdit == null ? 'Publicar Cosecha' : 'Editar Cosecha'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('1. Información General'),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Título de la publicación',
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cropTypeController,
                      label: 'Tipo de Producto (Ej: Papa Capira, Café Castillo)',
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Descripción de la cosecha',
                      maxLines: 3,
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('2. Precios y Cantidades'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Precio por kg (\$)',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Requerido';
                              final num = double.tryParse(val);
                              if (num == null || num <= 0) return 'Mayor a 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            label: 'Total Disp. (kg)',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Requerido';
                              final num = double.tryParse(val);
                              if (num == null || num < 0) return 'Mayor o igual a 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _minOrderController,
                      label: 'Pedido mínimo (kg)',
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) return 'Mayor a 0';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('3. Ubicación'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _departmentController,
                            label: 'Departamento',
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _municipalityController,
                            label: 'Municipio',
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('4. Modalidad de Venta'),
                    SwitchListTile(
                      title: const Text('¿Es Venta Anticipada?'),
                      subtitle: const Text('Útil si la cosecha aún no está lista pero quieres asegurar ventas.'),
                      value: _isEarlySale,
                      onChanged: (val) {
                        setState(() {
                          _isEarlySale = val;
                        });
                      },
                    ),
                    if (_isEarlySale) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _estimatedYieldController,
                              label: 'Rendimiento est. (kg)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha de Cosecha',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _estimatedHarvestDate != null
                                      ? DateFormatters.formatHarvestDate(_estimatedHarvestDate)
                                      : 'Seleccionar...',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionTitle('5. Imágenes'),
                    if (_existingImageUrls.isNotEmpty) ...[
                      const Text(
                        'Imágenes actuales de la publicación:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          key: const Key('existing_images_list'),
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final path = _existingImageUrls[index];
                            final url = _cropService.getPublicImageUrl(path);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported_outlined, size: 24),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    key: Key('remove_existing_image_$index'),
                                    onTap: () {
                                      setState(() {
                                        _existingImageUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Añadir Imágenes'),
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.file(_selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _saveCrop(CropStatus.borrador),
                            child: const Text('Guardar Borrador'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _saveCrop(CropStatus.activa),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Publicar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
