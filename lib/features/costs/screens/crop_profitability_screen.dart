import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/unit_formatters.dart';
import '../../crop/models/crop_model.dart';
import '../data/simulated_regional_price_references.dart';
import '../models/regional_price_reference.dart';
import '../services/crop_cost_calculator.dart';
import '../services/profit_margin_calculator.dart';
import '../services/regional_price_reference_service.dart';

/// Calculadora orientativa de margen y precio sugerido para un cultivo.
///
/// No guarda preferencias, no modifica `pricePerKg` y no publica cambios.
class CropProfitabilityScreen extends StatefulWidget {
  final CropModel crop;
  final CropCostPerKgResult costPerKgResult;
  final RegionalPriceReferenceService? regionalReferenceService;
  final RegionalPriceReference? initialReference;

  const CropProfitabilityScreen({
    super.key,
    required this.crop,
    required this.costPerKgResult,
    this.regionalReferenceService,
    this.initialReference,
  });

  @override
  State<CropProfitabilityScreen> createState() =>
      _CropProfitabilityScreenState();
}

class _CropProfitabilityScreenState extends State<CropProfitabilityScreen> {
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _targetMarginController;
  late final RegionalPriceReferenceService _referenceService;

  RegionalPriceReference? _regionalReference;
  double? _evaluatedPrice;
  double? _targetMargin;
  bool _priceEdited = false;

  bool get _hasCurrentPrice =>
      widget.crop.pricePerKg.isFinite && widget.crop.pricePerKg > 0;

  bool get _isUsingTemporaryPrice {
    if (_evaluatedPrice == null) return false;
    if (!_hasCurrentPrice) return _priceEdited;
    return (_evaluatedPrice! - widget.crop.pricePerKg).abs() > 0.005;
  }

  @override
  void initState() {
    super.initState();
    _referenceService = widget.regionalReferenceService ?? RegionalPriceReferenceService();
    _regionalReference = widget.initialReference ??
        SimulatedRegionalPriceReferences.findForCrop(
          cropType: widget.crop.cropType,
          title: widget.crop.title,
        );
    _loadRegionalReference();

    final currentPrice = widget.crop.pricePerKg;
    _evaluatedPrice = _hasCurrentPrice ? currentPrice : null;
    _sellingPriceController = TextEditingController(
      text: _hasCurrentPrice
          ? UnitFormatters.formatCleanValue(
              currentPrice,
              useLocaleSeparators: false,
            )
          : '',
    );
    _targetMargin = 15;
    _targetMarginController = TextEditingController(text: '15');
  }

