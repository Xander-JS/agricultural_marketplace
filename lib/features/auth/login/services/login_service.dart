import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signIn({required String phone, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );

      if (response.user == null) {
        throw Exception('No se pudo autenticar el usuario.');
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception(
          'Credenciales incorrectas. Verifica tu número y contraseña.',
        );
      }
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
