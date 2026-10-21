// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../deals/exceptions/commercial_exception.dart';
import '../../deals/models/negotiation_status.dart';
import '../models/review_model.dart';

/// Servicio de calificaciones y reputación sobre `public.reviews`.
///
/// Reglas aplicadas en cliente:
/// - Solo el usuario autenticado puede emitir su propia calificación.
/// - Solo se califica una negociación en estado `completada`.
/// - El destinatario se deduce de la negociación (`buyer_id` y
///   `crops.farmer_id`); nunca se recibe como UUID libre desde la interfaz.
/// - La calificación debe estar entre 1 y 5 estrellas.
/// - El comentario es opcional.
/// - La unicidad por `(negotiation_id, reviewer_id)` se apoya en el índice
///   único de la base de datos; la consulta previa solo informa el estado de
///   la interfaz y no sustituye esa garantía ante escrituras concurrentes.
class ReviewService {
  final SupabaseClient _supabase;
  final String? _currentUserIdForTesting;

  ReviewService({SupabaseClient? client, String? currentUserIdForTesting})
    : _supabase = client ?? Supabase.instance.client,
      _currentUserIdForTesting = currentUserIdForTesting;

  String? get _activeUserId =>
      _currentUserIdForTesting ?? _supabase.auth.currentUser?.id;

