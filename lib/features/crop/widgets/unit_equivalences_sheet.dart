import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/sheets/app_sheet_frame.dart';
import '../../../core/localization/app_localizations.dart';
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
          ? UnitFormatters.formatCleanValue(
              _currentKg,
              useLocaleSeparators: false,
            )
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

  String _formatEquivalence(
    AppLocalizations l10n,
    double qtyKg,
    TraditionalUnit unit,
  ) {
    if (qtyKg <= 0 || unit.kgEquivalent <= 0) {
      return l10n.units_empty(unit.pluralName);
    }
    final converted = qtyKg / unit.kgEquivalent;
    final formatted = UnitFormatters.formatCleanValue(
      converted,
      maxDecimals: 1,
    );
    final label = (converted == 1.0) ? unit.displayName : unit.pluralName;
    return l10n.units_approx(formatted, label);
  }

  static IconData _iconFor(TraditionalUnit unit) => switch (unit) {
    TraditionalUnit.canastilla => LucideIcons.shoppingBasket,
    TraditionalUnit.bulto => LucideIcons.package,
    TraditionalUnit.caja => LucideIcons.box,
    TraditionalUnit.arroba => LucideIcons.scale,
    TraditionalUnit.tonelada => LucideIcons.truck,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initialKgFormatted = UnitFormatters.formatKg(widget.referenceKg);

    // Field units first, in a 2x2 grid; the ton is a bulk-buyer figure and
    // gets its own full-width row below.
    const gridUnits = [
      TraditionalUnit.canastilla,
      TraditionalUnit.bulto,
      TraditionalUnit.caja,
      TraditionalUnit.arroba,
    ];

    return AppSheetFrame(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconSquircle(
                icon: LucideIcons.scale,
                triad: context.appBrandTriad,
                size: 40,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.units_title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: context.appTextPrimary,
                      ),
                    ),
                    if (widget.cropTitle.isNotEmpty)
                      Text(
                        widget.cropTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: l10n.common_close,
                color: context.appTextSecondary,
                style: IconButton.styleFrom(
                  backgroundColor: context.appSurfaceVariant,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: context.appPrimarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBrandTriad.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.units_reference_quantity,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.appOnPrimarySoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        initialKgFormatted,
                        style: AppTextStyles.figureMedium.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.warehouse,
                  size: 22,
                  color: context.appOnPrimarySoft,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
          TextFormField(
            key: const Key('unit_equivalences_input'),
            controller: _calculatorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onInputChanged,
            style: AppTextStyles.figureSmall.copyWith(
              fontSize: 16,
              color: context.appTextPrimary,
            ),
            decoration: InputDecoration(
              labelText: l10n.units_calculate_quantity,
              hintText: l10n.units_input_hint,
              suffixText: 'kg',
              prefixIcon: const Icon(LucideIcons.calculator, size: 18),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              l10n.units_approximate_equivalents,
              style: AppTextStyles.titleSmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppDimensions.space8;
              final tileWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final unit in gridUnits)
                    SizedBox(
                      width: tileWidth,
                      child: _buildUnitTile(context, l10n, unit),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildUnitTile(
            context,
            l10n,
            TraditionalUnit.tonelada,
            horizontal: true,
          ),
          const SizedBox(height: AppDimensions.space16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  LucideIcons.info,
                  size: 15,
                  color: context.appTextSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.units_kg_baseline_note,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.units_disclaimer,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      footer: FilledButton(
        key: const Key('crop_detail_equivalences_close_button'),
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.units_close),
      ),
    );
  }

  /// One grouped iOS tile: icon, unit name, the large approximate value and
  /// the conversion rate it rests on.
  Widget _buildUnitTile(
    BuildContext context,
    AppLocalizations l10n,
    TraditionalUnit unit, {
    bool horizontal = false,
  }) {
    final equivalenceText = _formatEquivalence(l10n, _currentKg, unit);
    final rateText = l10n.units_equivalence_rate(
      unit.displayName,
      UnitFormatters.formatKg(unit.kgEquivalent),
    );
    final name =
        unit.displayName[0].toUpperCase() + unit.displayName.substring(1);

    final value = Text(
      equivalenceText,
      style: AppTextStyles.figureMedium.copyWith(
        fontSize: horizontal ? 17 : 19,
        fontWeight: FontWeight.w800,
        color: context.appTextPrimary,
      ),
    );
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTextStyles.titleSmall.copyWith(
            color: context.appTextPrimary,
          ),
        ),
        Text(
          rateText,
          style: AppTextStyles.caption.copyWith(
            color: context.appTextSecondary,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
      ],
    );
    final icon = Icon(_iconFor(unit), size: 18, color: context.appPrimary);

    return Container(
      key: Key('unit_equivalence_${unit.name}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: horizontal
          ? Row(
              children: [
                icon,
                const SizedBox(width: AppDimensions.space12),
                Expanded(child: labels),
                const SizedBox(width: AppDimensions.space8),
                value,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: AppDimensions.space12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: value,
                ),
                const SizedBox(height: AppDimensions.space4),
                labels,
              ],
            ),
    );
  }
}
