import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/unit_formatters.dart';
import '../../crop/models/crop_model.dart';
import '../../crop/services/crop_service.dart';
import '../models/crop_cost_model.dart';
import '../services/crop_cost_calculator.dart';
import '../services/crop_cost_service.dart';
import 'add_crop_cost_screen.dart';
import 'crop_profitability_screen.dart';

class CropCostsDetailScreen extends StatefulWidget {
  final CropModel crop;
  final CropService? cropService;
  final CropCostService? costService;

  const CropCostsDetailScreen({
    super.key,
    required this.crop,
    this.cropService,
    this.costService,
  });

  @override
  State<CropCostsDetailScreen> createState() => _CropCostsDetailScreenState();
}

class _CropCostsDetailScreenState extends State<CropCostsDetailScreen> {
  late final CropCostService _costService;
  late final CropService _cropService;

  List<CropCostModel> _costs = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalCost = 0.0;
  CropCostPerKgResult? _perKgResult;

  @override
  void initState() {
    super.initState();
    _costService = widget.costService ?? CropCostService();
    _cropService = widget.cropService ?? CropService();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final costs = await _costService.getCostsByCropId(widget.crop.id);
      final total = CropCostCalculator.totalForCrop(costs, widget.crop.id);
      final perKg = CropCostCalculator.calculatePerKg(
        crop: widget.crop,
        totalCost: total,
      );

      if (!mounted) return;
      setState(() {
        _costs = costs;
        _totalCost = total;
        _perKgResult = perKg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddOrEditCost([CropCostModel? costToEdit]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCropCostScreen(
          cropId: widget.crop.id,
          costToEdit: costToEdit,
          costService: _costService,
        ),
      ),
    );

    if (result == true) {
      await _loadCosts();
    }
  }

  Future<void> _deleteCost(CropCostModel cost) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este costo?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _costService.deleteCost(cost.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Costo eliminado')));
        await _loadCosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  void _openProfitability() {
    final result = _perKgResult;
    if (result == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CropProfitabilityScreen(crop: widget.crop, costPerKgResult: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.crop.title)),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddOrEditCost(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar costo'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ocurrió un error: $_errorMessage',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCosts,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCosts,
      child: ListView(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
        children: [
          _buildCropHeader(),
          const SizedBox(height: 16),
          _buildProfitabilityEntryCard(),
          const SizedBox(height: 24),
          if (_costs.isEmpty)
            _buildEmptyState()
          else
            ..._costs.map((cost) => _buildCostCard(cost)),
        ],
      ),
    );
  }

  Widget _buildCropHeader() {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.crop.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _cropService.getPublicImageUrl(
                        widget.crop.imageUrls.first,
                      ),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    ),
                  )
                else
                  _buildPlaceholderImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.crop.title,
                        key: const Key('crop_cost_crop_title'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.crop.cropType} · ${widget.crop.municipality}, ${widget.crop.department}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total de costos',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatters.formatCop(_totalCost),
                        key: const Key('crop_cost_total'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerKgSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerKgSection() {
    final result = _perKgResult;
    if (result == null) return const SizedBox.shrink();

    final isCalculated = result.isCalculated;
    final denominatorText = result.denominator == null
        ? 'No disponible'
        : UnitFormatters.formatKg(result.denominator);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.scale_outlined,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              const Text(
                'Costo estimado por kg',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isCalculated)
            Text(
              CurrencyFormatters.formatPricePerKg(result.costPerKg),
              key: const Key('crop_cost_per_kg_value'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            )
          else
            Text(
              result.message,
              key: const Key('crop_cost_per_kg_message'),
              style: TextStyle(color: Colors.grey.shade800),
            ),
          const SizedBox(height: 4),
          Text(
            'Cantidad usada: $denominatorText (${result.denominatorSource.displayName})',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            'Campo: ${result.denominatorSource.fieldName}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityEntryCard() {
    return Card(
      key: const Key('crop_profitability_button'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor
              .withValues(alpha: 0.1),
          child: Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
        ),
        title: const Text(
          'Margen y precio sugerido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Calcula ganancia, margen y compara con referencias simuladas.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _openProfitability,
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.grass, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildCostCard(CropCostModel cost) {
    IconData getCategoryIcon(CostCategory category) {
      switch (category) {
        case CostCategory.jornales:
          return Icons.people;
        case CostCategory.fertilizantes:
          return Icons.eco;
        case CostCategory.transporte:
          return Icons.local_shipping;
        case CostCategory.otros:
          return Icons.more_horiz;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor
              .withValues(alpha: 0.1),
          child: Icon(
            getCategoryIcon(cost.category),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          cost.category.toDisplayName(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(cost.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatters.formatCop(cost.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToAddOrEditCost(cost);
                } else if (value == 'delete') {
                  _deleteCost(cost);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes costos registrados',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega los gastos relacionados con esta cosecha para llevar un mejor control.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