  Future<void> _loadRegionalReference() async {
    try {
      final ref = await _referenceService.findForCrop(
        cropType: widget.crop.cropType,
        title: widget.crop.title,
      );
      if (mounted && ref != null) {
        setState(() {
          _regionalReference = ref;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _targetMarginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final costPerKg = widget.costPerKgResult.isCalculated
        ? widget.costPerKgResult.costPerKg
        : null;
    final marginResult = ProfitMarginCalculator.calculateMargin(
      costPerKg: costPerKg,
      sellingPricePerKg: _evaluatedPrice,
    );
    final suggestedResult = ProfitMarginCalculator.calculateSuggestedPrice(
      costPerKg: costPerKg,
      targetMarginPercentage: _targetMargin,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Margen y precio sugerido')),
      body: Column(
        children: [
          _buildSimulatedNoticeBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCostSummary(),
                  const SizedBox(height: 16),
                  if (!widget.costPerKgResult.isCalculated)
                    _buildUnavailableCard()
                  else ...[
                    _buildPriceEvaluationCard(marginResult),
                    const SizedBox(height: 16),
                    _buildSuggestedPriceCard(suggestedResult),
                  ],
                  const SizedBox(height: 16),
                  _buildRegionalReferenceCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.withValues(alpha: 0.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              SimulatedRegionalPriceReferences.notice,
              key: const Key('simulated_reference_notice'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    final result = widget.costPerKgResult;
    final primary = Theme.of(context).primaryColor;

    return Card(
      elevation: 0,
      color: primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scale_outlined, size: 20, color: primary),
                const SizedBox(width: 8),
                const Text(
                  'Costo de producción por kg',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (result.isCalculated)
              Text(
                CurrencyFormatters.formatPricePerKg(result.costPerKg),
                key: const Key('profit_cost_per_kg'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              )
            else
              Text(
                result.message,
                key: const Key('profit_cost_unavailable_message'),
                style: TextStyle(color: Colors.grey.shade800),
              ),
            if (result.denominator != null) ...[
              const SizedBox(height: 4),
              Text(
                'Cantidad usada: ${UnitFormatters.formatKg(result.denominator)} '
                '(${result.denominatorSource.displayName}) · '
                '${result.denominatorSource.fieldName}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Precio actual publicado',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _hasCurrentPrice
                      ? CurrencyFormatters.formatPricePerKg(
                          widget.crop.pricePerKg,
                        )
                      : 'No disponible',
                  key: const Key('profit_current_price'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (!_hasCurrentPrice) ...[
              const SizedBox(height: 4),
              Text(
                'El precio actual no es válido. Puedes introducir un precio temporal para la simulación.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.errorContainer
          .withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No se puede calcular el margen ni el precio sugerido',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(widget.costPerKgResult.message),
                  const SizedBox(height: 6),
                  const Text(
                    'Corrige los costos o los datos del cultivo para continuar. No se muestran valores estimados para evitar resultados engañosos.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceEvaluationCard(ProfitMarginResult marginResult) {
    final color = marginResult.isLoss
        ? Theme.of(context).colorScheme.error
        : Colors.green.shade700;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evalúa tu precio de venta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profit_selling_price_field'),
              controller: _sellingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Precio de venta por kg',
                prefixText: '\$ ',
                suffixText: '/ kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _priceEdited = true;
                  _evaluatedPrice = CropCostCalculator.parseAmount(value);
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes editar este valor para la simulación; no se guarda ni modifica el precio publicado.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (_isUsingTemporaryPrice) ...[
              const SizedBox(height: 4),
              Text(
                'Precio temporal para simulación; no se ha guardado.',
                key: const Key('profit_temporary_price_note'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_evaluatedPrice == null)
              Text(
                'Ingresa un precio de venta válido mayor que 0.',
                key: const Key('profit_price_error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (marginResult.isCalculated)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marginResult.isLoss
                          ? 'Pérdida estimada por kg'
                          : 'Ganancia estimada por kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatters.formatPricePerKg(
                        marginResult.profitPerKg,
                      ),
                      key: const Key('profit_amount_value'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Margen sobre el precio de venta',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatPercentage(marginResult.marginPercentage),
                      key: const Key('profit_margin_value'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (marginResult.isLoss)
                      Text(
                        'El precio evaluado está por debajo del costo de producción.',
                        key: const Key('profit_loss_message'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if ((marginResult.marginPercentage ?? 0) <
                        ProfitMarginCalculator.referenceMarginPercentage)
                      Text(
                        'El margen está por debajo del 15 % de referencia del prototipo.',
                        key: const Key('profit_low_margin_warning'),
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Margen = (precio − costo) / precio × 100',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                marginResult.message,
                key: const Key('profit_margin_message'),
                style: TextStyle(color: Colors.grey.shade800),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPriceCard(SuggestedPriceResult suggestedResult) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precio sugerido según margen objetivo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('profit_target_margin_field'),
              controller: _targetMarginController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Margen objetivo (%)',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _targetMargin = ProfitMarginCalculator.parseMarginPercentage(
                    value,
                  );
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'El margen se aplica sobre el precio de venta; no es un recargo sobre el costo.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (_targetMargin == null)
              Text(
                'Ingresa un margen entre 0 % y menos de 100 %.',
                key: const Key('profit_target_margin_error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (suggestedResult.isCalculated) ...[
              Text(
                CurrencyFormatters.formatPricePerKg(
                  suggestedResult.suggestedPricePerKg,
                ),
                key: const Key('profit_suggested_price'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Precio orientativo. No modifica ni publica el precio del cultivo.',
                style: TextStyle(fontSize: 12),
              ),
            ] else
              Text(
                suggestedResult.message,
                key: const Key('profit_suggested_message'),
                style: TextStyle(color: Colors.grey.shade800),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalReferenceCard() {
    final reference = _regionalReference;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer
          .withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Referencia regional simulada',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (reference?.isSimulated == true)
                  Chip(
                    label: const Text('SIMULADA'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.orange.shade100,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (reference == null)
              const Text(
                'No hay una referencia simulada configurada para este cultivo.',
                key: Key('simulated_reference_missing'),
              )
            else
              _buildReferenceDetails(reference),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceDetails(RegionalPriceReference reference) {
    final comparison = ProfitMarginCalculator.compareToReference(
      evaluatedPricePerKg: _evaluatedPrice,
      referencePricePerKg: reference.referencePricePerKg,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Cultivo de referencia', reference.cropName),
        _buildInfoRow('Región', reference.region),
        _buildInfoRow(
          'Precio de referencia simulado',
          CurrencyFormatters.formatPricePerKg(reference.referencePricePerKg),
          valueKey: const Key('simulated_reference_price'),
        ),
        _buildInfoRow('Tipo de dato', 'Simulado para el prototipo'),
        const Divider(height: 24),
        if (comparison.isCalculated) ...[
          _buildInfoRow(
            'Diferencia frente a la referencia simulada',
            CurrencyFormatters.formatPricePerKg(comparison.differencePerKg),
            valueKey: const Key('simulated_reference_difference'),
          ),
          Text(
            comparison.message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'La diferencia se calcula como precio evaluado − referencia.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ] else
          Text(
            comparison.message,
            key: const Key('simulated_reference_difference_unavailable'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Key? valueKey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercentage(double? value) {
    if (value == null || !value.isFinite) return 'No disponible';
    return '${UnitFormatters.formatCleanValue(value, maxDecimals: 2)} %';
  }
}
