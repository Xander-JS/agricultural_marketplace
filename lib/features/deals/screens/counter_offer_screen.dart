import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../services/negotiation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/constants/delivery_methods.dart';
import '../../../core/utils/app_formatters.dart';

class CounterOfferScreen extends StatefulWidget {
  final NegotiationModel negotiation;
  final NegotiationOfferModel latestOffer;
  final String? role;
  final NegotiationService? service;

  const CounterOfferScreen({
    super.key,
    required this.negotiation,
    required this.latestOffer,
    this.role,
    this.service,
  });

  @override
  State<CounterOfferScreen> createState() => _CounterOfferScreenState();
}

class _CounterOfferScreenState extends State<CounterOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final NegotiationService _service;

  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _messageController;

  String _deliveryMethod = DeliveryMethod.uiOptions.first;
  final List<String> _deliveryOptions = DeliveryMethod.uiOptions;

  bool _isLoading = false;

  bool get _isBuyer {
    if (widget.role != null) {
      return UserRole.isBuyerRole(widget.role);
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return widget.negotiation.buyerId == user.id;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NegotiationService();

    _quantityController = TextEditingController(
      text: UnitFormatters.formatCleanValue(
        widget.latestOffer.quantityKg,
        useLocaleSeparators: false,
      ),
    );
    _priceController = TextEditingController(
      text: UnitFormatters.formatCleanValue(
        widget.latestOffer.proposedPricePerKg,
        useLocaleSeparators: false,
      ),
    );
    _messageController = TextEditingController();

    if (_deliveryOptions.contains(widget.latestOffer.deliveryMethod)) {
      _deliveryMethod = widget.latestOffer.deliveryMethod;
    } else {
      _deliveryMethod = DeliveryMethod.toLabel(widget.latestOffer.deliveryMethod);
      if (!_deliveryOptions.contains(_deliveryMethod)) {
        _deliveryMethod = _deliveryOptions.first;
      }
    }
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
    if (_isLoading) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nextResponder = _isBuyer
          ? UserRole.agricultor.toDbValue()
          : UserRole.comprador.toDbValue();

      await _service.counterOffer(
        negotiationId: widget.negotiation.id,
        quantityKg: _currentQuantity,
        proposedPricePerKg: _currentPrice,
        deliveryMethod: _deliveryMethod,
        message: _messageController.text.trim(),
        nextResponder: nextResponder,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.counter_offer_success),
            backgroundColor: context.appSuccess,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: context.appError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(l10n.counter_offer_title),
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
                    Text(
                      l10n.counter_offer_subtitle_crop(
                        widget.negotiation.crop?.title ??
                            l10n.deals_unknown_crop,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: l10n.counter_offer_quantity_label,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: l10n.counter_offer_price_label,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _deliveryMethod,
                      decoration: InputDecoration(
                        labelText: l10n.counter_offer_delivery_label,
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
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: l10n.counter_offer_message_label,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: l10n.counter_offer_message_hint,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Subtotal Estimado
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
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        foregroundColor: context.appOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        l10n.counter_offer_send_btn,
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
