import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> registerUser({
    required String phone,
    required String firstName,
    required String lastName,
    required String role,
    required String documentType,
    required File documentFront,
    required File documentBack,
    required File selfie,
  }) async {
    try {
      // 1. Create auth user
      // Since the mockup doesn't have a password field, we use a temporary password.
      // In a real scenario, this might use OTP, but we need the user ID immediately
      // to insert into profiles and verification_attempts as per the instructions.
      final cleanPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
      final AuthResponse authRes = await _supabase.auth.signUp(
        email: '$cleanPhone@agromarket.com',
        password: 'TempPassword123!', // Placeholder since no password in UI
      );

      final user = authRes.user;
      if (user == null) {
        throw Exception('Error al crear el usuario en Supabase Auth');
      }

      // 2. Upload images to user_documents bucket
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final frontPath = '${user.id}/front_$timestamp.jpg';
      final backPath = '${user.id}/back_$timestamp.jpg';
      final selfiePath = '${user.id}/selfie_$timestamp.jpg';

      await _supabase.storage
          .from('user_documents')
          .upload(frontPath, documentFront);
      await _supabase.storage
          .from('user_documents')
          .upload(backPath, documentBack);
      await _supabase.storage.from('user_documents').upload(selfiePath, selfie);

      // 3. Insert into profiles
      await _supabase.from('profiles').insert({
        'id': user.id,
        'phone': phone,
        'full_name': '$firstName $lastName'.trim(),
        'role': role,
        'verification_status': 'pendiente',
      });

      // 4. Insert into verification_attempts
      await _supabase.from('verification_attempts').insert({
        'user_id': user.id,
        'status': 'pendiente',
        'document_front_path': frontPath,
        'document_back_path': backPath,
        'selfie_path': selfiePath,
      });
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw Exception('El número de teléfono ya está registrado');
      }
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error durante el registro: $e');
    }
  }
}
