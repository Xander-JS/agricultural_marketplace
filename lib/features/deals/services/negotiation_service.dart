// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/negotiation_model.dart';
import '../models/negotiation_status.dart';
import '../models/negotiation_consent_model.dart';
import '../exceptions/commercial_exception.dart';
import '../../../core/constants/user_roles.dart';
import '../../../core/constants/delivery_methods.dart';

export '../exceptions/commercial_exception.dart';
export '../models/negotiation_consent_model.dart';

typedef RpcInvoker = Future<dynamic> Function(
  String functionName, {
  Map<String, dynamic>? params,
});

typedef GetNegotiationByIdInvoker = Future<NegotiationModel> Function(
  String id,
);

class NegotiationService {
  final SupabaseClient _supabase;
  final RpcInvoker? _rpcInvoker;
  final GetNegotiationByIdInvoker? _getNegotiationByIdInvoker;
  final String? _currentUserIdForTesting;

  NegotiationService({
    SupabaseClient? client,
    RpcInvoker? rpcInvoker,
    GetNegotiationByIdInvoker? getNegotiationByIdInvoker,
    String? currentUserIdForTesting,
  }) : _supabase = client ?? Supabase.instance.client,
       _rpcInvoker = rpcInvoker,
       _getNegotiationByIdInvoker = getNegotiationByIdInvoker,
       _currentUserIdForTesting = currentUserIdForTesting;

  String? get _activeUserId =>
      _currentUserIdForTesting ?? _supabase.auth.currentUser?.id;

