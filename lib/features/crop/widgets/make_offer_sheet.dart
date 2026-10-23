import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/crop_model.dart';
import '../../deals/services/negotiation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/misc/pressable_scale.dart';
import '../../../core/widgets/sheets/app_sheet_frame.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/delivery_methods.dart';
import '../../../core/utils/app_formatters.dart';

class MakeOfferSheet extends StatefulWidget {
  final CropModel crop;
  final NegotiationService? negotiationService;

  const MakeOfferSheet({
    super.key,
    required this.crop,
    this.negotiationService,
  });

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  final _formKey = GlobalKey<FormState>();
  late final NegotiationService _service;

  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _messageController;

  String _deliveryMethod = DeliveryMethod.uiOptions.first;
  final List<String> _deliveryOptions = DeliveryMethod.uiOptions;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.negotiationService ?? NegotiationService();

    final initialQty = widget.crop.minOrderKg > 0
        ? UnitFormatters.formatCleanValue(
            widget.crop.minOrderKg,
            useLocaleSeparators: false,
          )
        : '1';
    _quantityController = TextEditingController(text: initialQty);
    _priceController = TextEditingController(
      text: UnitFormatters.formatCleanValue(
        widget.crop.pricePerKg,
        useLocaleSeparators: false,
      ),
    );
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  double get _currentQuantity {
    return double.tryParse(_quantityController.text.trim()) ?? 0.0;
  }

  double get _currentPrice {
    return double.tryParse(_priceController.text.trim()) ?? 0.0;
  }

  double get _estimatedTotal {
    return _currentQuantity * _currentPrice;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _service.createNegotiation(
        cropId: widget.crop.id,
        quantityKg: _currentQuantity,
        proposedPricePerKg: _currentPrice,
        deliveryMethod: _deliveryMethod,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.offer_sheet_success),
            backgroundColor: context.appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: context.appError),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  ({IconData icon, String label}) _deliveryPresentation(
    AppLocalizations l10n,
    String method,
  ) {
    return switch (DeliveryMethod.fromString(method)) {
      DeliveryMethod.enFinca => (
        icon: LucideIcons.tractor,
        label: l10n.offer_sheet_delivery_farm,
      ),
      DeliveryMethod.puntoAcordado => (
        icon: LucideIcons.mapPinned,
        label: l10n.offer_sheet_delivery_point,
      ),
      DeliveryMethod.transportadora => (
        icon: LucideIcons.truck,
        label: l10n.offer_sheet_delivery_carrier,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final figureStyle = AppTextStyles.figureSmall.copyWith(
      fontSize: 16,
      color: context.appTextPrimary,
    );

    return Form(
      key: _formKey,
      child: AppSheetFrame(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.offer_sheet_title,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 22,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.crop.title} — ${widget.crop.cropType}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Terms of the lot the offer has to respect.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.appSurfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _LotTerm(
                        label: l10n.crop_card_price_per_kg,
                        value: CurrencyFormatters.formatCop(
                          widget.crop.pricePerKg,
                        ),
                        emphasized: true,
                      ),
                    ),
                    VerticalDivider(width: 20, color: context.appBorder),
                    Expanded(
                      child: _LotTerm(
                        label: l10n.offer_sheet_min_order,
                        value: UnitFormatters.formatKg(widget.crop.minOrderKg),
                      ),
                    ),
                    VerticalDivider(width: 20, color: context.appBorder),
                    Expanded(
                      child: _LotTerm(
                        label: l10n.offer_sheet_available_stock,
                        value: UnitFormatters.formatKg(
                          widget.crop.availableStock,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: figureStyle,
                    decoration: InputDecoration(
                      labelText: l10n.offer_sheet_quantity_label,
                      suffixText: 'kg',
                      prefixIcon: const Icon(LucideIcons.weight, size: 18),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.offer_sheet_val_required;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return l10n.offer_sheet_val_positive;
                      }
                      if (parsed < widget.crop.minOrderKg) {
                        return l10n.offer_sheet_val_min_order;
                      }
                      if (parsed > widget.crop.availableStock) {
                        return l10n.offer_sheet_val_max_stock;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: figureStyle,
                    decoration: InputDecoration(
                      labelText: l10n.offer_sheet_price_label,
                      prefixText: '\$ ',
                      suffixText: '/ kg',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.offer_sheet_val_required;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return l10n.offer_sheet_val_positive;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space20),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.offer_sheet_delivery_label,
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < _deliveryOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: _DeliveryOption(
                      presentation: _deliveryPresentation(
                        l10n,
                        _deliveryOptions[i],
                      ),
                      selected: _deliveryMethod == _deliveryOptions[i],
                      onTap: () {
                        if (_deliveryMethod == _deliveryOptions[i]) return;
                        HapticFeedback.selectionClick();
                        setState(() => _deliveryMethod = _deliveryOptions[i]);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppDimensions.space20),

            TextFormField(
              controller: _messageController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.offer_sheet_message_label,
                hintText: l10n.offer_sheet_message_hint,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.offer_sheet_estimated_total,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.offer_sheet_total_breakdown(
                          UnitFormatters.formatKg(_currentQuantity),
                          CurrencyFormatters.formatCop(_currentPrice),
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: context.appTextSecondary,
                          fontFeatures: AppTextStyles.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Text(
                  CurrencyFormatters.formatCop(_estimatedTotal),
                  style: AppTextStyles.figureLarge.copyWith(
                    fontSize: 24,
                    color: context.appPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? CupertinoActivityIndicator(color: context.appTextMuted)
                  : Text(l10n.offer_sheet_submit_btn),
            ),
          ],
        ),
      ),
    );
  }
}

/// One delivery method in a three-way selector: icon over a short label,
/// filled with the brand soft tone when chosen.
class _DeliveryOption extends StatelessWidget {
  final ({IconData icon, String label}) presentation;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.presentation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final triad = context.appBrandTriad;
    final duration = AppMotion.of(context, AppMotion.standard);
    final foreground = selected ? triad.foreground : context.appTextSecondary;

    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.easeOut,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? triad.background : context.appSurfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? triad.border : AppColors.transparent,
                width: AppDimensions.borderWidthMedium,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(presentation.icon, size: 20, color: foreground),
                const SizedBox(height: 6),
                Text(
                  presentation.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: selected ? triad.foreground : context.appTextPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One term of the lot the offer must respect: a small label over its
/// figure.
class _LotTerm extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _LotTerm({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTextStyles.figureSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasized ? context.appPrimary : context.appTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
