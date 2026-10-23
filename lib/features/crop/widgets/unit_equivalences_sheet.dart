import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/misc/icon_squircle.dart';
import '../../../core/widgets/sheets/app_sheet_frame.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/app_formatters.dart';

/// Modal informativo de equivalencias aproximadas de unidades agrícolas,
/// en una cuadrícula compacta de tarjetas.
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
      TraditionalUnit.bulto,
      TraditionalUnit.canastilla,
      TraditionalUnit.caja,
      TraditionalUnit.arroba,
    ];

    return AppSheetFrame(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.units_title,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
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
                  backgroundColor: context.appIconTriad.background,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
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
              prefixIcon: Icon(
                LucideIcons.calculator,
                size: 18,
                color: context.appTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.units_reference_quantity,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
                Text(
                  initialKgFormatted,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
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
          _buildUnitTile(context, l10n, TraditionalUnit.tonelada, wide: true),
          const SizedBox(height: AppDimensions.space12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.units_disclaimer,
              style: AppTextStyles.caption.copyWith(
                color: context.appTextSecondary,
              ),
            ),
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

  /// One compact card: a neutral icon on the left, the unit name above and
  /// the approximate figure below it in large tabular numerals. The figure
  /// stays one string (e.g. "≈ 16 bultos"); only the number is enlarged.
  Widget _buildUnitTile(
    BuildContext context,
    AppLocalizations l10n,
    TraditionalUnit unit, {
    bool wide = false,
  }) {
    final equivalenceText = _formatEquivalence(l10n, _currentKg, unit);
    final name =
        unit.pluralName[0].toUpperCase() + unit.pluralName.substring(1);

    final figure = _figureSpans(context, equivalenceText);
    final value = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: wide ? Alignment.centerRight : Alignment.centerLeft,
      child: Text.rich(figure, maxLines: 1),
    );
    final label = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption.copyWith(
        color: context.appTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );

    return Container(
      key: Key('unit_equivalence_${unit.name}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.appSurfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconSquircle(
            icon: _iconFor(unit),
            size: 34,
            iconSize: 17,
            triad: AppSemanticTriad(
              background: context.appSurface,
              border: AppColors.transparent,
              foreground: context.appTextSecondary,
            ),
          ),
          const SizedBox(width: AppDimensions.space12 - 2),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      Expanded(child: label),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(flex: 2, child: value),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [label, const SizedBox(height: 2), value],
                  ),
          ),
        ],
      ),
    );
  }

  /// Splits a localized equivalence ("≈ 16 bultos") around its number so
  /// the number carries the weight and the words stay quiet.
  TextSpan _figureSpans(BuildContext context, String text) {
    final number = RegExp(r'\d[\d.,]*').firstMatch(text);
    final quiet = AppTextStyles.bodySmall.copyWith(
      color: context.appTextSecondary,
      fontWeight: FontWeight.w500,
    );
    final loud = AppTextStyles.figureMedium.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: context.appTextPrimary,
      fontFeatures: AppTextStyles.tabularFigures,
    );
    if (number == null) return TextSpan(text: text, style: loud);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, number.start), style: quiet),
        TextSpan(text: number.group(0), style: loud),
        TextSpan(text: text.substring(number.end), style: quiet),
      ],
    );
  }
}
