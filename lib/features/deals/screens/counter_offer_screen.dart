import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../services/negotiation_service.dart';
import '../widgets/delivery_presentation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/constants/delivery_methods.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/cards/inset_group_card.dart';
import '../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../core/widgets/feedback/status_banner.dart';
import '../../../core/widgets/inputs/choice_tile.dart';
import '../../../core/constants/input_limits.dart';
import '../../../core/widgets/inputs/field_pair.dart';

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
      _deliveryMethod = DeliveryMethod.toLabel(
        widget.latestOffer.deliveryMethod,
      );
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
        showAppSnackBar(
          context,
          l10n.counter_offer_success,
          tone: StatusTone.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          tone: StatusTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePositive(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.offer_sheet_val_required;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return l10n.offer_sheet_val_positive;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final figureStyle = AppTextStyles.figureSmall.copyWith(
      fontSize: 16,
      color: context.appTextPrimary,
    );
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(l10n.counter_offer_title)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: AppMotion.scrollPhysics,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.counter_offer_subtitle_crop(
                        widget.negotiation.crop?.title ??
                            l10n.deals_unknown_crop,
                      ),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    _CurrentOfferCard(offer: widget.latestOffer),
                    const SizedBox(height: AppDimensions.space24),

                    FieldPair(
                      first: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: InputLimits.decimal(
                          InputLimits.kgDigits,
                        ),
                        style: figureStyle,
                        decoration: InputDecoration(
                          labelText: l10n.counter_offer_quantity_label,
                          suffixText: 'kg',
                          prefixIcon: const Icon(LucideIcons.weight, size: 18),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) => _validatePositive(value, l10n),
                      ),
                      second: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: InputLimits.decimal(
                          InputLimits.pricePerKgDigits,
                        ),
                        style: figureStyle,
                        decoration: InputDecoration(
                          labelText: l10n.counter_offer_price_label,
                          prefixText: '\$ ',
                          suffixText: '/ kg',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) => _validatePositive(value, l10n),
                      ),
                    ),
                    _buildPriceDelta(l10n),
                    const SizedBox(height: AppDimensions.space20),

                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        l10n.counter_offer_delivery_label,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _deliveryOptions.length; i++) ...[
                          if (i > 0)
                            const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _deliveryTile(l10n, _deliveryOptions[i]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space20),

                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      maxLength: InputLimits.message,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.counter_offer_message_label,
                        hintText: l10n.counter_offer_message_hint,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(l10n),
          ],
        ),
      ),
    );
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

  /// How far the counter-offer moves the price per kg from the offer on
  /// the table; hidden while the price is unchanged or not a number.
  Widget _buildPriceDelta(AppLocalizations l10n) {
    final diff = _currentPrice - widget.latestOffer.proposedPricePerKg;
    final show = _currentPrice > 0 && diff != 0;
    final sign = diff > 0 ? '+' : '−';

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.easeOut,
      alignment: Alignment.topCenter,
      child: show
          ? Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Row(
                children: [
                  Icon(
                    diff > 0
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    size: 14,
                    color: context.appTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.counter_offer_vs_current(
                        '$sign${CurrencyFormatters.formatCop(diff.abs())} / kg',
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.appTextSecondary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  /// Total of the counter-offer and its send button, kept above the
  /// keyboard and the home indicator.
  Widget _buildFooter(AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appDivider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
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
                          // Wraps like the offer sheet; the figures stay whole.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? CupertinoActivityIndicator(color: context.appTextMuted)
                    : Text(l10n.counter_offer_send_btn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The offer on the table that this counter-offer answers.
class _CurrentOfferCard extends StatelessWidget {
  final NegotiationOfferModel offer;

  const _CurrentOfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final delivery = deliveryPresentation(l10n, offer.deliveryMethod);

    Widget figure(String label, String value, {bool emphasized = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.figureMedium.copyWith(
              fontSize: 16,
              color: emphasized ? context.appPrimary : context.appTextPrimary,
            ),
          ),
        ],
      );
    }

    return InsetGroupCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.receipt,
                size: 16,
                color: context.appTextSecondary,
              ),
              const SizedBox(width: AppDimensions.space8),
              Text(
                l10n.counter_offer_current_offer,
                style: AppTextStyles.titleSmall.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                DateFormatters.formatOfferDateTime(offer.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: context.appTextSecondary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: figure(
                    l10n.deal_detail_price_per_kg,
                    CurrencyFormatters.formatCop(offer.proposedPricePerKg),
                    emphasized: true,
                  ),
                ),
                VerticalDivider(width: 24, color: context.appDivider),
                Expanded(
                  child: figure(
                    l10n.deal_detail_quantity,
                    UnitFormatters.formatKg(offer.quantityKg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          Divider(height: 1, thickness: 1, color: context.appDivider),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(delivery.icon, size: 16, color: context.appTextSecondary),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  deliveryDisplayLabel(l10n, offer.deliveryMethod),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13,
                    color: context.appTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
