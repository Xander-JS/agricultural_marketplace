import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../deals/models/negotiation_model.dart';
import '../../deals/models/negotiation_status.dart';
import '../../deals/screens/deal_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // Obtener la última oferta acordada
    final latestOffer = (purchase.offers != null && purchase.offers!.isNotEmpty)
        ? purchase.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final quantity = latestOffer?.quantityKg ?? 0.0;
    final price = latestOffer?.proposedPricePerKg ?? 0.0;
    final total = quantity * price;

    final producerName = purchase.farmerProfile?['full_name'] ??
        (purchase.crop?.municipality != null
            ? 'Productor (${purchase.crop!.municipality})'
            : 'Productor local');

    final location = purchase.crop != null && purchase.crop!.municipality.isNotEmpty
        ? '${purchase.crop!.municipality}, ${purchase.crop!.department}'
        : null;

    final formatter = DateFormat('dd MMM yyyy', 'es_CO');
    final formattedDate = formatter.format(purchase.updatedAt);

    final isAgreed = purchase.status == NegotiationStatus.acordada;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
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
                          purchase.crop?.title ?? 'Cosecha acordada',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(isAgreed, isDark, l10n),
                ],
              ),

              const SizedBox(height: 12),

              // Información del Productor
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark
                        ? AppColors.darkTertiary.withValues(alpha: 0.2)
                        : AppColors.lightSecondary,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      producerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                      color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
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
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricColumn(
                      label: 'Cantidad',
                      value: '${quantity.toStringAsFixed(0)} kg',
                      isDark: isDark,
                    ),
                    _buildMetricColumn(
                      label: 'Precio / kg',
                      value: currencyFormatter.format(price),
                      isDark: isDark,
                    ),
                    _buildMetricColumn(
                      label: l10n?.purchases_total_invested ?? 'Total pactado',
                      value: currencyFormatter.format(total),
                      isDark: isDark,
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
                      color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n?.purchases_delivery_method ?? "Entrega"}: ${latestOffer.deliveryMethod}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Enlace al detalle del acuerdo
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n?.purchases_view_detail ?? 'Ver detalle del acuerdo →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isAgreed, bool isDark, AppLocalizations? l10n) {
    final label = isAgreed
        ? (l10n?.purchases_status_agreed ?? 'Acordada')
        : (l10n?.purchases_status_completed ?? 'Completada');

    final color = isAgreed
        ? (isDark ? AppColors.darkTertiary : AppColors.success)
        : (isDark ? const Color(0xFF80CBC4) : const Color(0xFF00897B));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
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

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }
}
