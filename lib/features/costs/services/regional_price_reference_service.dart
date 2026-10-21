import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/simulated_regional_price_references.dart';
import '../models/regional_price_reference.dart';

/// Servicio de consulta de referencias regionales de precios para demostración.
///
/// Consulta prioritariamente la tabla `public.regional_price_references` en Supabase
/// y utiliza la lista local `SimulatedRegionalPriceReferences.all` únicamente como
/// fallback ante problemas de red o modo fuera de línea.
class RegionalPriceReferenceService {
  final SupabaseClient? _clientOverride;
  final Future<List<RegionalPriceReference>> Function()? _fetcherOverride;

  RegionalPriceReferenceService({
    SupabaseClient? client,
    Future<List<RegionalPriceReference>> Function()? fetcher,
  })  : _clientOverride = client,
        _fetcherOverride = fetcher;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      if (Supabase.instance.isInitialized) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  /// Consulta prioritariamente los datos desde Supabase (`regional_price_references`).
  /// Si falla o está desconectado, retorna el catálogo local simulado.
  Future<List<RegionalPriceReference>> getReferences() async {
    final override = _fetcherOverride;
    if (override != null) {
      return await override();
    }

    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('regional_price_references')
            .select()
            .timeout(const Duration(seconds: 4));

        final List<dynamic> data = response as List<dynamic>;
        if (data.isNotEmpty) {
          return data
              .map((row) =>
                  RegionalPriceReference.fromJson(row as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // En caso de error de red o timeout, se usa el fallback local
      }
    }

    return SimulatedRegionalPriceReferences.all;
  }

  /// Busca la referencia correspondiente a un cultivo específico.
  Future<RegionalPriceReference?> findForCrop({
    required String cropType,
    required String title,
  }) async {
    try {
      final references = await getReferences();
      return SimulatedRegionalPriceReferences.findInList(
        references: references,
        cropType: cropType,
        title: title,
      );
    } catch (_) {
      return SimulatedRegionalPriceReferences.findForCrop(
        cropType: cropType,
        title: title,
      );
    }
  }
}
