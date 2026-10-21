// ignore_for_file: prefer_initializing_formals
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
      final profileRes = await _supabase
          .from('profiles')
          .select('verification_status, role')
          .eq('id', user.id)
          .maybeSingle();

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

      // According to the logic, we can return the attempt status or profile status.
      // Usually, profile status is the source of truth for the app access,
      // but attempt status might have the specific rejection reason.
      // If profile is approved but attempt is rejected (unlikely), profile wins.
      if (profileStatus == 'aprobado' || profileStatus == 'suspendido') {
        return VerificationStatusData(
          status: profileStatus!,
          role: role,
          hasVerificationAttempt: true,
          hasAllDocuments: hasAllDocuments,
        );
      }

      return VerificationStatusData(
        status: attemptStatus ?? profileStatus ?? 'desconocido',
        rejectionReason: rejectionReason,
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
