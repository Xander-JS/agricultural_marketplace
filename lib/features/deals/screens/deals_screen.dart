import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import 'deal_detail_screen.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with SingleTickerProviderStateMixin {
  final NegotiationService _service = NegotiationService();
  bool _isLoading = true;
  String? _errorMessage;
  List<NegotiationModel> _negotiations = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final negotiations = await _service.getFarmerNegotiations(user.id);
      
      setState(() {
        _negotiations = negotiations;
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

  List<NegotiationModel> _getFilteredNegotiations(int index) {
    if (index == 0) return _negotiations;
    switch (index) {
      case 1: // Pendientes
        return _negotiations.where((n) => n.status == NegotiationStatus.propuesta).toList();
      case 2: // En negociación
        return _negotiations.where((n) => n.status == NegotiationStatus.contraofertada).toList();
      case 3: // Acordados
        return _negotiations.where((n) => n.status == NegotiationStatus.acordada).toList();
      case 4: // Completados/Historial (rechazados, cancelados, completados)
        return _negotiations.where((n) => 
          n.status == NegotiationStatus.completada || 
          n.status == NegotiationStatus.rechazada || 
          n.status == NegotiationStatus.cancelada
        ).toList();
      default:
        return _negotiations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tratos'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'En negociación'),
            Tab(text: 'Acordados'),
            Tab(text: 'Historial'),
          ],
        ),
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

    return TabBarView(
      controller: _tabController,
      children: List.generate(5, (index) => _buildList(_getFilteredNegotiations(index))),
    );
  }

  Widget _buildList(List<NegotiationModel> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: _buildEmptyState(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildDealCard(list[index]);
        },
      ),
    );
  }

  Widget _buildDealCard(NegotiationModel negotiation) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    
    // We get the last offer if any, or general info
    final latestOffer = (negotiation.offers != null && negotiation.offers!.isNotEmpty) 
        ? negotiation.offers!.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final quantity = latestOffer?.quantityKg ?? 0;
    final price = latestOffer?.proposedPricePerKg ?? 0;
    final buyerName = negotiation.buyerProfile?['full_name'] ?? 'Comprador Anónimo';
    
    final formatter = DateFormat('dd MMM yyyy, hh:mm a', 'es_CO');
    final formattedDate = formatter.format(negotiation.updatedAt);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    negotiation.crop?.title ?? 'Cosecha desconocida',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(negotiation.status),
              ],
            ),
            const SizedBox(height: 12),
            Text('Comprador: $buyerName', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            if (latestOffer != null) ...[
              Text('${quantity.toStringAsFixed(0)} kg'),
              Text('${currencyFormatter.format(price)} / kg', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                if (negotiation.currentResponder == 'farmer' && 
                    (negotiation.status == NegotiationStatus.propuesta || negotiation.status == NegotiationStatus.contraofertada))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Tu turno',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (negotiation.currentResponder == 'buyer' && 
                    (negotiation.status == NegotiationStatus.propuesta || negotiation.status == NegotiationStatus.contraofertada))
                  Text(
                    'Esperando respuesta',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToDetail(negotiation),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ver trato →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(NegotiationStatus status) {
    Color color;
    switch (status) {
      case NegotiationStatus.propuesta:
        color = Colors.blue;
        break;
      case NegotiationStatus.contraofertada:
        color = Colors.orange;
        break;
      case NegotiationStatus.acordada:
        color = Colors.green;
        break;
      case NegotiationStatus.completada:
        color = Colors.teal;
        break;
      case NegotiationStatus.rechazada:
      case NegotiationStatus.cancelada:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toDisplayName(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aún no tienes tratos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Cuando un comprador realice una oferta sobre una de tus cosechas, aparecerá aquí.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to my crops (just pop or push a specific route, maybe context.go if router is used)
              Navigator.pop(context); // Or however it navigates back to my crops
            },
            icon: const Icon(Icons.grass),
            label: const Text('Ver mis cosechas'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(NegotiationModel negotiation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DealDetailScreen(negotiationId: negotiation.id),
      ),
    );
    if (result == true) {
      _loadData(); // Refresh if something changed
    }
  }
}
