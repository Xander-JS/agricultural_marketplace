import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_status_badge.dart';
import 'publish_crop_screen.dart';

class CropDetailScreen extends StatefulWidget {
  final CropModel crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  late CropModel _crop;
  final _cropService = CropService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _crop = widget.crop;
  }

  Future<void> _updateStatus(CropStatus newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _cropService.updateCropStatus(_crop.id, newStatus);
      setState(() {
        // En una app real, idealmente volvemos a obtener el objeto desde la BD
        // o actualizamos el estado local.
        _crop = CropModel(
          id: _crop.id,
          farmerId: _crop.farmerId,
          title: _crop.title,
          description: _crop.description,
          cropType: _crop.cropType,
          pricePerKg: _crop.pricePerKg,
          stockTotal: _crop.stockTotal,
          stockCommitted: _crop.stockCommitted,
          stockSold: _crop.stockSold,
          minOrderKg: _crop.minOrderKg,
          department: _crop.department,
          municipality: _crop.municipality,
          isEarlySale: _crop.isEarlySale,
          status: newStatus,
          createdAt: _crop.createdAt,
          updatedAt: DateTime.now(),
          imageUrls: _crop.imageUrls,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PublishCropScreen(cropToEdit: _crop)),
    );

    if (result == true) {
      // Necesita refrescar
      if (mounted) {
        Navigator.pop(context, true); // Devuelve a MarketplaceScreen para que recargue
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar Publicación'),
        content: const Text('¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _cropService.deleteCrop(_crop.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publicación borrada exitosamente'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Retornar true para recargar la lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al borrar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? primaryImageUrl;
    if (_crop.imageUrls.isNotEmpty) {
      primaryImageUrl = _cropService.getPublicImageUrl(_crop.imageUrls.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cosecha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Borrar',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: 'Editar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen
                  if (primaryImageUrl != null)
                    Image.network(
                      primaryImageUrl,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade400),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _crop.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CropStatusBadge(status: _crop.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _crop.cropType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _crop.description,
                          style: theme.textTheme.bodyLarge,
                        ),

                        const Divider(height: 32),

                        _buildInfoRow('Precio por kg', '\$${_crop.pricePerKg.toStringAsFixed(2)}'),
                        _buildInfoRow('Total Disponible', '${_crop.stockTotal.toStringAsFixed(2)} kg'),
                        _buildInfoRow('Pedido Mínimo', '${_crop.minOrderKg.toStringAsFixed(2)} kg'),
                        _buildInfoRow('Ubicación', '${_crop.municipality}, ${_crop.department}'),
                        
                        if (_crop.isEarlySale) ...[
                          const Divider(height: 32),
                          const Text('Venta Anticipada', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_crop.estimatedHarvestDate != null)
                            _buildInfoRow('Fecha est. de cosecha', '${_crop.estimatedHarvestDate!.day}/${_crop.estimatedHarvestDate!.month}/${_crop.estimatedHarvestDate!.year}'),
                          if (_crop.estimatedYieldKg != null)
                            _buildInfoRow('Rendimiento estimado', '${_crop.estimatedYieldKg} kg'),
                        ],

                        const Divider(height: 32),
                        const Text('Acciones Rápidas', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        if (_crop.status == CropStatus.activa)
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(CropStatus.pausada),
                            icon: const Icon(Icons.pause),
                            label: const Text('Pausar Publicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          )
                        else if (_crop.status == CropStatus.pausada || _crop.status == CropStatus.borrador)
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(CropStatus.activa),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Activar Publicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Navegar a pantalla de negociaciones usando _crop.id
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Próximamente: Ver negociaciones')),
                            );
                          },
                          icon: const Icon(Icons.handshake),
                          label: const Text('Ver Negociaciones'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
