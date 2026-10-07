import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../crop/models/crop_model.dart';
import '../../crop/services/crop_service.dart';
import '../models/crop_cost_model.dart';
import '../services/crop_cost_service.dart';
import 'add_crop_cost_screen.dart';

class CropCostsDetailScreen extends StatefulWidget {
  final CropModel crop;

  const CropCostsDetailScreen({super.key, required this.crop});

  @override
  State<CropCostsDetailScreen> createState() => _CropCostsDetailScreenState();
}

class _CropCostsDetailScreenState extends State<CropCostsDetailScreen> {
  final _costService = CropCostService();
  final _cropService = CropService();

  List<CropCostModel> _costs = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final costs = await _costService.getCostsByCropId(widget.crop.id);
      
      double total = 0.0;
      for (var cost in costs) {
        total += cost.amount;
      }

      setState(() {
        _costs = costs;
        _totalCost = total;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddOrEditCost([CropCostModel? costToEdit]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCropCostScreen(
          cropId: widget.crop.id,
          costToEdit: costToEdit,
        ),
      ),
    );

    if (result == true) {
      _loadCosts();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Costo eliminado')),
        );
      }
      _loadCosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crop.title),
      ),
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
            Text('Ocurrió un error: $_errorMessage', textAlign: TextAlign.center),
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
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (widget.crop.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _cropService.getPublicImageUrl(widget.crop.imageUrls.first),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
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
                    'Total de costos',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(_totalCost),
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
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
              currencyFormatter.format(cost.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega los gastos relacionados con esta cosecha para llevar un mejor control.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
