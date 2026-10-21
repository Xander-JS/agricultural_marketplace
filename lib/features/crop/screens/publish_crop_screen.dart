import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../../ai_assistant/models/voice_crop_draft.dart';
import '../../geo/services/geo_simulation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/constants/user_roles.dart';

class PublishCropScreen extends StatefulWidget {
  final CropModel? cropToEdit;
  final CropService? cropService;
  final String? currentUserIdForTesting;
  final VoiceCropDraft? initialDraft;
  final String? role;

  const PublishCropScreen({
    super.key,
    this.cropToEdit,
    this.cropService,
    this.currentUserIdForTesting,
    this.initialDraft,
    this.role,
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
  VoiceCropDraft? _voiceDraft;

  @override
  void initState() {
    super.initState();
    _minOrderController.text = '1';
    _existingImageUrls = List<String>.from(widget.cropToEdit?.imageUrls ?? const []);

    if (widget.cropToEdit != null) {
      // La edición de un cultivo existente siempre tiene prioridad sobre un
      // borrador de voz, para no alterar el flujo de edición.
      _loadCropData(widget.cropToEdit!);
    } else {
      _departmentController.text = 'Nariño';
      if (widget.initialDraft != null) {
        _voiceDraft = widget.initialDraft;
        _applyVoiceDraft(widget.initialDraft!);
      }
    }
  }

  void _applyVoiceDraft(VoiceCropDraft draft) {
    if (draft.cropType != null) {
      _cropTypeController.text = draft.cropType!;
    }
    if (draft.pricePerKg != null) {
      _priceController.text = UnitFormatters.formatCleanValue(
        draft.pricePerKg,
        useLocaleSeparators: false,
      );
    }
    if (draft.quantityKg != null) {
      _stockController.text = UnitFormatters.formatCleanValue(
        draft.quantityKg,
        useLocaleSeparators: false,
      );
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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.publish_validation_incomplete)),
      );
      return;
    }

    if (_isEarlySale && _estimatedHarvestDate == null && targetStatus == CropStatus.activa) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.publish_harvest_date_required)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = widget.currentUserIdForTesting ?? user?.id;
      if (userId == null) throw Exception(l10n.publish_not_authenticated);

      if (widget.role != null && !UserRole.isFarmerRole(widget.role)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.publish_access_farmer_only),
            backgroundColor: context.appError,
          ),
        );
        return;
      }

      if (widget.cropToEdit != null &&
          widget.cropToEdit!.farmerId.isNotEmpty &&
          widget.cropToEdit!.farmerId != userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.publish_access_other_crop),
            backgroundColor: context.appError,
          ),
        );
        return;
      }

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
            content: Text(
              targetStatus == CropStatus.activa
                  ? l10n.publish_success_active
                  : l10n.publish_success_draft,
            ),
            backgroundColor: context.appSuccess,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.publish_save_error(e.toString())),
            backgroundColor: context.appError,
          ),
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
    final l10n = AppLocalizations.of(context)!;

    if (widget.role != null && !UserRole.isFarmerRole(widget.role)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.cropToEdit == null
                ? l10n.publish_title_new
                : l10n.publish_title_edit,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad_outlined, size: 72, color: context.appError),
                const SizedBox(height: 16),
                Text(
                  l10n.publish_unauthorized_title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.publish_unauthorized_desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appTextSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          widget.cropToEdit == null
              ? l10n.publish_title_new
              : l10n.publish_title_edit,
        ),
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
                    if (_voiceDraft != null && widget.cropToEdit == null) ...[
                      _buildVoiceDraftBanner(_voiceDraft!),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle(l10n.publish_section_general),
                    _buildTextField(
                      controller: _titleController,
                      label: l10n.publish_field_title,
                      validator: (val) => val == null || val.isEmpty
                          ? l10n.publish_validation_required
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cropTypeController,
                      label: l10n.publish_field_crop_type,
                      validator: (val) => val == null || val.isEmpty
                          ? l10n.publish_validation_required
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: l10n.publish_field_description,
                      maxLines: 3,
                      validator: (val) => val == null || val.isEmpty
                          ? l10n.publish_validation_required
                          : null,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(l10n.publish_section_prices),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: l10n.publish_field_price,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return l10n.publish_validation_required;
                              }
                              final num = double.tryParse(val);
                              if (num == null || num <= 0) {
                                return l10n.publish_validation_greater_zero;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            label: l10n.publish_field_stock,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return l10n.publish_validation_required;
                              }
                              final num = double.tryParse(val);
                              if (num == null || num < 0) {
                                return l10n.publish_validation_non_negative;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _minOrderController,
                      label: l10n.publish_field_min_order,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return l10n.publish_validation_required;
                        }
                        final num = double.tryParse(val);
                        if (num == null || num <= 0) {
                          return l10n.publish_validation_greater_zero;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(l10n.publish_section_location),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _departmentController,
                            label: l10n.publish_field_department,
                            validator: (val) => val == null || val.isEmpty
                                ? l10n.publish_validation_required
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _municipalityController,
                            label: l10n.publish_field_municipality,
                            validator: (val) => val == null || val.isEmpty
                                ? l10n.publish_validation_required
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(l10n.publish_section_sale_mode),
                    SwitchListTile(
                      title: Text(l10n.publish_early_sale_title),
                      subtitle: Text(l10n.publish_early_sale_desc),
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
                              label: l10n.publish_field_estimated_yield,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: l10n.publish_field_harvest_date,
                                  border: const OutlineInputBorder(),
                                ),
                                child: Text(
                                  _estimatedHarvestDate != null
                                      ? DateFormatters.formatHarvestDate(_estimatedHarvestDate)
                                      : l10n.publish_select_date,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionTitle(l10n.publish_section_images),
                    if (_existingImageUrls.isNotEmpty) ...[
                      Text(
                        l10n.publish_current_images,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                                      color: context.appSurfaceVariant,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 24,
                                        color: context.appTextDisabled,
                                      ),
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
                                      decoration: BoxDecoration(
                                        color: context.appError,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: context.appOnPrimary,
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
                      label: Text(l10n.publish_add_images),
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
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: context.appError,
                                    ),
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
                            child: Text(l10n.publish_save_draft),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _saveCrop(CropStatus.activa),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appPrimary,
                              foregroundColor: context.appOnPrimary,
                            ),
                            child: Text(l10n.publish_submit),
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

  Widget _buildVoiceDraftBanner(VoiceCropDraft draft) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final missing = <String>[
      ...draft.missingFields.map((field) => field.label),
      l10n.publish_voice_label_title,
      l10n.publish_voice_label_description,
      l10n.publish_voice_label_location,
    ];

    return Container(
      key: const Key('voice_draft_banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.publish_voice_banner_title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.publish_voice_banner_desc),
          const SizedBox(height: 10),
          if (draft.cropType != null)
            _buildVoiceDraftLine(l10n.ai_crop, draft.cropType!),
          if (draft.quantityDescription != null)
            _buildVoiceDraftLine(l10n.ai_quantity, draft.quantityDescription!),
          if (draft.pricePerKg != null)
            _buildVoiceDraftLine(
              l10n.ai_price,
              CurrencyFormatters.formatPricePerKg(draft.pricePerKg),
            ),
          if (draft.reviewFields.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.publish_voice_confirm(
                draft.reviewFields.map((field) => field.label).join(', '),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.publish_voice_missing(missing.join(', ')),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (draft.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...draft.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(warning)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceDraftLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
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
        fillColor: context.appSurfaceVariant,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
