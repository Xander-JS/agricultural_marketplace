// ignore_for_file: prefer_initializing_formals, use_null_aware_elements
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../geo/services/geo_simulation_service.dart';

class RegistrationResult {
  final bool success;
  final bool requiresConfirmation;
  final bool documentsUploaded;
  final String? userId;
  final String? message;

  const RegistrationResult({
    required this.success,
    this.requiresConfirmation = false,
    this.documentsUploaded = true,
    this.userId,
    this.message,
  });
}

typedef AuthSignUpInvoker = Future<AuthResponse> Function({
  required String email,
  required String password,
  Map<String, dynamic>? data,
});

typedef ProfileUpserter = Future<void> Function(
  Map<String, dynamic> profileData,
);

typedef VerificationAttemptSaver = Future<void> Function(
  Map<String, dynamic> attemptData,
);

typedef StorageUploader = Future<String> Function(
  String bucket,
  String path,
  File file,
);

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
  }) : _clientOverride = client,
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
    String? department,
    String? municipality,
    double? latitude,
    double? longitude,
    String? verificationStatus,
  }) async {
    // 1. Validación de campos obligatorios
    if (phone.trim().isEmpty ||
        firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        password.isEmpty) {
      throw ArgumentError(
        'Todos los campos obligatorios deben ser diligenciados.',
      );
    }

    // 2. Validación de contraseña
    if (password.length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }

    // 3. Validación y protección de rol: NUNCA permitir moderador ni auto-aprobación
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'moderador' || normalizedRole == 'moderator') {
      throw ArgumentError(
        'No está permitido registrarse con el rol de moderador.',
      );
    }
    if (normalizedRole != 'agricultor' && normalizedRole != 'comprador') {
      throw ArgumentError(
        'Rol no permitido: $role. Debe ser agricultor o comprador.',
      );
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
        throw Exception(
          'Error al registrar usuario en el servicio de autenticación.',
        );
      }

      // 6. Verificar si se exige confirmación antes de iniciar sesión (sin sesión activa).
      // Supabase puede devolver session == null cuando enable_confirmations = false pero la
      // sesión aún no se propagó. Se intenta un signIn inmediato para recuperarla.
      if (authRes.session == null) {
        try {
          final signInRes = await _client.auth.signInWithPassword(
            email: emailToUse,
            password: password,
          );
          if (signInRes.session == null) {
            // Confirmación realmente requerida: informar al usuario sin guardar perfil
            // bajo rol anon (las RLS de profiles exigen sesión autenticada).
            return RegistrationResult(
              success: true,
              requiresConfirmation: true,
              userId: user.id,
              message: 'Cuenta creada. Por favor confirma tu medio de contacto para iniciar sesión.',
            );
          }
        } catch (_) {
          // Si el signIn falla (cuenta aún no confirmada), devolver requiresConfirmation.
          return RegistrationResult(
            success: true,
            requiresConfirmation: true,
            userId: user.id,
            message: 'Cuenta creada. Por favor confirma tu medio de contacto para iniciar sesión.',
          );
        }
      }

      // 7. Inserción obligatoria e inmediata en public.profiles para asegurar la FK.
      // El trigger trg_protect_profiles_security_fields exige que el estado inicial
      // sea 'pendiente'. Cualquier otro valor provoca el error 42501.
      // El parámetro verificationStatus se ignora a propósito para mantener este invariante.
      const effectiveStatus = 'pendiente';

      final simLocation = GeoSimulationService.assignSimulatedLocation(
        seed: user.id,
        municipality: municipality,
        department: department,
      );

      final finalDepartment = department?.trim().isNotEmpty == true
          ? department!.trim()
          : simLocation.department;
      final finalMunicipality = municipality?.trim().isNotEmpty == true
          ? municipality!.trim()
          : simLocation.municipality;
      final finalLatitude = GeoUtils.isValidCoordinate(latitude, longitude)
          ? latitude!
          : simLocation.latitude;
      final finalLongitude = GeoUtils.isValidCoordinate(latitude, longitude)
          ? longitude!
          : simLocation.longitude;

      final profileData = {
        'id': user.id,
        'phone': cleanContact,
        'full_name': '$firstName $lastName'.trim(),
        'role': UserRole.toDb(normalizedRole),
        'verification_status': effectiveStatus,
        if (isEmail) 'email': cleanContact,
        'department': finalDepartment,
        'municipality': finalMunicipality,
        'latitude': finalLatitude,
        'longitude': finalLongitude,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        final profileUpserter = _profileUpserter;
        if (profileUpserter != null) {
          await profileUpserter(profileData);
        } else {
          await _client.from('profiles').upsert(profileData);
        }
      } catch (profileErr) {
        throw Exception(
          'Error al registrar el perfil de usuario en base de datos: $profileErr',
        );
      }

      // 8. Subida de documentos requeridos
      String? frontPath;
      String? backPath;
      String? selfiePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (documentFront != null) {
        final path = '${user.id}/front_$timestamp.jpg';
        if (await _uploadFile('user_documents', path, documentFront)) {
          frontPath = path;
        } else {
          throw Exception('Error al subir la imagen frontal del documento de identidad.');
        }
      }
      if (documentBack != null) {
        final path = '${user.id}/back_$timestamp.jpg';
        if (await _uploadFile('user_documents', path, documentBack)) {
          backPath = path;
        } else {
          throw Exception('Error al subir la imagen posterior del documento de identidad.');
        }
      }
      if (selfie != null) {
        final path = '${user.id}/selfie_$timestamp.jpg';
        if (await _uploadFile('user_documents', path, selfie)) {
          selfiePath = path;
        } else {
          throw Exception('Error al subir la fotografía facial (selfie).');
        }
      }

      // 9. Inserción en verification_attempts con estado 'pendiente'.
      // Restricciones del esquema que se deben respetar:
      //  - GRANT INSERT solo cubre: user_id, status, document_front_path, document_back_path, selfie_path
      //  - La política verification_attempts_insert_own exige status = 'pendiente' y ai_result IS NULL
      //  - El trigger protect_verification_attempts_security_fields bloquea cualquier valor distinto
      // Por ello NO se incluyen ai_result, created_at, ocr_result, face_match_result ni campos de revisión.
      if (frontPath != null && backPath != null && selfiePath != null) {
        final attemptData = {
          'user_id': user.id,
          'status': 'pendiente',
          'document_front_path': frontPath,
          'document_back_path': backPath,
          'selfie_path': selfiePath,
        };

        try {
          final attemptSaver = _verificationAttemptSaver;
          if (attemptSaver != null) {
            await attemptSaver(attemptData);
          } else {
            await _client.from('verification_attempts').insert(attemptData);
          }
        } catch (attemptErr) {
          throw Exception(
            'Error al registrar la solicitud en verificación y moderación: $attemptErr',
          );
        }
      }

      return RegistrationResult(
        success: true,
        requiresConfirmation: false,
        documentsUploaded:
            frontPath != null &&
            backPath != null &&
            selfiePath != null,
        userId: user.id,
        message: '¡Registro completado con éxito! Tu solicitud está en revisión.',
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        throw Exception(
          'El número de teléfono o correo ya se encuentra registrado.',
        );
      }
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('ClientException') ||
          errStr.contains('Network') ||
          errStr.contains('TimeoutException') ||
          errStr.contains('Failed host lookup')) {
        throw Exception(
          'Error de conexión. Verifica tu internet y vuelve a intentar.',
        );
      }
      if (e is ArgumentError) {
        rethrow;
      }
      throw Exception('Error al procesar el registro: $e');
    }
  }

  Future<bool> _uploadFile(String bucket, String path, File file) async {
    try {
      final storageUploader = _storageUploader;
      if (storageUploader != null) {
        await storageUploader(bucket, path, file);
      } else {
        await _client.storage.from(bucket).upload(path, file);
      }
      return true;
    } catch (_) {
      // No se registra la ruta ni el contenido. La pantalla de estado permitirá
      // reintentar la carga sin eliminar documentos existentes.
      return false;
    }
  }
}
