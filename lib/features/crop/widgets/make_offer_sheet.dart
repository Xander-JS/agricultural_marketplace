import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../../deals/services/negotiation_service.dart';
import '../../../core/theme/app_colors.dart';
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
        ? UnitFormatters.formatCleanValue(widget.crop.minOrderKg, useLocaleSeparators: false)
        : '1';
    _quantityController = TextEditingController(text: initialQty);
    _priceController = TextEditingController(
      text: UnitFormatters.formatCleanValue(widget.crop.pricePerKg, useLocaleSeparators: false),
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
          SnackBar(
            content: Text(message),
            backgroundColor: context.appError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.appDivider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Text(
                  l10n.offer_sheet_title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.crop.title} — ${widget.crop.cropType}',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Stock & base price reminder
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.offer_sheet_base_price(
                          CurrencyFormatters.formatPricePerKg(widget.crop.pricePerKg),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.appPrimary,
                        ),
                      ),
                      Text(
                        l10n.offer_sheet_min_stock(
                          UnitFormatters.formatKg(widget.crop.minOrderKg),
                          UnitFormatters.formatKg(widget.crop.availableStock),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cantidad
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.offer_sheet_quantity_label,
                    suffixText: 'kg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(height: 14),

                // Precio propuesto por kg
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.offer_sheet_price_label,
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(height: 14),

                // Método de entrega
                DropdownButtonFormField<String>(
                  initialValue: _deliveryMethod,
                  decoration: InputDecoration(
                    labelText: l10n.offer_sheet_delivery_label,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _deliveryOptions.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _deliveryMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Mensaje opcional
                TextFormField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.offer_sheet_message_label,
                    hintText: l10n.offer_sheet_message_hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Subtotal Estimado Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.offer_sheet_estimated_total,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatters.formatCop(_estimatedTotal),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.appPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Enviar
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appPrimary,
                    foregroundColor: context.appOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.appOnPrimary,
                          ),
                        )
                      : Text(
                          l10n.offer_sheet_submit_btn,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
