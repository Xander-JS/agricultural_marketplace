import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../../ai_assistant/models/voice_crop_draft.dart';
import '../../geo/services/geo_simulation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/feedback/app_empty_state.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
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
    _existingImageUrls = List<String>.from(
      widget.cropToEdit?.imageUrls ?? const [],
    );

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
    _priceController.text = UnitFormatters.formatCleanValue(
      crop.pricePerKg,
      useLocaleSeparators: false,
    );
    _stockController.text = UnitFormatters.formatCleanValue(
      crop.stockTotal,
      useLocaleSeparators: false,
    );
    _minOrderController.text = UnitFormatters.formatCleanValue(
      crop.minOrderKg,
      useLocaleSeparators: false,
    );
    _departmentController.text = crop.department;
    _municipalityController.text = crop.municipality;

    _isEarlySale = crop.isEarlySale;
    if (crop.estimatedYieldKg != null) {
      _estimatedYieldController.text = UnitFormatters.formatCleanValue(
        crop.estimatedYieldKg,
        useLocaleSeparators: false,
      );
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
      initialDate:
          _estimatedHarvestDate ?? DateTime.now().add(const Duration(days: 30)),
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

    if (_isEarlySale &&
        _estimatedHarvestDate == null &&
        targetStatus == CropStatus.activa) {
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
        estimatedYieldKg:
            _isEarlySale && _estimatedYieldController.text.isNotEmpty
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
    final title = widget.cropToEdit == null
        ? l10n.publish_title_new
        : l10n.publish_title_edit;

    if (widget.role != null && !UserRole.isFarmerRole(widget.role)) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(title: Text(title)),
        body: AppEmptyState(
          icon: Icons.gpp_bad_outlined,
          title: l10n.publish_unauthorized_title,
          message: l10n.publish_unauthorized_desc,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 12))
          : SingleChildScrollView(
              physics: AppMotion.scrollPhysics,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_voiceDraft != null && widget.cropToEdit == null) ...[
                      _buildVoiceDraftBanner(_voiceDraft!),
                      const SizedBox(height: AppDimensions.space24),
                    ],
                    _buildSection(
                      icon: LucideIcons.fileText,
                      title: l10n.publish_section_general,
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: l10n.publish_field_title,
                          validator: (val) => val == null || val.isEmpty
                              ? l10n.publish_validation_required
                              : null,
                        ),
                        _buildTextField(
                          controller: _cropTypeController,
                          label: l10n.publish_field_crop_type,
                          validator: (val) => val == null || val.isEmpty
                              ? l10n.publish_validation_required
                              : null,
                        ),
                        _buildTextField(
                          controller: _descriptionController,
                          label: l10n.publish_field_description,
                          maxLines: 3,
                          validator: (val) => val == null || val.isEmpty
                              ? l10n.publish_validation_required
                              : null,
                        ),
                      ],
                    ),
                    _buildSection(
                      icon: LucideIcons.coins,
                      title: l10n.publish_section_prices,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: l10n.publish_field_price,
                                keyboardType: TextInputType.number,
                                figures: true,
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
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              child: _buildTextField(
                                controller: _stockController,
                                label: l10n.publish_field_stock,
                                keyboardType: TextInputType.number,
                                figures: true,
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
                        _buildTextField(
                          controller: _minOrderController,
                          label: l10n.publish_field_min_order,
                          keyboardType: TextInputType.number,
                          figures: true,
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
                      ],
                    ),
                    _buildSection(
                      icon: LucideIcons.mapPin,
                      title: l10n.publish_section_location,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: AppDimensions.space12),
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
                      ],
                    ),
                    _buildSection(
                      icon: LucideIcons.calendarClock,
                      title: l10n.publish_section_sale_mode,
                      children: [
                        _buildEarlySaleSwitch(l10n),
                        if (_isEarlySale)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _estimatedYieldController,
                                  label: l10n.publish_field_estimated_yield,
                                  keyboardType: TextInputType.number,
                                  figures: true,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(child: _buildHarvestDateField(l10n)),
                            ],
                          ),
                      ],
                    ),
                    _buildSection(
                      icon: LucideIcons.imagePlus,
                      title: l10n.publish_section_images,
                      children: [
                        if (_existingImageUrls.isNotEmpty) ...[
                          Text(
                            l10n.publish_current_images,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: context.appTextSecondary,
                            ),
                          ),
                          _buildExistingImages(),
                        ],
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(LucideIcons.camera, size: 18),
                          label: Text(l10n.publish_add_images),
                        ),
                        if (_selectedImages.isNotEmpty) _buildSelectedImages(),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _saveCrop(CropStatus.borrador),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                AppDimensions.buttonHeightPrimary,
                              ),
                            ),
                            child: Text(l10n.publish_save_draft),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _saveCrop(CropStatus.activa),
                            child: Text(l10n.publish_submit),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// One form group: an icon-led heading above an inset card whose fields
  /// are spaced evenly.
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: AppDimensions.space8,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: context.appPrimary),
                const SizedBox(width: AppDimensions.space8),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          InsetGroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppDimensions.space12),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarlySaleSwitch(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.publish_early_sale_title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.publish_early_sale_desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.space12),
        Switch.adaptive(
          value: _isEarlySale,
          activeTrackColor: context.appPrimary,
          onChanged: (val) {
            setState(() {
              _isEarlySale = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHarvestDateField(AppLocalizations l10n) {
    final hasDate = _estimatedHarvestDate != null;
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: AppDimensions.borderRadiusControl,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.publish_field_harvest_date,
          suffixIcon: const Icon(LucideIcons.calendar, size: 18),
        ),
        child: Text(
          hasDate
              ? DateFormatters.formatHarvestDate(_estimatedHarvestDate)
              : l10n.publish_select_date,
          style: AppTextStyles.bodyMedium.copyWith(
            color: hasDate ? context.appTextPrimary : context.appTextSecondary,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
      ),
    );
  }

  Widget _buildExistingImages() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        key: const Key('existing_images_list'),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 6, right: 6),
        itemCount: _existingImageUrls.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.space12),
        itemBuilder: (context, index) {
          final path = _existingImageUrls[index];
          final url = _cropService.getPublicImageUrl(path);
          return _ImageThumb(
            image: Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
                color: context.appSurfaceVariant,
                child: Icon(
                  LucideIcons.imageOff,
                  size: 22,
                  color: context.appTextMuted,
                ),
              ),
            ),
            removeKey: Key('remove_existing_image_$index'),
            onRemove: () {
              setState(() {
                _existingImageUrls.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedImages() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 6, right: 6),
        itemCount: _selectedImages.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.space12),
        itemBuilder: (context, index) {
          return _ImageThumb(
            image: Image.file(
              _selectedImages[index],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            onRemove: () {
              setState(() {
                _selectedImages.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildVoiceDraftBanner(VoiceCropDraft draft) {
    final l10n = AppLocalizations.of(context)!;
    final info = context.appInfoTriad;
    final missing = <String>[
      ...draft.missingFields.map((field) => field.label),
      l10n.publish_voice_label_title,
      l10n.publish_voice_label_description,
      l10n.publish_voice_label_location,
    ];

    return Container(
      key: const Key('voice_draft_banner'),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(InsetGroupCard.radius),
        border: Border.all(color: info.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconSquircle(
                icon: LucideIcons.sparkles,
                triad: AppSemanticTriad(
                  background: context.appSurface,
                  border: info.border,
                  foreground: info.foreground,
                ),
                size: 32,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  l10n.publish_voice_banner_title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            l10n.publish_voice_banner_desc,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
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
            const SizedBox(height: AppDimensions.space8),
            Text(
              l10n.publish_voice_confirm(
                draft.reviewFields.map((field) => field.label).join(', '),
              ),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appWarningText,
              ),
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space4),
            Text(
              l10n.publish_voice_missing(missing.join(', ')),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appErrorText,
              ),
            ),
          ],
          if (draft.warnings.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space8),
            ...draft.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.info,
                        size: 14,
                        color: info.foreground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
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
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodyMedium.copyWith(
          color: context.appTextPrimary,
          fontFeatures: AppTextStyles.tabularFigures,
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
    bool figures = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      style: (figures ? AppTextStyles.figureSmall : AppTextStyles.bodyLarge)
          .copyWith(color: context.appTextPrimary),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

/// Rounded photo thumbnail with a remove control on its corner.
class _ImageThumb extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;
  final Key? removeKey;

  const _ImageThumb({
    required this.image,
    required this.onRemove,
    this.removeKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            key: removeKey,
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.appError,
                shape: BoxShape.circle,
                border: Border.all(color: context.appSurface, width: 2),
              ),
              child: Icon(
                LucideIcons.x,
                size: 12,
                color: context.appColorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
