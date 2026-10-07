import 'package:flutter/material.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_offer_model.dart';
import '../services/negotiation_service.dart';

class CounterOfferScreen extends StatefulWidget {
  final NegotiationModel negotiation;
  final NegotiationOfferModel latestOffer;

  const CounterOfferScreen({
    super.key,
    required this.negotiation,
    required this.latestOffer,
  });

  @override
  State<CounterOfferScreen> createState() => _CounterOfferScreenState();
}

class _CounterOfferScreenState extends State<CounterOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = NegotiationService();

  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _messageController;
  
  String _deliveryMethod = 'En finca';
  final List<String> _deliveryOptions = [
    'En finca',
    'Punto de acopio',
    'Destino final',
    'Acordar con el comprador'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.latestOffer.quantityKg.toStringAsFixed(0));
    _priceController = TextEditingController(text: widget.latestOffer.proposedPricePerKg.toStringAsFixed(0));
    _messageController = TextEditingController();
    
    if (_deliveryOptions.contains(widget.latestOffer.deliveryMethod)) {
      _deliveryMethod = widget.latestOffer.deliveryMethod;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.counterOffer(
        negotiationId: widget.negotiation.id,
        quantityKg: double.parse(_quantityController.text),
        proposedPricePerKg: double.parse(_priceController.text),
        deliveryMethod: _deliveryMethod,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraoferta enviada exitosamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contraoferta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifica los términos de la oferta para ${widget.negotiation.crop?.title ?? 'la cosecha'}.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad (kg)',
                        border: OutlineInputBorder(),
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo requerido';
                        if (double.tryParse(value) == null) return 'Debe ser un número válido';
                        if (double.parse(value) <= 0) return 'Debe ser mayor a 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio propuesto por kg',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo requerido';
                        if (double.tryParse(value) == null) return 'Debe ser un número válido';
                        if (double.parse(value) <= 0) return 'Debe ser mayor a 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _deliveryMethod,
                      decoration: const InputDecoration(
                        labelText: 'Método de entrega',
                        border: OutlineInputBorder(),
                      ),
                      items: _deliveryOptions.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _deliveryMethod = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje (Opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Explica el motivo de tu contraoferta',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enviar contraoferta', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
