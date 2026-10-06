import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationStatusData {
  final String status;
  final String? rejectionReason;
  final String? role;

  VerificationStatusData({required this.status, this.rejectionReason, this.role});
}

class VerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<VerificationStatusData> getCurrentVerificationStatus() async {
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

      final profileStatus = profileRes['verification_status'] as String;
      final role = profileRes['role'] as String?;

      // 2. Get latest verification attempt details if any
      final attemptRes = await _supabase
          .from('verification_attempts')
          .select('status, rejection_reason')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (attemptRes == null) {
        // If no attempts exist, rely on profile status
        return VerificationStatusData(status: profileStatus, role: role);
      }

      final attemptStatus = attemptRes['status'] as String;
      final rejectionReason = attemptRes['rejection_reason'] as String?;

      // According to the logic, we can return the attempt status or profile status.
      // Usually, profile status is the source of truth for the app access,
      // but attempt status might have the specific rejection reason.
      // If profile is approved but attempt is rejected (unlikely), profile wins.
      if (profileStatus == 'aprobado' || profileStatus == 'suspendido') {
        return VerificationStatusData(status: profileStatus, role: role);
      }

      return VerificationStatusData(
        status: attemptStatus,
        rejectionReason: rejectionReason,
        role: role,
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
}
