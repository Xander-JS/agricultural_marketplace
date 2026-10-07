import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../crop/models/crop_model.dart';
import '../../crop/services/crop_service.dart';
import '../../crop/screens/publish_crop_screen.dart';
import '../services/crop_cost_service.dart';
import 'crop_costs_detail_screen.dart';

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  final _cropService = CropService();
  final _costService = CropCostService();
  
  List<CropModel> _crops = [];
  Map<String, double> _cropTotals = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final crops = await _cropService.getCropsByFarmerId(user.id);
      
      Map<String, double> totals = {};
      for (var crop in crops) {
        totals[crop.id] = await _costService.getTotalCostByCropId(crop.id);
      }

      setState(() {
        _crops = crops;
        _cropTotals = totals;
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

  void _navigateToCreateCrop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PublishCropScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToDetail(CropModel crop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropCostsDetailScreen(crop: crop),
      ),
    );
    // Reload to update total costs in case they were modified
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Costos'),
      ),
      body: _buildBody(),
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
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_crops.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _crops.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Lleva un registro de los gastos\nasociados a tus cosechas.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
            );
          }
          final crop = _crops[index - 1];
          final totalCost = _cropTotals[crop.id] ?? 0.0;
          return _buildCropCard(crop, totalCost);
        },
      ),
    );
  }

  Widget _buildCropCard(CropModel crop, double totalCost) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (crop.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _cropService.getPublicImageUrl(crop.imageUrls.first),
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
                        crop.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total de costos',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        currencyFormatter.format(totalCost),
                        style: TextStyle(
                          fontSize: 20,
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToDetail(crop),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ver costos'),
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Primero debes crear una cosecha',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para llevar un registro de costos, necesitas tener al menos una cosecha registrada.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateCrop,
              icon: const Icon(Icons.add),
              label: const Text('Crear cosecha'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
