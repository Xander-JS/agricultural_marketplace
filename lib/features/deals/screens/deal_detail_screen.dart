import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../models/negotiation_status.dart';
import '../services/negotiation_service.dart';
import 'counter_offer_screen.dart';

class DealDetailScreen extends StatefulWidget {
  final String negotiationId;

  const DealDetailScreen({super.key, required this.negotiationId});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  final NegotiationService _service = NegotiationService();
  bool _isLoading = true;
  String? _errorMessage;
  NegotiationModel? _negotiation;

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
      final negotiation = await _service.getNegotiationById(widget.negotiationId);
      setState(() {
        _negotiation = negotiation;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del trato'),
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

    if (_negotiation == null) {
      return const Center(child: Text('No se encontró el trato.'));
    }

    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final n = _negotiation!;
    
    // Sort offers chronologically
    final offers = n.offers ?? [];
    offers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    final latestOffer = offers.isNotEmpty ? offers.last : null;
    final buyerName = n.buyerProfile?['full_name'] ?? 'Comprador Anónimo';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.crop?.title ?? 'Cosecha desconocida',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Comprador', style: TextStyle(color: Colors.grey.shade600)),
            Text(buyerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            
            if (latestOffer != null) ...[
              _buildInfoRow('Cantidad', '${latestOffer.quantityKg.toStringAsFixed(0)} kg'),
              const SizedBox(height: 8),
              _buildInfoRow('Precio por kg', currencyFormatter.format(latestOffer.proposedPricePerKg)),
              const SizedBox(height: 8),
              _buildInfoRow('Método de entrega', latestOffer.deliveryMethod),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
            ],

            _buildInfoRow('Estado', n.status.toDisplayName(), isStatus: true, status: n.status),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),

            const Text(
              'Historial de ofertas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...offers.map((offer) => _buildOfferBubble(offer, n)).toList(),

            const SizedBox(height: 32),

            _buildActionButtons(n, latestOffer),

            if (n.status == NegotiationStatus.completada) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to Rating screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('La calificación de compradores estará disponible pronto.')),
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Calificar comprador'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, NegotiationStatus? status}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
        if (isStatus && status != null)
          _buildStatusBadge(status)
        else
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOfferBubble(NegotiationOfferModel offer, NegotiationModel negotiation) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final formatter = DateFormat('hh:mm a', 'es_CO');
    
    final user = Supabase.instance.client.auth.currentUser;
    final isMe = offer.senderId == user?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
          ),
          border: Border.all(
            color: isMe ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        width: MediaQuery.of(context).size.width * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMe ? 'Tú' : 'Comprador',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMe ? Theme.of(context).primaryColor : Colors.black87,
                  ),
                ),
                Text(
                  formatter.format(offer.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${currencyFormatter.format(offer.proposedPricePerKg)} / kg'),
            Text('${offer.quantityKg.toStringAsFixed(0)} kg'),
            Text('Entrega: ${offer.deliveryMethod}'),
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${offer.message}"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(NegotiationModel n, NegotiationOfferModel? latestOffer) {
    if (n.status == NegotiationStatus.acordada || 
        n.status == NegotiationStatus.completada || 
        n.status == NegotiationStatus.rechazada || 
        n.status == NegotiationStatus.cancelada) {
      return const SizedBox.shrink();
    }

    if (n.currentResponder != 'farmer') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange.shade800),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Esperando respuesta del comprador',
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _acceptOffer(n),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar oferta', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: latestOffer == null ? null : () => _navigateToCounterOffer(n, latestOffer),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Contraofertar', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _rejectOffer(n),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Rechazar trato', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _navigateToCounterOffer(NegotiationModel n, NegotiationOfferModel latestOffer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CounterOfferScreen(
          negotiation: n,
          latestOffer: latestOffer,
        ),
      ),
    );
    if (result == true) {
      _loadData();
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _acceptOffer(NegotiationModel n) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await _service.acceptOffer(n.id);
      
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trato acordado correctamente.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectOffer(NegotiationModel n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Rechazar este trato?'),
        content: const Text('Esta acción no se puede deshacer y el trato se cerrará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }
      
      await _service.rejectOffer(n.id);
      
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El trato ha sido rechazado.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}
