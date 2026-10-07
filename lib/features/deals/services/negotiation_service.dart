import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_status.dart';

class NegotiationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NegotiationModel>> getFarmerNegotiations(String farmerId) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops!inner(*),
            profiles:buyer_id(*),
            negotiation_offers(*)
          ''')
          .eq('crops.farmer_id', farmerId)
          .order('updated_at', ascending: false);

      return (response as List).map((n) => NegotiationModel.fromJson(n)).toList();
    } catch (e) {
      throw Exception('Error al cargar tratos: $e');
    }
  }

  Future<NegotiationModel> getNegotiationById(String id) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops(*),
            profiles:buyer_id(*),
            negotiation_offers(*)
          ''')
          .eq('id', id)
          .single();

      return NegotiationModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar el detalle del trato: $e');
    }
  }

  Future<void> counterOffer({
    required String negotiationId,
    required double quantityKg,
    required double proposedPricePerKg,
    required String deliveryMethod,
    String? message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Create the offer
      await _supabase.from('negotiation_offers').insert({
        'negotiation_id': negotiationId,
        'sender_id': user.id,
        'quantity_kg': quantityKg,
        'proposed_price_per_kg': proposedPricePerKg,
        'delivery_method': deliveryMethod,
        if (message != null && message.isNotEmpty) 'message': message,
      });

      // 2. Update negotiation state
      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.contraofertada.toShortString(),
        'current_responder': 'buyer', // assuming 'buyer' / 'farmer'
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);

    } catch (e) {
      throw Exception('Error al enviar contraoferta: $e');
    }
  }

  Future<void> acceptOffer(String negotiationId) async {
    try {
      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.acordada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      throw Exception('Error al aceptar la oferta: $e');
    }
  }

  Future<void> rejectOffer(String negotiationId) async {
    try {
      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.rechazada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      throw Exception('Error al rechazar la oferta: $e');
    }
  }

  Future<void> cancelOffer(String negotiationId) async {
    try {
      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.cancelada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      throw Exception('Error al cancelar la oferta: $e');
    }
  }
}