  Future<List<NegotiationModel>> getFarmerNegotiations(String farmerId) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops!inner(*, crop_images(image_path, is_primary)),
            profiles:buyer_id(id, full_name, role, profile_path, verification_status, department, municipality),
            negotiation_offers(*)
          ''')
          .eq('crops.farmer_id', farmerId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((n) => NegotiationModel.fromJson(n))
          .toList();
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
            crops(*, crop_images(image_path, is_primary), profiles:farmer_id(id, full_name, role, profile_path, verification_status, department, municipality)),
            profiles:buyer_id(id, full_name, role, profile_path, verification_status, department, municipality),
            negotiation_offers(*)
          ''')
          .eq('buyer_id', buyerId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((n) => NegotiationModel.fromJson(n))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar tratos del comprador: $e');
    }
  }

  Future<NegotiationModel> getNegotiationById(String id) async {
    final invoker = _getNegotiationByIdInvoker;
    if (invoker != null) {
      return await invoker(id);
    }
    try {
      final response = await _supabase
          .from('negotiations')
          .select('''
            *,
            crops(*, crop_images(image_path, is_primary), profiles:farmer_id(id, full_name, role, profile_path, verification_status, department, municipality)),
            profiles:buyer_id(id, full_name, role, profile_path, verification_status, department, municipality),
            negotiation_offers(*)
          ''')
          .eq('id', id)
          .single();

      return NegotiationModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar el detalle del trato: $e');
    }
  }

  /// Registra una contraoferta mediante la función RPC PostgreSQL transaccional `counter_offer`.
  /// Valida en servidor: identidad, perfil aprobado, turnos, participantes y stock disponible.
  Future<void> counterOffer({
    required String negotiationId,
    required double quantityKg,
    required double proposedPricePerKg,
    required String deliveryMethod,
    String? message,
    String? nextResponder,
  }) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final dbDelivery = DeliveryMethod.toDb(deliveryMethod);
    final cleanMessage = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : null;

    final Map<String, dynamic> rpcParams = {
      'p_negotiation_id': negotiationId,
      'p_quantity_kg': quantityKg,
      'p_proposed_price_per_kg': proposedPricePerKg,
      'p_delivery_method': dbDelivery,
      'p_message': cleanMessage,
    };

    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        await invoker('counter_offer', params: rpcParams);
      } else {
        await _supabase.rpc('counter_offer', params: rpcParams);
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al enviar contraoferta: $e',
        originalError: e,
      );
    }
  }

  /// Acepta un trato acordando las condiciones y reservando el stock pactado
  /// mediante la función RPC PostgreSQL transaccional `accept_negotiation`.
  ///
  /// Ejecuta bloqueo exclusivo `FOR UPDATE` en `crops`, verifica stock disponible,
  /// reserva inventario en `stock_committed`, registra movimiento en `inventory_movements`
  /// y actualiza `negotiations.status = 'acordada'` en una única transacción atómica.
  Future<void> acceptOffer(String negotiationId) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final Map<String, dynamic> rpcParams = {'p_negotiation_id': negotiationId};

    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        await invoker('accept_negotiation', params: rpcParams);
      } else {
        await _supabase.rpc('accept_negotiation', params: rpcParams);
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al aceptar la oferta: $e',
        originalError: e,
      );
    }
  }

  /// Completa una negociación acordada mediante la función RPC PostgreSQL transaccional `complete_negotiation`.
  ///
  /// Traslada `stock_committed` a `stock_sold`, ajusta estado del cultivo a 'agotada' si stock disponible llega a 0,
  /// registra movimiento 'venta' en `inventory_movements` y actualiza `negotiations.status = 'completada'`.
  Future<void> completeNegotiation(String negotiationId) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final Map<String, dynamic> rpcParams = {'p_negotiation_id': negotiationId};

    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        await invoker('complete_negotiation', params: rpcParams);
      } else {
        await _supabase.rpc('complete_negotiation', params: rpcParams);
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al completar la negociación: $e',
        originalError: e,
      );
    }
  }

  /// Rechaza un trato mediante la función RPC PostgreSQL transaccional `reject_or_cancel_negotiation`.
  ///
  /// Si el trato ya estaba en estado 'acordada', libera atómicamente el `stock_committed`
  /// y registra el movimiento 'liberacion_reserva' en `inventory_movements`.
  Future<void> rejectOffer(String negotiationId, {String? reason}) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final cleanReason = (reason != null && reason.trim().isNotEmpty)
        ? reason.trim()
        : null;

    final Map<String, dynamic> rpcParams = {
      'p_negotiation_id': negotiationId,
      'p_target_status': 'rechazada',
      if (cleanReason != null) 'p_reason': cleanReason,
    };

    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        await invoker('reject_or_cancel_negotiation', params: rpcParams);
      } else {
        await _supabase.rpc('reject_or_cancel_negotiation', params: rpcParams);
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al rechazar la oferta: $e',
        originalError: e,
      );
    }
  }

  /// Cancela una propuesta de negociación mediante la función RPC PostgreSQL transaccional `reject_or_cancel_negotiation`.
  ///
  /// Si el trato ya estaba en estado 'acordada', libera atómicamente el `stock_committed`
  /// y registra el movimiento 'liberacion_reserva' en `inventory_movements`.
  Future<void> cancelOffer(String negotiationId, {String? reason}) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final cleanReason = (reason != null && reason.trim().isNotEmpty)
        ? reason.trim()
        : null;

    final Map<String, dynamic> rpcParams = {
      'p_negotiation_id': negotiationId,
      'p_target_status': 'cancelada',
      if (cleanReason != null) 'p_reason': cleanReason,
    };

    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        await invoker('reject_or_cancel_negotiation', params: rpcParams);
      } else {
        await _supabase.rpc('reject_or_cancel_negotiation', params: rpcParams);
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al cancelar la oferta: $e',
        originalError: e,
      );
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
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
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

  /// Transforma PostgrestException de Supabase/PostgreSQL en excepciones comerciales tipadas.
  /// Mapea los códigos SQL estándar y mensajes del servidor protegiendo credenciales y tokens.
  static CommercialException mapPostgrestError(PostgrestException pe) {
    final code = pe.code;
    final message = pe.message;
    final details = pe.details?.toString();

    // 1. Error de autenticación (28000) o sesión ausente
    if (code == '28000' || message.toLowerCase().contains('no autenticado')) {
      return CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: code,
        details: details,
      );
    }

    // 2. Errores de permisos / RLS / Verificación de negocio (42501)
    if (code == '42501') {
      final msgLower = message.toLowerCase();
      if (msgLower.contains('aprobad') || msgLower.contains('verificad')) {
        return CommercialValidationException(
          'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales.',
          code: code,
          details: details,
        );
      }
      if (msgLower.contains('propio cultivo')) {
        return CommercialValidationException(
          'No puedes iniciar una negociación sobre tu propio cultivo.',
          code: code,
          details: details,
        );
      }
      if (msgLower.contains('rol') && msgLower.contains('comprador')) {
        return CommercialValidationException(
          'Solo los usuarios con rol de comprador pueden iniciar negociaciones.',
          code: code,
          details: details,
        );
      }
      if (msgLower.contains('turno')) {
        return CommercialValidationException(
          'No es tu turno para responder a esta negociación.',
          code: code,
          details: details,
        );
      }
      if (msgLower.contains('propia oferta')) {
        return CommercialValidationException(
          'No puedes aceptar tu propia oferta.',
          code: code,
          details: details,
        );
      }
      if (msgLower.contains('cancelar una propuesta')) {
        return CommercialAuthorizationException(
          'Solo el comprador proponente puede cancelar una propuesta inicial.',
          code: code,
          details: details,
        );
      }
      if (msgLower.contains('participante')) {
        return CommercialAuthorizationException(
          'Acceso denegado: no eres participante de esta negociación.',
          code: code,
          details: details,
        );
      }
      return CommercialAuthorizationException(
        'Acceso denegado: no tienes permisos para realizar esta operación comercial.',
        code: code,
        details: details,
      );
    }

    // 3. Reglas comerciales y stock (22000)
    if (code == '22000') {
      final msgLower = message.toLowerCase();
      if (msgLower.contains('stock') || msgLower.contains('disponible')) {
        return InsufficientStockException(
          message,
          code: code,
          details: details,
        );
      }
      return CommercialValidationException(
        message,
        code: code,
        details: details,
      );
    }

    // 4. Negociación activa duplicada (23505 - Unique Violation)
    if (code == '23505' ||
        message.toLowerCase().contains('ya tienes una negociación activa')) {
      return DuplicateNegotiationException(
        'Ya tienes una negociación activa para este cultivo.',
        code: code,
        details: details,
      );
    }

    // 5. Violación de restricciones CHECK de integridad (23514)
    if (code == '23514') {
      return CommercialValidationException(
        'Operación rechazada: los valores no cumplen con las restricciones de integridad comercial.',
        code: code,
        details: details,
      );
    }

    // 6. Entidad no encontrada (P0002)
    if (code == 'P0002') {
      return CommercialValidationException(
        message,
        code: code,
        details: details,
      );
    }

    // 7. Otros errores de base de datos
    return CommercialDatabaseException(
      'Error en la base de datos: $message',
      code: code,
      details: details,
      originalError: pe,
    );
  }

  /// Crea una nueva negociación iniciada por el comprador con su oferta inicial
  /// de forma atómica mediante la función RPC PostgreSQL `create_negotiation_with_offer`.
  ///
  /// Garantiza:
  /// 1. Validación de sesión autenticada.
  /// 2. Atomicidad ACID total: la negociación y la oferta inicial se crean en la misma transacción.
  /// 3. Validación en servidor de perfil aprobado, rol comprador, stock disponible y pedido mínimo.
  /// 4. Protección contra condiciones de carrera e inserciones duplicadas (bloqueo FOR SHARE + índice único).
  /// 5. Eliminación del rollback manual frágil en cliente.
  Future<NegotiationModel> createNegotiation({
    required String cropId,
    required double quantityKg,
    required double proposedPricePerKg,
    required String deliveryMethod,
    String? message,
  }) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado',
        code: '28000',
      );
    }

    final dbDelivery = DeliveryMethod.toDb(deliveryMethod);
    final cleanMessage = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : null;

    final Map<String, dynamic> rpcParams = {
      'p_crop_id': cropId,
      'p_quantity_kg': quantityKg,
      'p_proposed_price_per_kg': proposedPricePerKg,
      'p_delivery_method': dbDelivery,
      'p_message': ?cleanMessage,
    };

    final dynamic rpcResponse;
    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        rpcResponse = await invoker(
          'create_negotiation_with_offer',
          params: rpcParams,
        );
      } else {
        rpcResponse = await _supabase.rpc(
          'create_negotiation_with_offer',
          params: rpcParams,
        );
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al procesar la negociación: $e',
        originalError: e,
      );
    }

    final Map<String, dynamic> data = rpcResponse is Map<String, dynamic>
        ? rpcResponse
        : Map<String, dynamic>.from(rpcResponse as Map);

    final negotiationId = data['id'] as String;
    return await getNegotiationById(negotiationId);
  }

  /// Guarda o actualiza los permisos de consentimiento del usuario autenticado
  /// de forma segura mediante la RPC `set_negotiation_consent`.
  Future<void> setNegotiationConsent({
    required String negotiationId,
    required bool sharePhone,
    required bool shareLocation,
  }) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final Map<String, dynamic> rpcParams = {
      'p_negotiation_id': negotiationId,
      'p_share_phone': sharePhone,
      'p_share_location': shareLocation,
    };

    try {
      final invoker = _rpcInvoker;
      if (invoker != null) {
        await invoker('set_negotiation_consent', params: rpcParams);
      } else {
        await _supabase.rpc('set_negotiation_consent', params: rpcParams);
      }
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al guardar el consentimiento: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene los datos de contacto autorizados por la contraparte y el estado
  /// de los consentimientos mutuos mediante la RPC segura `get_negotiation_counterpart_contact`.
  Future<NegotiationContactInfo> getCounterpartContact(
    String negotiationId,
  ) async {
    final userId = _activeUserId;
    if (userId == null) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }

    final Map<String, dynamic> rpcParams = {'p_negotiation_id': negotiationId};

    try {
      final dynamic response;
      final invoker = _rpcInvoker;
      if (invoker != null) {
        response = await invoker(
          'get_negotiation_counterpart_contact',
          params: rpcParams,
        );
      } else {
        response = await _supabase.rpc(
          'get_negotiation_counterpart_contact',
          params: rpcParams,
        );
      }

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);

      return NegotiationContactInfo.fromJson(data);
    } on PostgrestException catch (pe) {
      throw mapPostgrestError(pe);
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al obtener los datos de contacto: $e',
        originalError: e,
      );
    }
  }
}
