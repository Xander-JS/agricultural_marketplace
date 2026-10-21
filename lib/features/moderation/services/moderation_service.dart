import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';
import '../models/moderation_request.dart';

/// Resultado estructurado tras aplicar una decisión de moderación (Aprobar / Rechazar).
class ModerationDecisionResult {
  final bool isSuccess;
  final UserVerificationStatus? updatedStatus;
  final String? reason;
  final String? errorMessage;
  final String? errorCode;

  const ModerationDecisionResult({
    required this.isSuccess,
    this.updatedStatus,
    this.reason,
    this.errorMessage,
    this.errorCode,
  });

  factory ModerationDecisionResult.success({
    required UserVerificationStatus updatedStatus,
    String? reason,
  }) {
    return ModerationDecisionResult(
      isSuccess: true,
      updatedStatus: updatedStatus,
      reason: reason,
    );
  }

  factory ModerationDecisionResult.failure({
    required String errorMessage,
    String? errorCode,
  }) {
    return ModerationDecisionResult(
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}

/// Servicio encargado de la consulta, auditoría y resolución de solicitudes de verificación
/// por parte de usuarios con rol `moderador`.
class ModerationService {
  final SupabaseClient? _clientOverride;
  final Future<List<ModerationRequest>> Function({
    int limit,
    int offset,
    String? statusFilter,
  })? requestsFetcher;
  final Future<ModerationDecisionResult> Function({
    required String attemptId,
    required String userId,
    required String decision,
    String? reason,
  })? decisionHandler;
  final String? Function()? currentUserIdFetcher;
  final Future<UserRole> Function()? currentUserRoleFetcher;

  ModerationService({
    SupabaseClient? client,
    this.requestsFetcher,
    this.decisionHandler,
    this.currentUserIdFetcher,
    this.currentUserRoleFetcher,
  }) : _clientOverride = client;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId {
    final fetcher = currentUserIdFetcher;
    if (fetcher != null) {
      return fetcher();
    }
    return _client?.auth.currentUser?.id;
  }

  /// Verifica si el usuario autenticado tiene el rol de moderador
  Future<bool> isCurrentUserModerator() async {
    final roleFetcher = currentUserRoleFetcher;
    if (roleFetcher != null) {
      final role = await roleFetcher();
      return role == UserRole.moderador;
    }

    final userId = currentUserId;
    if (userId == null) return false;

    final client = _client;
    if (client == null) return false;

    try {
      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) return false;
      return UserRole.fromString(profile['role']?.toString()) == UserRole.moderador;
    } catch (_) {
      return false;
    }
  }

  /// Consulta las solicitudes de verificación pendientes de moderación
  Future<List<ModerationRequest>> fetchPendingRequests({
    int limit = 50,
    int offset = 0,
    String? statusFilter,
  }) async {
    final fetcher = requestsFetcher;
    if (fetcher != null) {
      return await fetcher(
        limit: limit,
        offset: offset,
        statusFilter: statusFilter,
      );
    }

    final client = _client;
    if (client == null) {
      throw StateError('SupabaseClient no está disponible.');
    }

    try {
      var query = client.from('verification_attempts').select('''
        id,
        user_id,
        status,
        document_front_path,
        document_back_path,
        selfie_path,
        rejection_reason,
        reviewed_by,
        reviewed_at,
        created_at,
        updated_at,
        profiles!user_id (
          id,
          full_name,
          phone,
          email,
          role,
          verification_status
        )
      ''');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      } else {
        // Por defecto, mostrar pendientes y en_revision_ia
        query = query.inFilter('status', ['pendiente', 'en_revision_ia']);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => ModerationRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('[ModerationService] Error de PostgREST al listar solicitudes: ${e.message} (${e.code})');
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error general al listar solicitudes: $e');
      rethrow;
    }
  }

  /// Aprueba una solicitud de verificación.
  ///
  /// Actualiza tanto el registro en `verification_attempts` como el `verification_status`
  /// del perfil a 'aprobado'.
  Future<ModerationDecisionResult> approveRequest({
    required String attemptId,
    required String userId,
  }) async {
    final handler = decisionHandler;
    if (handler != null) {
      return await handler(
        attemptId: attemptId,
        userId: userId,
        decision: 'aprobado',
      );
    }

    final isMod = await isCurrentUserModerator();
    if (!isMod) {
      return ModerationDecisionResult.failure(
        errorMessage: 'Acceso no autorizado: se requiere el rol de moderador.',
        errorCode: '403',
      );
    }

    final client = _client;
    if (client == null) {
      return ModerationDecisionResult.failure(
        errorMessage: 'SupabaseClient no disponible.',
        errorCode: '500',
      );
    }

    final moderatorId = currentUserId;

    try {
      // 1. Invocar RPC segura de moderación si existe en Supabase
      try {
        await client.rpc('approve_verification_attempt', params: {
          'p_attempt_id': attemptId,
        });
        return ModerationDecisionResult.success(
          updatedStatus: UserVerificationStatus.aprobado,
        );
      } on PostgrestException catch (rpcError) {
        // Si el RPC no existe aún (código PGRST202 o 42883), intentar actualización directa controlada
        if (rpcError.code == 'PGRST202' || rpcError.code == '42883') {
          debugPrint('[ModerationService] RPC approve_verification_attempt no disponible. Intentando fallback directo...');
        } else {
          return ModerationDecisionResult.failure(
            errorMessage: rpcError.message,
            errorCode: rpcError.code,
          );
        }
      }

      // Fallback directo sobre verification_attempts y profiles
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await client.from('verification_attempts').update({
        'status': 'aprobado',
        'reviewed_by': moderatorId,
        'reviewed_at': nowUtc,
        'moderator_result': {
          'decision': 'aprobado',
          'moderator_id': moderatorId,
          'timestamp': nowUtc,
        },
      }).eq('id', attemptId);

      await client.from('profiles').update({
        'verification_status': 'aprobado',
        'updated_at': nowUtc,
      }).eq('id', userId);

      return ModerationDecisionResult.success(
        updatedStatus: UserVerificationStatus.aprobado,
      );
    } on PostgrestException catch (e) {
      debugPrint('[ModerationService] PostgrestException al aprobar solicitud: ${e.message} (${e.code})');
      return ModerationDecisionResult.failure(
        errorMessage: e.message,
        errorCode: e.code,
      );
    } catch (e) {
      debugPrint('[ModerationService] Error inesperado al aprobar solicitud: $e');
      return ModerationDecisionResult.failure(
        errorMessage: e.toString(),
        errorCode: '500',
      );
    }
  }

  /// Rechaza una solicitud de verificación registrando obligatoriamente el motivo.
  Future<ModerationDecisionResult> rejectRequest({
    required String attemptId,
    required String userId,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('El motivo de rechazo no puede estar vacío.');
    }

    final handler = decisionHandler;
    if (handler != null) {
      return await handler(
        attemptId: attemptId,
        userId: userId,
        decision: 'rechazado',
        reason: cleanReason,
      );
    }

    final isMod = await isCurrentUserModerator();
    if (!isMod) {
      return ModerationDecisionResult.failure(
        errorMessage: 'Acceso no autorizado: se requiere el rol de moderador.',
        errorCode: '403',
      );
    }

    final client = _client;
    if (client == null) {
      return ModerationDecisionResult.failure(
        errorMessage: 'SupabaseClient no disponible.',
        errorCode: '500',
      );
    }

    final moderatorId = currentUserId;

    try {
      // 1. Invocar RPC segura de rechazo si existe en Supabase
      try {
        await client.rpc('reject_verification_attempt', params: {
          'p_attempt_id': attemptId,
          'p_reason': cleanReason,
        });
        return ModerationDecisionResult.success(
          updatedStatus: UserVerificationStatus.rechazado,
          reason: cleanReason,
        );
      } on PostgrestException catch (rpcError) {
        if (rpcError.code == 'PGRST202' || rpcError.code == '42883') {
          debugPrint('[ModerationService] RPC reject_verification_attempt no disponible. Intentando fallback directo...');
        } else {
          return ModerationDecisionResult.failure(
            errorMessage: rpcError.message,
            errorCode: rpcError.code,
          );
        }
      }

      // Fallback directo sobre verification_attempts y profiles
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await client.from('verification_attempts').update({
        'status': 'rechazado',
        'rejection_reason': cleanReason,
        'reviewed_by': moderatorId,
        'reviewed_at': nowUtc,
        'moderator_result': {
          'decision': 'rechazado',
          'reason': cleanReason,
          'moderator_id': moderatorId,
          'timestamp': nowUtc,
        },
      }).eq('id', attemptId);

      await client.from('profiles').update({
        'verification_status': 'rechazado',
        'updated_at': nowUtc,
      }).eq('id', userId);

      return ModerationDecisionResult.success(
        updatedStatus: UserVerificationStatus.rechazado,
        reason: cleanReason,
      );
    } on PostgrestException catch (e) {
      debugPrint('[ModerationService] PostgrestException al rechazar solicitud: ${e.message} (${e.code})');
      return ModerationDecisionResult.failure(
        errorMessage: e.message,
        errorCode: e.code,
      );
    } catch (e) {
      debugPrint('[ModerationService] Error inesperado al rechazar solicitud: $e');
      return ModerationDecisionResult.failure(
        errorMessage: e.toString(),
        errorCode: '500',
      );
    }
  }

  /// Marca una solicitud en proceso de revisión ('en_revision_ia').
  Future<ModerationDecisionResult> markInReview({
    required String attemptId,
    required String userId,
  }) async {
    final handler = decisionHandler;
    if (handler != null) {
      return await handler(
        attemptId: attemptId,
        userId: userId,
        decision: 'en_revision_ia',
      );
    }

    final isMod = await isCurrentUserModerator();
    if (!isMod) {
      return ModerationDecisionResult.failure(
        errorMessage: 'Acceso no autorizado: se requiere el rol de moderador.',
        errorCode: '403',
      );
    }

    final client = _client;
    if (client == null) {
      return ModerationDecisionResult.failure(
        errorMessage: 'SupabaseClient no disponible.',
        errorCode: '500',
      );
    }

    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await client.from('verification_attempts').update({
        'status': 'en_revision_ia',
        'updated_at': nowUtc,
      }).eq('id', attemptId);

      await client.from('profiles').update({
        'verification_status': 'en_revision_ia',
        'updated_at': nowUtc,
      }).eq('id', userId);

      return ModerationDecisionResult.success(
        updatedStatus: UserVerificationStatus.enRevisionIa,
      );
    } on PostgrestException catch (e) {
      debugPrint(
        '[ModerationService] PostgrestException al marcar en revisión: ${e.message} (${e.code})',
      );
      return ModerationDecisionResult.failure(
        errorMessage: e.message,
        errorCode: e.code,
      );
    } catch (e) {
      debugPrint(
        '[ModerationService] Error inesperado al marcar en revisión: $e',
      );
      return ModerationDecisionResult.failure(
        errorMessage: e.toString(),
        errorCode: '500',
      );
    }
  }
}
