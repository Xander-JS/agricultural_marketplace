// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';

class VerificationStatusData {
  final String status;
  final String? rejectionReason;
  final String? role;
  final bool hasVerificationAttempt;
  final bool hasAllDocuments;

  VerificationStatusData({
    required this.status,
    this.rejectionReason,
    this.role,
    this.hasVerificationAttempt = false,
    this.hasAllDocuments = false,
  });

  UserVerificationStatus get verificationStatus =>
      UserVerificationStatus.fromString(status);

  bool get isApproved => verificationStatus.isApproved;
  bool get isPending => verificationStatus.isPending;
  bool get isUnderAiReview => verificationStatus.isUnderAiReview;
  bool get isRejected => verificationStatus.isRejected;
  bool get isSuspended => verificationStatus.isSuspended;
  bool get isUnknown => verificationStatus.isUnknown;
}

/// Estado que debe ver el usuario combinando su perfil con su última
/// solicitud.
///
/// `profiles.verification_status` decide el acceso, pero tras un rechazo el
/// perfil sigue en `rechazado` hasta que el servidor procese la nueva
/// solicitud. Si la última solicitud ya está pendiente o en revisión, el
/// usuario reenvió sus documentos y debe ver la espera, no otra vez el
/// rechazo.
String resolveEffectiveVerificationStatus({
  required String? profileStatus,
  required String? attemptStatus,
}) {
  const reviewStates = {'pendiente', 'en_revision_ia'};
  if (profileStatus == 'aprobado' || profileStatus == 'suspendido') {
    return profileStatus!;
  }
  if (attemptStatus == null) return profileStatus ?? 'desconocido';
  if (reviewStates.contains(attemptStatus) &&
      profileStatus == 'en_revision_ia') {
    return 'en_revision_ia';
  }
  return attemptStatus;
}

/// Lee el perfil propio mediante la RPC `get_my_profile` (SECURITY DEFINER).
///
/// Se usa como respaldo cuando la consulta directa a `profiles` no devuelve
/// filas: si la RPC sí encuentra el perfil, el usuario existe y el problema es
/// de visibilidad (RLS o privilegios de columna), no un registro incompleto.
/// Devuelve `null` solo cuando el perfil realmente no existe.
Future<Map<String, dynamic>?> fetchOwnProfileViaRpc(
  SupabaseClient client,
) async {
  try {
    final result = await client.rpc('get_my_profile');
    if (result is Map) {
      debugPrint(
        '[auth][profile] profiles SELECT returned no row but get_my_profile '
        'found it; review RLS on public.profiles.',
      );
      return Map<String, dynamic>.from(result);
    }
    return null;
  } on PostgrestException catch (error) {
    // P0002: el perfil no existe. PGRST202/42883: la RPC no está desplegada.
    if (error.code == 'P0002' ||
        error.code == 'PGRST202' ||
        error.code == '42883') {
      return null;
    }
    rethrow;
  }
}

class VerificationService {
  final SupabaseClient? _clientOverride;
  final Future<VerificationStatusData> Function()? _statusFetcher;

  VerificationService({
    SupabaseClient? client,
    Future<VerificationStatusData> Function()? statusFetcher,
  }) : _clientOverride = client,
       _statusFetcher = statusFetcher;

  SupabaseClient get _supabase {
    final client = _clientOverride;
    if (client != null) return client;
    return Supabase.instance.client;
  }

  Future<VerificationStatusData> getCurrentVerificationStatus() async {
    final fetcher = _statusFetcher;
    if (fetcher != null) {
      return await fetcher();
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // 1. Get profile status and role
      final profileRes =
          await _supabase
              .from('profiles')
              .select('verification_status, role')
              .eq('id', user.id)
              .maybeSingle() ??
          await fetchOwnProfileViaRpc(_supabase);

      if (profileRes == null) {
        throw Exception('Perfil inexistente');
      }

      final profileStatus = profileRes['verification_status'] as String?;
      final role = profileRes['role'] as String?;

      // 2. Get latest verification attempt details if any
      final attemptRes = await _supabase
          .from('verification_attempts')
          .select(
            'status, rejection_reason, document_front_path, document_back_path, selfie_path',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (attemptRes == null) {
        // If no attempts exist, rely on profile status
        return VerificationStatusData(
          status: profileStatus ?? 'desconocido',
          role: role,
        );
      }

      final attemptStatus = attemptRes['status'] as String?;
      final rejectionReason = attemptRes['rejection_reason'] as String?;
      final hasAllDocuments = _hasAllDocuments(attemptRes);

      final status = resolveEffectiveVerificationStatus(
        profileStatus: profileStatus,
        attemptStatus: attemptStatus,
      );

      return VerificationStatusData(
        status: status,
        rejectionReason: status == 'rechazado' ? rejectionReason : null,
        role: role,
        hasVerificationAttempt: true,
        hasAllDocuments: hasAllDocuments,
      );
    } on PostgrestException catch (e) {
      throw Exception('Error de consulta a Supabase: ${e.message}');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException')) {
        throw Exception('Error de conexión. Verifica tu internet.');
      }
      throw Exception('Estado de verificación inesperado: $e');
    }
  }

  bool _hasAllDocuments(Map<String, dynamic> attempt) {
    final paths = [
      attempt['document_front_path'],
      attempt['document_back_path'],
      attempt['selfie_path'],
    ];
    return paths.every((path) => path is String && path.trim().isNotEmpty);
  }
}
