import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_formatters.dart';

/// Gráfico de Mancuerna (Dumbbell Chart) horizontal estilizado para contrastar
/// el precio de la cosecha frente al índice de referencia regional Nariño.
class RegionalIndexDumbbellChart extends StatelessWidget {
  final double referencePrice;
  final double cropPrice;

  const RegionalIndexDumbbellChart({
    super.key,
    required this.referencePrice,
    required this.cropPrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = cropPrice - referencePrice;
    final diffPercent = referencePrice > 0 ? (diff / referencePrice) * 100 : 0.0;
    final sign = diff > 0 ? '+' : (diff < 0 ? '-' : '');

    final String diffFormatted;
    if (diff == 0) {
      diffFormatted = l10n.crop_detail_regional_at_par;
    } else {
      final formattedCop = CurrencyFormatters.formatCop(diff.abs());
      final percentVal = diffPercent.abs();
      final percentFormatted = percentVal.truncateToDouble() == percentVal
          ? percentVal.toStringAsFixed(0)
          : percentVal.toStringAsFixed(1);
      diffFormatted = '$sign$formattedCop/kg ($sign$percentFormatted%)';
    }

    final isHigher = diff > 0;
    final badgeBg = isHigher
        ? AppColors.lightPrimarySoft
        : (diff < 0 ? context.appSurfaceVariant : context.appSurfaceVariant);
    final badgeColor = isHigher
        ? AppColors.primary
        : (diff < 0 ? context.appTextSecondary : context.appTextPrimary);
    final badgeBorder = isHigher
        ? AppColors.primary.withValues(alpha: 0.25)
        : context.appBorder;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: context.appBorder, width: AppDimensions.borderWidthThin),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conector y Diferencia central destacada
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                diffFormatted,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          // Gráfico de Mancuerna: Línea conector y nodos circulares
          SizedBox(
            height: 24,
            child: CustomPaint(
              painter: _DumbbellPainter(
                surfaceColor: context.appSurface,
                trackColor: context.appDivider,
                nodeAColor: const Color(0xFF64748B), // Gris pizarra / neutro
                nodeBColor: AppColors.primary,       // Verde institucional
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          // Etiquetas y Valores de los puntos A y B
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Punto A: Referencia Regional Nariño
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.crop_detail_point_reference,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatters.formatCop(referencePrice)} / kg',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              // Punto B: Precio de la Cosecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.crop_detail_point_crop,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatters.formatCop(cropPrice)} / kg',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFeatures: AppTextStyles.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          // Micro-etiqueta sobria de atribución formal
          Text(
            l10n.profitability_reference_notice,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: context.appTextSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  final Color surfaceColor;
  final Color trackColor;
  final Color nodeAColor;
  final Color nodeBColor;

  const _DumbbellPainter({
    required this.surfaceColor,
    required this.trackColor,
    required this.nodeAColor,
    required this.nodeBColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const nodeRadiusA = 7.0;
    const nodeRadiusB = 8.5;
    final centerY = size.height / 2;
    final startX = nodeRadiusB + 4;
    final endX = size.width - (nodeRadiusB + 4);

    // 1. Línea horizontal estilizada que conecta ambos puntos
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      trackPaint,
    );

    // Segmento activo con gradiente neutro -> verde institucional
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [nodeAColor.withValues(alpha: 0.5), nodeBColor],
      ).createShader(Rect.fromPoints(Offset(startX, centerY), Offset(endX, centerY)))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      activePaint,
    );

    // 2. Punto A (Referencia Regional Nariño): Gris pizarra / neutro
    final borderPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintA = Paint()
      ..color = nodeAColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(startX, centerY), nodeRadiusA, paintA);
    canvas.drawCircle(Offset(startX, centerY), nodeRadiusA, borderPaint);

    // 3. Punto B (Precio de la Cosecha): Verde institucional
    final paintB = Paint()
      ..color = nodeBColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(endX, centerY), nodeRadiusB, paintB);
    canvas.drawCircle(Offset(endX, centerY), nodeRadiusB, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DumbbellPainter oldDelegate) {
    return oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.nodeAColor != nodeAColor ||
        oldDelegate.nodeBColor != nodeBColor;
  }
}
