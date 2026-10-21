import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_cost_model.dart';
import 'crop_cost_calculator.dart';

class CropCostService {
  final SupabaseClient _supabase;

  CropCostService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

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
    return CropCostCalculator.totalFromAmounts(
      records.map((record) => record['amount'] as num),
    );
  }

  /// Crea un nuevo registro de costo
  Future<CropCostModel> createCost(CropCostModel cost) async {
    _validateCost(cost);

    final response = await _supabase
        .from('crop_costs')
        .insert(cost.toJson())
        .select()
        .single();
    
    return CropCostModel.fromJson(response);
  }

  /// Actualiza un costo existente
  Future<CropCostModel> updateCost(CropCostModel cost) async {
    _validateCost(cost);

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

  void _validateCost(CropCostModel cost) {
    if (!cost.amount.isFinite || cost.amount <= 0) {
      throw ArgumentError(
        'El importe debe ser numérico, finito y mayor que cero.',
      );
    }
    if (cost.description.trim().isEmpty) {
      throw ArgumentError('La descripción del costo es obligatoria.');
    }
  }
}
