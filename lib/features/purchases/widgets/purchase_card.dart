import 'package:flutter/material.dart';
import '../../deals/models/negotiation_model.dart';
import '../../deals/models/negotiation_status.dart';
import '../../deals/screens/deal_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/app_formatters.dart';

class PurchaseCard extends StatelessWidget {
  final NegotiationModel purchase;
  final VoidCallback? onRefresh;

  const PurchaseCard({
    super.key,
    required this.purchase,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Obtener la última oferta acordada
    final latestOffer = (purchase.offers != null && purchase.offers!.isNotEmpty)
        ? purchase.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final quantity = latestOffer?.quantityKg ?? 0.0;
    final price = latestOffer?.proposedPricePerKg ?? 0.0;
    final total = quantity * price;

    final producerName = purchase.farmerProfile?['full_name'] ??
        (purchase.crop?.municipality != null
            ? l10n.purchase_card_producer_municipality(
                purchase.crop!.municipality,
              )
            : l10n.purchase_card_producer_local);

    final location = purchase.crop != null && purchase.crop!.municipality.isNotEmpty
        ? '${purchase.crop!.municipality}, ${purchase.crop!.department}'
        : null;

    final formattedDate = DateFormatters.formatMediumDate(purchase.updatedAt);

    final isAgreed = purchase.status == NegotiationStatus.acordada;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.appBorder),
      ),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Título del cultivo y Badge de Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.crop?.title ?? l10n.purchase_card_agreed_crop,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (purchase.crop?.cropType != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            purchase.crop!.cropType,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context, isAgreed, l10n),
                ],
              ),

              const SizedBox(height: 12),

              // Información del Productor
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: context.appPrimaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: context.appPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      producerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.appTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (location != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: context.appTextDisabled,
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appTextDisabled,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),

              // Contenedor de detalles del acuerdo: Cantidad, Precio y Total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.appSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricColumn(
                      context,
                      label: l10n.purchase_card_quantity,
                      value: UnitFormatters.formatKg(quantity),
                                          ),
                    _buildMetricColumn(
                      context,
                      label: l10n.purchase_card_price_per_kg,
                      value: CurrencyFormatters.formatCop(price),
                                          ),
                    _buildMetricColumn(
                      context,
                      label: l10n.purchase_card_total_agreed,
                      value: CurrencyFormatters.formatCop(total),
                                            isHighlighted: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Entrega y Fecha
              Row(
                children: [
                  if (latestOffer != null && latestOffer.deliveryMethod.isNotEmpty) ...[
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 15,
                      color: context.appPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.purchases_delivery_method}: ${latestOffer.deliveryMethod}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: context.appTextDisabled,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appTextDisabled,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Enlace al detalle del acuerdo
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.purchases_view_detail,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    bool isAgreed,
    AppLocalizations l10n,
  ) {
    final label = isAgreed
        ? l10n.purchases_status_agreed
        : l10n.purchases_status_completed;

    final color = isAgreed ? context.appSuccess : context.appInfo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.appTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? context.appPrimary
                : context.appTextPrimary,
          ),
        ),
      ],
    );
  }
}
