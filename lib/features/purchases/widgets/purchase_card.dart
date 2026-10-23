import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';

import '../../deals/models/negotiation_model.dart';
import '../../deals/models/negotiation_status.dart';
import '../../deals/screens/deal_detail_screen.dart';
import '../../deals/widgets/deal_crop_thumb.dart';
import '../../deals/widgets/delivery_presentation.dart';
import '../../deals/widgets/negotiation_status_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/misc/pressable_scale.dart';

/// One purchase agreed with a farmer: the lot, who sells it, the figures
/// of the agreement and how it will be delivered.
class PurchaseCard extends StatelessWidget {
  final NegotiationModel purchase;
  final VoidCallback? onRefresh;

  const PurchaseCard({super.key, required this.purchase, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Obtener la última oferta acordada
    final latestOffer = (purchase.offers != null && purchase.offers!.isNotEmpty)
        ? purchase.offers!.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
          )
        : null;

    final quantity = latestOffer?.quantityKg ?? 0.0;
    final price = latestOffer?.proposedPricePerKg ?? 0.0;
    final total = quantity * price;

    final producerName =
        purchase.farmerProfile?['full_name'] ??
        (purchase.crop?.municipality != null
            ? l10n.purchase_card_producer_municipality(
                purchase.crop!.municipality,
              )
            : l10n.purchase_card_producer_local);

    final location =
        purchase.crop != null && purchase.crop!.municipality.isNotEmpty
        ? '${purchase.crop!.municipality}, ${purchase.crop!.department}'
        : null;

    final formattedDate = DateFormatters.formatMediumDate(purchase.updatedAt);

    final isAgreed = purchase.status == NegotiationStatus.acordada;

    return PressableScale(
      pressedScale: 0.985,
      child: Material(
        color: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.appBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DealDetailScreen(
                  negotiationId: purchase.id,
                  role: 'comprador',
                ),
              ),
            );
            if (result == true) {
              onRefresh?.call();
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado: cosecha, tipo y estado
                Row(
                  children: [
                    DealCropThumb(crop: purchase.crop, size: 48),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            purchase.crop?.title ??
                                l10n.purchase_card_agreed_crop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                          if (purchase.crop?.cropType != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              purchase.crop!.cropType,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 13,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space12),

                // Productor y procedencia
                Row(
                  children: [
                    Icon(
                      LucideIcons.userRound,
                      size: 15,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        producerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    if (location != null) ...[
                      const SizedBox(width: AppDimensions.space12),
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: context.appTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppDimensions.space12),

                // Precio, cantidad y total del acuerdo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _Figure(
                            label: l10n.purchase_card_price_per_kg,
                            value: CurrencyFormatters.formatCop(price),
                          ),
                        ),
                        VerticalDivider(width: 20, color: context.appBorder),
                        Expanded(
                          flex: 3,
                          child: _Figure(
                            label: l10n.purchase_card_quantity,
                            value: UnitFormatters.formatKg(quantity),
                          ),
                        ),
                        VerticalDivider(width: 20, color: context.appBorder),
                        Expanded(
                          flex: 5,
                          child: _Figure(
                            label: l10n.purchase_card_total_agreed,
                            value: CurrencyFormatters.formatCop(total),
                            emphasized: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space12),

                // Entrega y fecha
                Row(
                  children: [
                    if (latestOffer != null &&
                        latestOffer.deliveryMethod.isNotEmpty) ...[
                      Icon(
                        deliveryPresentation(
                          l10n,
                          latestOffer.deliveryMethod,
                        ).icon,
                        size: 15,
                        color: context.appTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.purchases_delivery_method}: ${deliveryDisplayLabel(l10n, latestOffer.deliveryMethod)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(width: AppDimensions.space8),
                    Text(
                      formattedDate,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appTextSecondary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space12),
                Divider(height: 1, thickness: 1, color: context.appDivider),
                const SizedBox(height: 10),

                // Estado del acuerdo y enlace al detalle
                Row(
                  children: [
                    NegotiationStatusBadge(
                      status: purchase.status,
                      label: isAgreed
                          ? l10n.purchases_status_agreed
                          : l10n.purchases_status_completed,
                    ),
                    const Spacer(),
                    const SizedBox(width: AppDimensions.space8),
                    Text(
                      l10n.purchases_view_detail,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A label over its tabular figure inside the agreement strip.
class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _Figure({
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
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
              color: emphasized ? context.appPrimary : context.appTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
