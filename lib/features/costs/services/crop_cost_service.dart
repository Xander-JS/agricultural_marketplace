import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_cost_model.dart';

class CropCostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene los costos asociados a una cosecha específica
  Future<List<CropCostModel>> getCostsByCropId(String cropId) async {
    final response = await _supabase
        .from('crop_costs')
        .select()
        .eq('crop_id', cropId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => CropCostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene el costo total para una cosecha sumando los registros
  Future<double> getTotalCostByCropId(String cropId) async {
    final response = await _supabase
        .from('crop_costs')
        .select('amount')
        .eq('crop_id', cropId);

    final List<dynamic> records = response as List<dynamic>;
    double total = 0.0;
    for (var record in records) {
      total += (record['amount'] as num).toDouble();
    }
    return total;
  }

  /// Crea un nuevo registro de costo
  Future<CropCostModel> createCost(CropCostModel cost) async {
    final response = await _supabase
        .from('crop_costs')
        .insert(cost.toJson())
        .select()
        .single();
    
    return CropCostModel.fromJson(response);
  }

  /// Actualiza un costo existente
  Future<CropCostModel> updateCost(CropCostModel cost) async {
    final response = await _supabase
        .from('crop_costs')
        .update({
          'category': cost.category.toShortString(),
          'description': cost.description,
          'amount': cost.amount,
        })
        .eq('id', cost.id)
        .select()
        .single();

    return CropCostModel.fromJson(response);
  }

  /// Elimina un costo
  Future<void> deleteCost(String costId) async {
    await _supabase.from('crop_costs').delete().eq('id', costId);
  }
}