  String _requireUserId() {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) {
      throw const CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: '28000',
      );
    }
    return userId;
  }

  /// Indica si el usuario autenticado ya calificó una negociación.
  ///
  /// Este resultado es solo informativo para la interfaz. La garantía real de
  /// una única reseña por usuario y negociación la aporta el índice único de
  /// `public.reviews`, no esta consulta previa.
  Future<bool> hasReviewedNegotiation(String negotiationId) async {
    final userId = _requireUserId();
    _validateNegotiationId(negotiationId);

    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('negotiation_id', negotiationId)
          .eq('reviewer_id', userId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (pe) {
      throw _mapPostgrestError(
        pe,
        fallbackMessage: 'Error al verificar la calificación de la negociación',
      );
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al verificar la calificación de la negociación: $e',
        originalError: e,
      );
    }
  }

  /// Registra la calificación del usuario autenticado sobre una negociación
  /// completada.
  ///
  /// El destinatario se resuelve internamente como la contraparte real del
  /// trato. No se acepta `reviewed_user_id` desde fuera del servicio.
  Future<ReviewModel> submitReview({
    required String negotiationId,
    required int rating,
    String? comment,
  }) async {
    final userId = _requireUserId();
    _validateNegotiationId(negotiationId);

    if (!ReviewModel.isValidRating(rating)) {
      throw const CommercialValidationException(
        'La calificación debe estar entre 1 y 5 estrellas.',
        code: '22000',
      );
    }

    final negotiation = await _loadNegotiationContext(negotiationId);
    if (negotiation.status != NegotiationStatus.completada.toShortString()) {
      throw const CommercialValidationException(
        'Solo puedes calificar una negociación completada.',
        code: '22000',
      );
    }

    final reviewedUserId = resolveCounterpartyId(
      reviewerId: userId,
      buyerId: negotiation.buyerId,
      farmerId: negotiation.farmerId,
    );

    if (reviewedUserId == null) {
      throw const CommercialAuthorizationException(
        'No eres participante de esta negociación.',
        code: '42501',
      );
    }

    if (reviewedUserId == userId) {
      throw const CommercialValidationException(
        'No puedes calificarte a ti mismo.',
        code: '22000',
      );
    }

    final cleanComment = (comment != null && comment.trim().isNotEmpty)
        ? comment.trim()
        : null;

    final review = ReviewModel(
      negotiationId: negotiationId,
      reviewerId: userId,
      reviewedUserId: reviewedUserId,
      rating: rating,
      comment: cleanComment,
    );

    try {
      final response = await _supabase
          .from('reviews')
          .insert(review.toInsertJson())
          .select()
          .single();

      return ReviewModel.fromJson(response);
    } on PostgrestException catch (pe) {
      throw _mapPostgrestError(
        pe,
        fallbackMessage: 'Error al registrar la calificación',
      );
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al registrar la calificación: $e',
        originalError: e,
      );
    }
  }

  /// Obtiene las calificaciones recibidas por un usuario, de la más reciente a
  /// la más antigua.
  Future<List<ReviewModel>> getReceivedReviews(String userId) async {
    if (userId.trim().isEmpty) {
      throw const CommercialValidationException(
        'El usuario solicitado no es válido.',
        code: '22000',
      );
    }

    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('reviewed_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => ReviewModel.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (pe) {
      throw _mapPostgrestError(
        pe,
        fallbackMessage: 'Error al cargar las calificaciones recibidas',
      );
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al cargar las calificaciones recibidas: $e',
        originalError: e,
      );
    }
  }

  /// Calcula en memoria el promedio aritmético y el total de reseñas recibidas.
  static ReviewSummary calculateSummary(Iterable<ReviewModel> reviews) {
    return ReviewSummary.fromReviews(reviews);
  }

  /// Obtiene la reputación calculada de un usuario.
  ///
  /// Si no existen reseñas, devuelve un [ReviewSummary] vacío cuyo `isNew` es
  /// `true`, listo para representarse como «New» / «No ratings yet».
  Future<ReviewSummary> getReputation(String userId) async {
    final reviews = await getReceivedReviews(userId);
    return calculateSummary(reviews);
  }

  /// Obtiene la reputación de varios usuarios en una sola consulta.
  ///
  /// Agrupa las reseñas por `reviewed_user_id` y calcula cada resumen con
  /// [calculateSummary]. Los usuarios sin reseñas reciben [ReviewSummary.empty]
  /// para evitar consultas adicionales por elemento.
  Future<Map<String, ReviewSummary>> getReputationsForUsers(
    Iterable<String> userIds,
  ) async {
    final uniqueIds = userIds
        .map((userId) => userId.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (uniqueIds.isEmpty) return const <String, ReviewSummary>{};

    try {
      final response = await _supabase
          .from('reviews')
          .select('reviewed_user_id, rating')
          .inFilter('reviewed_user_id', uniqueIds);

      final reviewsByUser = <String, List<ReviewModel>>{};
      for (final row in (response as List)) {
        final review = ReviewModel.fromJson(row as Map<String, dynamic>);
        reviewsByUser
            .putIfAbsent(review.reviewedUserId, () => <ReviewModel>[])
            .add(review);
      }

      return {
        for (final userId in uniqueIds)
          userId: calculateSummary(
            reviewsByUser[userId] ?? const <ReviewModel>[],
          ),
      };
    } on PostgrestException catch (pe) {
      throw _mapPostgrestError(
        pe,
        fallbackMessage: 'Error al cargar las reputaciones de los productores',
      );
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al cargar las reputaciones de los productores: $e',
        originalError: e,
      );
    }
  }

  /// Resuelve la contraparte real de una negociación.
  ///
  /// Retorna `null` si el revisor no es ni el comprador ni el agricultor.
  static String? resolveCounterpartyId({
    required String reviewerId,
    required String buyerId,
    required String farmerId,
  }) {
    if (reviewerId == buyerId) return farmerId;
    if (reviewerId == farmerId) return buyerId;
    return null;
  }

  Future<_NegotiationReviewContext> _loadNegotiationContext(
    String negotiationId,
  ) async {
    try {
      final response = await _supabase
          .from('negotiations')
          .select('id, buyer_id, status, crops!inner(farmer_id)')
          .eq('id', negotiationId)
          .maybeSingle();

      if (response == null) {
        throw const CommercialValidationException(
          'La negociación no existe o no tienes acceso a ella.',
          code: 'P0002',
        );
      }

      final crops = response['crops'];
      final farmerId = crops is Map ? crops['farmer_id']?.toString() : null;
      final buyerId = response['buyer_id']?.toString();

      if (buyerId == null ||
          buyerId.isEmpty ||
          farmerId == null ||
          farmerId.isEmpty) {
        throw const CommercialValidationException(
          'No se pudo determinar la contraparte de la negociación.',
          code: 'P0002',
        );
      }

      return _NegotiationReviewContext(
        buyerId: buyerId,
        farmerId: farmerId,
        status: response['status']?.toString() ?? '',
      );
    } on PostgrestException catch (pe) {
      throw _mapPostgrestError(
        pe,
        fallbackMessage: 'Error al consultar la negociación',
      );
    } catch (e) {
      if (e is CommercialException) rethrow;
      throw CommercialDatabaseException(
        'Error al consultar la negociación: $e',
        originalError: e,
      );
    }
  }

  static void _validateNegotiationId(String negotiationId) {
    if (negotiationId.trim().isEmpty) {
      throw const CommercialValidationException(
        'La negociación indicada no es válida.',
        code: '22000',
      );
    }
  }

  static CommercialException _mapPostgrestError(
    PostgrestException pe, {
    required String fallbackMessage,
  }) {
    final code = pe.code;
    final details = pe.details?.toString();

    if (code == '28000') {
      return CommercialAuthException(
        'Usuario no autenticado. Por favor inicia sesión nuevamente.',
        code: code,
        details: details,
      );
    }

    if (code == '23505') {
      return CommercialValidationException(
        'Ya calificaste esta negociación.',
        code: code,
        details: details,
      );
    }

    if (code == '42501') {
      return CommercialAuthorizationException(
        'No tienes permisos para calificar esta negociación.',
        code: code,
        details: details,
      );
    }

    if (code == '23503' || code == 'P0002') {
      return CommercialValidationException(
        'La negociación o el usuario asociado no existe.',
        code: code,
        details: details,
      );
    }

    if (code == '23514') {
      return CommercialValidationException(
        'La calificación no cumple las restricciones de la base de datos.',
        code: code,
        details: details,
      );
    }

    return CommercialDatabaseException(
      '$fallbackMessage: ${pe.message}',
      code: code,
      details: details,
      originalError: pe,
    );
  }
}

class _NegotiationReviewContext {
  final String buyerId;
  final String farmerId;
  final String status;

  const _NegotiationReviewContext({
    required this.buyerId,
    required this.farmerId,
    required this.status,
  });
}
