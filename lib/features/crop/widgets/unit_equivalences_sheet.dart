import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';

/// Modal informativo de equivalencias aproximadas de unidades agrícolas.
///
/// Diseñado para compradores en el detalle de cultivo.
/// Es estrictamente informativo: no modifica inventario, precios, pedidos ni la base de datos.
class UnitEquivalencesSheet extends StatefulWidget {
  final double? referenceKg;
  final String cropTitle;

  const UnitEquivalencesSheet({
    super.key,
    required this.referenceKg,
    required this.cropTitle,
  });

  @override
  State<UnitEquivalencesSheet> createState() => _UnitEquivalencesSheetState();
}

class _UnitEquivalencesSheetState extends State<UnitEquivalencesSheet> {
  late final TextEditingController _calculatorController;
  late double _currentKg;

  @override
  void initState() {
    super.initState();
    _currentKg = _sanitizeKg(widget.referenceKg);
    _calculatorController = TextEditingController(
      text: _currentKg > 0
          ? UnitFormatters.formatCleanValue(_currentKg, useLocaleSeparators: false)
          : '0',
    );
  }

  @override
  void dispose() {
    _calculatorController.dispose();
    super.dispose();
  }

  static double _sanitizeKg(num? value) {
    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return 0.0;
    }
    return value.toDouble();
  }

  void _onInputChanged(String text) {
    final parsed = double.tryParse(text.replaceAll(',', '.').trim());
    setState(() {
      _currentKg = _sanitizeKg(parsed);
    });
  }

  String _formatEquivalence(double qtyKg, TraditionalUnit unit) {
    if (qtyKg <= 0 || unit.kgEquivalent <= 0) {
      return '0 ${unit.pluralName}';
    }
    final converted = qtyKg / unit.kgEquivalent;
    final formatted = UnitFormatters.formatCleanValue(converted, maxDecimals: 1);
    final label = (converted == 1.0) ? unit.displayName : unit.pluralName;
    return '≈ $formatted $label';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final initialKgFormatted = UnitFormatters.formatKg(widget.referenceKg);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador superior de arrastre
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cabecera con título e icono
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.balance_outlined,
                      color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Unit Equivalences' : 'Equivalencias de Unidades',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (widget.cropTitle.isNotEmpty)
                          Text(
                            widget.cropTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: isEn ? 'Close' : 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tarjeta de cantidad de referencia disponible
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Reference quantity (available)' : 'Cantidad de referencia (disponible)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          initialKgFormatted,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.inventory_2_outlined,
                      color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo interactivo para calcular otra cantidad en kg
              TextFormField(
                key: const Key('unit_equivalences_input'),
                controller: _calculatorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onInputChanged,
                decoration: InputDecoration(
                  labelText: isEn ? 'Calculate quantity (kg)' : 'Consultar otra cantidad (kg)',
                  hintText: 'Ej. 500',
                  suffixText: 'kg',
                  prefixIcon: const Icon(Icons.calculate_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de unidades tradicionales
              Text(
                isEn ? 'Approximate traditional equivalents' : 'Equivalencias tradicionales aproximadas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),

              ...TraditionalUnit.values.map((unit) {
                final equivalenceText = _formatEquivalence(_currentKg, unit);
                final rateText = '1 ${unit.displayName} = ${UnitFormatters.formatKg(unit.kgEquivalent)}';

                return Container(
                  key: Key('unit_equivalence_${unit.name}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.displayName[0].toUpperCase() + unit.displayName.substring(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            rateText,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextDisabled
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        equivalenceText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Nota de advertencia / disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEn
                            ? 'Approximate conversions for informational purposes only. They do not modify inventory, prices, or orders.'
                            : 'Conversiones aproximadas de carácter exclusivamente informativo. No modifican el inventario, los precios ni los pedidos.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botón de cierre
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('crop_detail_equivalences_close_button'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isEn ? 'Close' : 'Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
