import 'package:supabase_flutter/supabase_flutter.dart';

import '../../deals/models/negotiation_model.dart';
import '../../deals/models/negotiation_status.dart';

class PurchasesService {
  final SupabaseClient? _client;

  PurchasesService([this._client]);

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Obtiene los acuerdos vigentes y compras completadas del comerciante/comprador
  Future<List<NegotiationModel>> getPurchases(String buyerId) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops(*, crop_images(image_path, is_primary), profiles:farmer_id(id, full_name, role, profile_path, verification_status, department, municipality)),
            profiles:buyer_id(id, full_name, role, profile_path, verification_status, department, municipality),
            negotiation_offers(*)
          ''')
          .eq('buyer_id', buyerId)
          .inFilter('status', [
            NegotiationStatus.acordada.toShortString(),
            NegotiationStatus.completada.toShortString(),
          ])
          .order('updated_at', ascending: false);

      return (response as List)
          .map((n) => NegotiationModel.fromJson(n))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar compras: $e');
    }
  }
}
