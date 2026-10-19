// ignore_for_file: prefer_initializing_formals, use_null_aware_elements
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/user_roles.dart';

class RegistrationResult {
  final bool success;
  final bool requiresConfirmation;
  final String? userId;
  final String? message;

  const RegistrationResult({
    required this.success,
    this.requiresConfirmation = false,
    this.userId,
    this.message,
  });
}

typedef AuthSignUpInvoker = Future<AuthResponse> Function({
  required String email,
  required String password,
  Map<String, dynamic>? data,
});

typedef ProfileUpserter = Future<void> Function(Map<String, dynamic> profileData);

typedef VerificationAttemptSaver = Future<void> Function(
    Map<String, dynamic> attemptData);

typedef StorageUploader = Future<String> Function(
    String bucket, String path, File file);

class RegistrationService {
  final SupabaseClient? _clientOverride;
  final AuthSignUpInvoker? _signUpInvoker;
  final ProfileUpserter? _profileUpserter;
  final VerificationAttemptSaver? _verificationAttemptSaver;
  final StorageUploader? _storageUploader;

  RegistrationService({
    SupabaseClient? client,
    AuthSignUpInvoker? signUpInvoker,
    ProfileUpserter? profileUpserter,
    VerificationAttemptSaver? verificationAttemptSaver,
    StorageUploader? storageUploader,
  })  : _clientOverride = client,
        _signUpInvoker = signUpInvoker,
        _profileUpserter = profileUpserter,
        _verificationAttemptSaver = verificationAttemptSaver,
        _storageUploader = storageUploader;

  SupabaseClient get _client {
    final override = _clientOverride;
    if (override != null) return override;
    return Supabase.instance.client;
  }

  Future<RegistrationResult> registerUser({
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
    required String role,
    String? documentType,
    File? documentFront,
    File? documentBack,
    File? selfie,
  }) async {
    // 1. Validación de campos obligatorios
    if (phone.trim().isEmpty ||
        firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        password.isEmpty) {
      throw ArgumentError('Todos los campos obligatorios deben ser diligenciados.');
    }

    // 2. Validación de contraseña
    if (password.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }

    // 3. Validación y protección de rol: NUNCA permitir moderador ni auto-aprobación
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'moderador' || normalizedRole == 'moderator') {
      throw ArgumentError('No está permitido registrarse con el rol de moderador.');
    }
    if (normalizedRole != 'agricultor' && normalizedRole != 'comprador') {
      throw ArgumentError('Rol no permitido: $role. Debe ser agricultor o comprador.');
    }

    // 4. Normalización de contacto y correo sintético
    final cleanContact = phone.trim().replaceAll(RegExp(r'[\s\-()]+'), '');
    final isEmail = cleanContact.contains('@');
    if (!isEmail && cleanContact.length < 7) {
      throw ArgumentError('El número telefónico ingresado no es válido.');
    }
    final emailToUse = isEmail ? cleanContact : '$cleanContact@agromarket.com';

    try {
      // 5. Creación de cuenta en Supabase Auth
      final signUpInvoker = _signUpInvoker;
      final AuthResponse authRes = signUpInvoker != null
          ? await signUpInvoker(
              email: emailToUse,
              password: password,
              data: {
                'phone': cleanContact,
                'full_name': '$firstName $lastName'.trim(),
                'role': UserRole.toDb(normalizedRole),
              },
            )
          : await _client.auth.signUp(
              email: emailToUse,
              password: password,
              data: {
                'phone': cleanContact,
                'full_name': '$firstName $lastName'.trim(),
                'role': UserRole.toDb(normalizedRole),
              },
            );

      final user = authRes.user;
      if (user == null) {
        throw Exception('Error al registrar usuario en el servicio de autenticación.');
      }

      // 6. Verificar si se exige confirmación antes de iniciar sesión (sin sesión activa)
      if (authRes.session == null) {
        return RegistrationResult(
          success: true,
          requiresConfirmation: true,
          userId: user.id,
          message: 'Cuenta creada. Por favor confirma tu medio de contacto para iniciar sesión.',
        );
      }

      // 7. Subida de documentos (si fueron suministrados)
      String? frontPath;
      String? backPath;
      String? selfiePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (documentFront != null) {
        frontPath = '${user.id}/front_$timestamp.jpg';
        await _uploadFile('user_documents', frontPath, documentFront);
      }
      if (documentBack != null) {
        backPath = '${user.id}/back_$timestamp.jpg';
        await _uploadFile('user_documents', backPath, documentBack);
      }
      if (selfie != null) {
        selfiePath = '${user.id}/selfie_$timestamp.jpg';
        await _uploadFile('user_documents', selfiePath, selfie);
      }

      // 8. Inserción o actualización en profiles (Upsert para evitar duplicados ante reintentos)
      final profileData = {
        'id': user.id,
        'phone': cleanContact,
        'full_name': '$firstName $lastName'.trim(),
        'role': UserRole.toDb(normalizedRole),
        'verification_status': 'pendiente',
        if (isEmail) 'email': cleanContact,
      };

      final profileUpserter = _profileUpserter;
      if (profileUpserter != null) {
        await profileUpserter(profileData);
      } else {
        await _client.from('profiles').upsert(profileData);
      }

      // 9. Inserción en verification_attempts si se adjuntaron documentos
      if (frontPath != null || backPath != null || selfiePath != null) {
        final attemptData = {
          'user_id': user.id,
          'status': 'pendiente',
          if (frontPath != null) 'document_front_path': frontPath,
          if (backPath != null) 'document_back_path': backPath,
          if (selfiePath != null) 'selfie_path': selfiePath,
        };

        final attemptSaver = _verificationAttemptSaver;
        if (attemptSaver != null) {
          await attemptSaver(attemptData);
        } else {
          await _client.from('verification_attempts').insert(attemptData);
        }
      }

      return RegistrationResult(
        success: true,
        requiresConfirmation: false,
        userId: user.id,
        message: '¡Registro completado con éxito!',
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        throw Exception('El número de teléfono o correo ya se encuentra registrado.');
      }
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('ClientException') ||
          errStr.contains('Network') ||
          errStr.contains('TimeoutException') ||
          errStr.contains('Failed host lookup')) {
        throw Exception('Error de conexión. Verifica tu internet y vuelve a intentar.');
      }
      if (e is ArgumentError) {
        rethrow;
      }
      throw Exception('Error al procesar el registro: $e');
    }
  }

  Future<void> _uploadFile(String bucket, String path, File file) async {
    try {
      final storageUploader = _storageUploader;
      if (storageUploader != null) {
        await storageUploader(bucket, path, file);
      } else {
        await _client.storage.from(bucket).upload(path, file);
      }
    } catch (_) {
      // Advertencia no fatal para permitir continuar con el perfil si el storage falla
    }
  }
}
