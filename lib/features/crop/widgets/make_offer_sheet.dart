import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_icons.dart';

import '../models/crop_model.dart';
import '../../deals/services/negotiation_service.dart';
import '../../deals/widgets/delivery_presentation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../core/widgets/feedback/status_banner.dart';
import '../../../core/widgets/inputs/choice_tile.dart';
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
        showAppSnackBar(
          context,
          l10n.offer_sheet_success,
          tone: StatusTone.success,
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

  Widget _deliveryTile(AppLocalizations l10n, String method) {
    final presentation = deliveryPresentation(l10n, method);
    return ChoiceTile(
      icon: presentation.icon,
      label: presentation.label,
      selected: _deliveryMethod == method,
      onTap: () {
        if (_deliveryMethod == method) return;
        HapticFeedback.selectionClick();
        setState(() => _deliveryMethod = method);
      },
    );
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
                  Expanded(child: _deliveryTile(l10n, _deliveryOptions[i])),
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
