import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/negotiation_model.dart';
import '../models/negotiation_status.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/constants/delivery_methods.dart';

class NegotiationService {
  final SupabaseClient _supabase;

  NegotiationService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

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

  /// Obtiene los tratos donde el usuario es el comprador
  Future<List<NegotiationModel>> getBuyerNegotiations(String buyerId) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops(*, profiles:farmer_id(*)),
            profiles:buyer_id(*),
            negotiation_offers(*)
          ''')
          .eq('buyer_id', buyerId)
          .order('updated_at', ascending: false);

      return (response as List).map((n) => NegotiationModel.fromJson(n)).toList();
    } catch (e) {
      throw Exception('Error al cargar tratos del comprador: $e');
    }
  }

  Future<NegotiationModel> getNegotiationById(String id) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops(*, profiles:farmer_id(*)),
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

  /// Valida que el usuario tenga estado de verificación 'aprobado' en su perfil
  Future<void> _validateUserApproved(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('verification_status')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        final status = UserVerificationStatus.fromString(
          profile['verification_status'] as String?,
        );
        if (!status.isApproved) {
          throw Exception(
            'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales.',
          );
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al validar estado de verificación: $e');
    }
  }

  Future<void> counterOffer({
    required String negotiationId,
    required double quantityKg,
    required double proposedPricePerKg,
    required String deliveryMethod,
    String? message,
    String? nextResponder,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Validar permisos de verificación comercial
      await _validateUserApproved(user.id);

      // Determinar quién debe responder en formato PostgreSQL enum user_role
      String responderDb;
      if (nextResponder != null) {
        responderDb = UserRole.fromString(nextResponder).toDbValue();
      } else {
        final neg = await _supabase
            .from('negotiations')
            .select('buyer_id')
            .eq('id', negotiationId)
            .maybeSingle();

        if (neg != null && neg['buyer_id'] == user.id) {
          responderDb = UserRole.agricultor.toDbValue();
        } else {
          responderDb = UserRole.comprador.toDbValue();
        }
      }

      final now = DateTime.now().toIso8601String();

      // 1. Create the offer
      final offerPayload = buildOfferPayload(
        negotiationId: negotiationId,
        senderId: user.id,
        quantityKg: quantityKg,
        proposedPricePerKg: proposedPricePerKg,
        deliveryMethod: deliveryMethod,
        message: message,
        timestamp: now,
      );
      await _supabase.from('negotiation_offers').insert(offerPayload);

      // 2. Update negotiation state
      final updatePayload = buildCounterOfferNegotiationPayload(
        nextResponderRole: responderDb,
        timestamp: now,
      );
      await _supabase.from('negotiations').update(updatePayload).eq('id', negotiationId);

    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al enviar contraoferta: $e');
    }
  }

  /// Acepta un trato acordando las condiciones y reservando el stock pactado:
  /// stock_disponible = stock_total - stock_comprometido - stock_vendido
  Future<void> acceptOffer(String negotiationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Validar permisos comerciales
      await _validateUserApproved(user.id);

      // 1. Obtener la negociación y su última oferta
      final negotiation = await getNegotiationById(negotiationId);
      final offers = negotiation.offers;
      if (offers == null || offers.isEmpty) {
        throw Exception('No hay ofertas registradas en esta negociación');
      }

      final latestOffer = offers.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );

      final crop = negotiation.crop;
      if (crop != null) {
        final available = crop.availableStock;
        if (latestOffer.quantityKg > available) {
          throw Exception(
            'Stock disponible insuficiente ($available kg) para reservar ${latestOffer.quantityKg} kg pactados',
          );
        }

        // 2. Reservar stock pactado en crops
        final newCommitted = crop.stockCommitted + latestOffer.quantityKg;
        await _supabase.from('crops').update({
          'stock_committed': newCommitted,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', crop.id);

        // 3. Registrar movimiento de inventario (reserva)
        try {
          await _supabase.from('inventory_movements').insert({
            'crop_id': crop.id,
            'negotiation_id': negotiationId,
            'movement_type': 'reserva',
            'quantity_kg': latestOffer.quantityKg,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Si la tabla no está disponible o falla el insert opcional, no romper el flujo
        }
      }

      // 4. Actualizar estado de negociación a 'acordada'
      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.acordada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al aceptar la oferta: $e');
    }
  }

  /// Completa una negociación acordada: convierte el stock comprometido en stock vendido
  Future<void> completeNegotiation(String negotiationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _validateUserApproved(user.id);

      final negotiation = await getNegotiationById(negotiationId);
      final offers = negotiation.offers;
      if (offers == null || offers.isEmpty) {
        throw Exception('No hay ofertas registradas en esta negociación');
      }

      final latestOffer = offers.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );

      final crop = negotiation.crop;
      if (crop != null) {
        final newCommitted = max(0.0, crop.stockCommitted - latestOffer.quantityKg);
        final newSold = crop.stockSold + latestOffer.quantityKg;
        final availableRemaining = crop.stockTotal - newCommitted - newSold;
        final isAgotada = availableRemaining <= 0;

        await _supabase.from('crops').update({
          'stock_committed': newCommitted,
          'stock_sold': newSold,
          if (isAgotada) 'status': 'agotada',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', crop.id);

        try {
          await _supabase.from('inventory_movements').insert({
            'crop_id': crop.id,
            'negotiation_id': negotiationId,
            'movement_type': 'venta',
            'quantity_kg': latestOffer.quantityKg,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.completada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al completar la negociación: $e');
    }
  }

  /// Rechaza un trato y libera la reserva de inventario si ya estaba acordado
  Future<void> rejectOffer(String negotiationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final negotiation = await getNegotiationById(negotiationId);
      if (negotiation.status == NegotiationStatus.acordada && negotiation.crop != null) {
        final offers = negotiation.offers;
        if (offers != null && offers.isNotEmpty) {
          final latestOffer = offers.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
          );
          final crop = negotiation.crop!;
          final newCommitted = max(0.0, crop.stockCommitted - latestOffer.quantityKg);
          await _supabase.from('crops').update({
            'stock_committed': newCommitted,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', crop.id);

          try {
            await _supabase.from('inventory_movements').insert({
              'crop_id': crop.id,
              'negotiation_id': negotiationId,
              'movement_type': 'liberacion_reserva',
              'quantity_kg': latestOffer.quantityKg,
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        }
      }

      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.rechazada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al rechazar la oferta: $e');
    }
  }

  /// Cancela una propuesta de negociación y libera la reserva si correspondía
  Future<void> cancelOffer(String negotiationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final negotiation = await getNegotiationById(negotiationId);
      if (negotiation.status == NegotiationStatus.acordada && negotiation.crop != null) {
        final offers = negotiation.offers;
        if (offers != null && offers.isNotEmpty) {
          final latestOffer = offers.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
          );
          final crop = negotiation.crop!;
          final newCommitted = max(0.0, crop.stockCommitted - latestOffer.quantityKg);
          await _supabase.from('crops').update({
            'stock_committed': newCommitted,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', crop.id);

          try {
            await _supabase.from('inventory_movements').insert({
              'crop_id': crop.id,
              'negotiation_id': negotiationId,
              'movement_type': 'liberacion_reserva',
              'quantity_kg': latestOffer.quantityKg,
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        }
      }

      await _supabase.from('negotiations').update({
        'status': NegotiationStatus.cancelada.toShortString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', negotiationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al cancelar la oferta: $e');
    }
  }

  /// Consulta si el comprador ya tiene una negociación activa para este cultivo
  Future<NegotiationModel?> getActiveNegotiationForCrop({
    required String cropId,
    required String buyerId,
  }) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops(*),
            negotiation_offers(*)
          ''')
          .eq('crop_id', cropId)
          .eq('buyer_id', buyerId)
          .inFilter('status', [
            NegotiationStatus.propuesta.toShortString(),
            NegotiationStatus.contraofertada.toShortString(),
            NegotiationStatus.acordada.toShortString(),
          ])
          .maybeSingle();

      if (response == null) return null;
      return NegotiationModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Genera el payload canónico para insertar en la tabla `negotiations`.
  /// Garantiza que `current_responder` use el enum PostgreSQL `agricultor` ('agricultor') y NUNCA 'farmer'.
  static Map<String, dynamic> buildInitialNegotiationPayload({
    required String cropId,
    required String buyerId,
    required String timestamp,
  }) {
    final roleDb = UserRole.agricultor.toDbValue();
    assert(roleDb == 'agricultor' && roleDb != 'farmer');
    return {
      'crop_id': cropId,
      'buyer_id': buyerId,
      'status': NegotiationStatus.propuesta.toShortString(),
      'current_responder': roleDb,
      'created_at': timestamp,
      'updated_at': timestamp,
    };
  }

  /// Genera el payload canónico para insertar en la tabla `negotiation_offers`.
  /// Mapea el método de entrega al enum PostgreSQL `delivery_method`.
  static Map<String, dynamic> buildOfferPayload({
    required String negotiationId,
    required String senderId,
    required double quantityKg,
    required double proposedPricePerKg,
    required String deliveryMethod,
    String? message,
    required String timestamp,
  }) {
    final deliveryDb = DeliveryMethod.toDb(deliveryMethod);
    return {
      'negotiation_id': negotiationId,
      'sender_id': senderId,
      'quantity_kg': quantityKg,
      'proposed_price_per_kg': proposedPricePerKg,
      'delivery_method': deliveryDb,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      'created_at': timestamp,
    };
  }

  /// Genera el payload canónico para actualizar la tabla `negotiations` en contraofertas.
  static Map<String, dynamic> buildCounterOfferNegotiationPayload({
    required String nextResponderRole,
    required String timestamp,
  }) {
    final responderDb = UserRole.fromString(nextResponderRole).toDbValue();
    assert(responderDb == 'agricultor' || responderDb == 'comprador');
    return {
      'status': NegotiationStatus.contraofertada.toShortString(),
      'current_responder': responderDb,
      'updated_at': timestamp,
    };
  }

  /// Crea una nueva negociación iniciada por el comprador con su oferta inicial.
  ///
  /// Garantiza:
  /// 1. Validación de verificación comercial del usuario ('aprobado').
  /// 2. Validación de pedido mínimo y stock disponible según `app_movil_estados_Sistema.docx`.
  /// 3. Asignación correcta del turno inicial al agricultor (`current_responder = 'agricultor'`).
  /// 4. Atomicidad: rollback con eliminación de la negociación si falla la oferta inicial.
  Future<NegotiationModel> createNegotiation({
    required String cropId,
    required double quantityKg,
    required double proposedPricePerKg,
    required String deliveryMethod,
    String? message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Validar que el comprador tenga cuenta aprobada
      await _validateUserApproved(user.id);

      // 2. Validar reglas de inventario de la cosecha
      final cropRes = await _supabase
          .from('crops')
          .select('stock_total, stock_committed, stock_sold, min_order_kg')
          .eq('id', cropId)
          .single();

      final total = (cropRes['stock_total'] as num).toDouble();
      final committed = (cropRes['stock_committed'] as num? ?? 0).toDouble();
      final sold = (cropRes['stock_sold'] as num? ?? 0).toDouble();
      final minOrder = (cropRes['min_order_kg'] as num? ?? 1).toDouble();
      final available = max(0.0, total - committed - sold);

      if (quantityKg < minOrder) {
        throw Exception('La cantidad no cumple con el pedido mínimo (${minOrder.toStringAsFixed(0)} kg)');
      }
      if (quantityKg > available) {
        throw Exception('La cantidad supera el stock disponible (${available.toStringAsFixed(0)} kg)');
      }

      // 3. Validar que no exista negociación activa previa para el mismo cultivo
      final existing = await getActiveNegotiationForCrop(
        cropId: cropId,
        buyerId: user.id,
      );
      if (existing != null) {
        throw Exception('Ya tienes una negociación activa para este cultivo');
      }

      final now = DateTime.now().toIso8601String();

      // 4. Insertar registro en negotiations con enum user_role: 'agricultor'
      final negPayload = buildInitialNegotiationPayload(
        cropId: cropId,
        buyerId: user.id,
        timestamp: now,
      );

      final negResponse = await _supabase
          .from('negotiations')
          .insert(negPayload)
          .select()
          .single();

      final negotiationId = negResponse['id'] as String;

      final offerPayload = buildOfferPayload(
        negotiationId: negotiationId,
        senderId: user.id,
        quantityKg: quantityKg,
        proposedPricePerKg: proposedPricePerKg,
        deliveryMethod: deliveryMethod,
        message: message,
        timestamp: now,
      );

      // 5. Insertar primera oferta en negotiation_offers con rollback de resguardo
      try {
        await _supabase.from('negotiation_offers').insert(offerPayload);
      } catch (insertError) {
        // En caso de fallo al persistir la oferta inicial, eliminar la negociación creada
        // para garantizar atomicidad y evitar registros huérfanos incompletos en PostgreSQL
        try {
          await _supabase.from('negotiations').delete().eq('id', negotiationId);
        } catch (_) {}
        rethrow;
      }

      // 6. Retornar la negociación completa
      return await getNegotiationById(negotiationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al iniciar negociación: $e');
    }
  }
}
