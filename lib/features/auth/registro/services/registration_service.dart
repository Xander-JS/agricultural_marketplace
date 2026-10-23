// ignore_for_file: prefer_initializing_formals, use_null_aware_elements
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/utils/diagnostic_utils.dart';
import '../../../../core/utils/document_upload_utils.dart';
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

/// Error controlado del registro con un mensaje seguro para la UI y un detalle
/// sanitizado exclusivamente para depuración.
class RegistrationException implements Exception {
  final String message;
  final String stage;
  final String? debugReason;

  const RegistrationException(
    this.message, {
    required this.stage,
    this.debugReason,
  });

  @override
  String toString() => message;
}

typedef AuthSignUpInvoker = Future<AuthResponse> Function({
  required String email,
  required String password,
  Map<String, dynamic>? data,
});

typedef AuthSignInInvoker = Future<AuthResponse> Function({
  required String email,
  required String password,
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

typedef PendingAttemptFetcher = Future<Map<String, dynamic>?> Function(
  String userId,
);

/// Permite consultar la sesión activa sin acoplarse a `Supabase.instance` en
/// pruebas. En producción se usa la sesión real del cliente.
typedef AuthSessionProvider = Session? Function();

class RegistrationService {
  final SupabaseClient? _clientOverride;
  final AuthSignUpInvoker? _signUpInvoker;
  final AuthSignInInvoker? _signInInvoker;
  final ProfileUpserter? _profileUpserter;
  final VerificationAttemptSaver? _verificationAttemptSaver;
  final StorageUploader? _storageUploader;
  final PendingAttemptFetcher? _pendingAttemptFetcher;
  final AuthSessionProvider? _sessionProvider;
  final UploadRetryPolicy _uploadRetryPolicy;

  RegistrationService({
    SupabaseClient? client,
    AuthSignUpInvoker? signUpInvoker,
    AuthSignInInvoker? signInInvoker,
    ProfileUpserter? profileUpserter,
    VerificationAttemptSaver? verificationAttemptSaver,
    StorageUploader? storageUploader,
    PendingAttemptFetcher? pendingAttemptFetcher,
    AuthSessionProvider? sessionProvider,
    UploadRetryPolicy uploadRetryPolicy = UploadRetryPolicy.standard,
  }) : _clientOverride = client,
       _signUpInvoker = signUpInvoker,
       _signInInvoker = signInInvoker,
       _profileUpserter = profileUpserter,
       _verificationAttemptSaver = verificationAttemptSaver,
       _storageUploader = storageUploader,
       _pendingAttemptFetcher = pendingAttemptFetcher,
       _sessionProvider = sessionProvider,
       _uploadRetryPolicy = uploadRetryPolicy;

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
    final redact = <String?>[emailToUse, cleanContact];

    try {
      // 5. Reanudación idempotente.
      //
      // Si ya hay una sesión activa para esta misma cuenta (por ejemplo, el
      // primer intento creó Auth y falló al subir documentos), NO se vuelve a
      // llamar a signUp. Se reutiliza la identidad ya autenticada y se continúa
      // con perfil/documentos.
      final resumedSession = _resumableSession(emailToUse, cleanContact);
      User? user = resumedSession?.user;
      var hasSession = resumedSession != null;

      if (!hasSession) {
        // 5b. Creación de cuenta en Supabase Auth.
        final signUpInvoker = _signUpInvoker;
        AuthResponse authRes;
        try {
          authRes = signUpInvoker != null
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
        } on AuthException catch (error) {
          if (!_isAlreadyRegisteredError(error)) rethrow;

          final reason = describeException(
            error,
            stage: 'sign_up',
            redact: redact,
          );
          logAuthDiagnostic(
            'registration',
            '$reason; hint=resuming_existing_account',
          );
          authRes = AuthResponse();
        }

        user = authRes.user;
        hasSession = authRes.session != null;

        // 6. Si Supabase no devolvió sesión, intentar un inicio de sesión
        // inmediato. El proyecto desplegado puede exigir confirmación de correo
        // aunque el config.toml local tenga enable_confirmations = false.
        if (!hasSession) {
          final AuthResponse signInRes;
          try {
            final signInInvoker = _signInInvoker;
            signInRes = signInInvoker != null
                ? await signInInvoker(email: emailToUse, password: password)
                : await _client.auth.signInWithPassword(
                    email: emailToUse,
                    password: password,
                  );
          } on AuthException catch (error) {
            final reason = describeException(
              error,
              stage: 'resume_sign_in',
              redact: redact,
            );
            logAuthDiagnostic('registration', reason);

            if (_isContactConfirmationError(error)) {
              return RegistrationResult(
                success: true,
                requiresConfirmation: true,
                userId: user?.id,
                message: user == null
                    ? 'La cuenta ya existe, pero el registro aún no está completo. Confirma tu correo electrónico e inicia sesión para completar tu perfil y subir tus documentos.'
                    : 'Cuenta creada, pero el registro aún no está completo. Confirma tu correo electrónico e inicia sesión para completar tu perfil y subir tus documentos.',
              );
            }

            throw RegistrationException(
              user == null
                  ? 'La cuenta ya existe, pero no se pudo iniciar sesión automáticamente. Inicia sesión con tu contraseña para completar el registro.'
                  : 'La cuenta fue creada, pero no se pudo iniciar sesión automáticamente. Inicia sesión para completar el registro.',
              stage: 'resume_sign_in',
              debugReason: reason,
            );
          }

          if (signInRes.session == null) {
            // Sin sesión no se puede insertar el perfil: las RLS exigen
            // auth.uid().
            return RegistrationResult(
              success: true,
              requiresConfirmation: true,
              userId: user?.id ?? signInRes.user?.id,
              message: user == null
                  ? 'La cuenta ya existe, pero el registro aún no está completo. Inicia sesión para completar tu perfil y subir tus documentos.'
                  : 'Cuenta creada, pero el registro aún no está completo. Confirma tu correo electrónico e inicia sesión para completar tu perfil y subir tus documentos.',
            );
          }

          // En cuentas existentes Supabase puede devolver un usuario ofuscado
          // en signUp (sin sesión). La identidad válida es la que autenticó el
          // signIn; se usa esa para no intentar escribir un perfil ajeno.
          final authenticatedUser = signInRes.session?.user ?? signInRes.user;
          if (authenticatedUser != null) {
            user = authenticatedUser;
          }
          hasSession = true;
        }
      }

      if (!hasSession || user == null) {
        throw const RegistrationException(
          'No se pudo iniciar sesión para completar el registro. Inténtalo de nuevo.',
          stage: 'auth',
          debugReason: 'stage=auth; reason=missing_session_or_user',
        );
      }

      // La carpeta de Storage y la fila de profiles deben usar exactamente la
      // identidad de la sesión autenticada, no el usuario ofuscado que puede
      // devolver signUp cuando la cuenta ya existía.
      if (_sessionProvider == null &&
          _signUpInvoker == null &&
          _signInInvoker == null) {
        final sessionUserId = _client.auth.currentSession?.user.id;
        if (sessionUserId != null && sessionUserId != user.id) {
          throw const RegistrationException(
            'No se pudo verificar la sesión del registro. Inicia sesión nuevamente.',
            stage: 'session',
            debugReason: 'stage=session; reason=session_user_mismatch',
          );
        }
      }

      final authenticatedUserId = user.id;

      // 7. Inserción obligatoria e inmediata en public.profiles para asegurar la FK.
      // El trigger trg_protect_profiles_security_fields exige que el estado inicial
      // sea 'pendiente'. Cualquier otro valor provoca el error 42501.
      // El parámetro verificationStatus se ignora a propósito para mantener este invariante.
      const effectiveStatus = 'pendiente';

      final simLocation = GeoSimulationService.assignSimulatedLocation(
        seed: authenticatedUserId,
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
        'id': authenticatedUserId,
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
          // Ignorar duplicados evita que un reintento intente actualizar un perfil
          // existente (el rol authenticated no tiene UPDATE sobre rol/estado) y
          // garantiza que no se cree un segundo perfil para el mismo auth.uid().
          await _client
              .from('profiles')
              .upsert(profileData, onConflict: 'id', ignoreDuplicates: true);
        }
      } catch (profileError) {
        final reason = describeException(
          profileError,
          stage: 'profile_upsert',
          redact: [authenticatedUserId, ...redact],
        );
        logAuthDiagnostic('registration', reason);
        throw RegistrationException(
          'Error al procesar el registro: no se pudo guardar el perfil del usuario.',
          stage: 'profile',
          debugReason: reason,
        );
      }

      // 7b. Reanudación idempotente: si ya existe una solicitud pendiente
      // completa, no se vuelven a subir documentos ni se inserta un duplicado.
      if (documentFront != null && documentBack != null && selfie != null) {
        if (await _hasCompletePendingAttempt(authenticatedUserId)) {
          return RegistrationResult(
            success: true,
            requiresConfirmation: false,
            documentsUploaded: true,
            userId: authenticatedUserId,
            message: '¡Registro completado con éxito! Tu solicitud ya está en revisión.',
          );
        }
      }

      // 8. Subida de documentos requeridos
      String? frontPath;
      String? backPath;
      String? selfiePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      try {
        if (documentFront != null) {
          final path =
              '$authenticatedUserId/front_$timestamp.${documentFileExtension(documentFront.path)}';
          await _uploadFile(
            'user_documents',
            path,
            documentFront,
            stage: 'upload_front',
            userId: authenticatedUserId,
          );
          frontPath = path;
        }
        if (documentBack != null) {
          final path =
              '$authenticatedUserId/back_$timestamp.${documentFileExtension(documentBack.path)}';
          await _uploadFile(
            'user_documents',
            path,
            documentBack,
            stage: 'upload_back',
            userId: authenticatedUserId,
          );
          backPath = path;
        }
        if (selfie != null) {
          final path =
              '$authenticatedUserId/selfie_$timestamp.${documentFileExtension(selfie.path)}';
          await _uploadFile(
            'user_documents',
            path,
            selfie,
            stage: 'upload_selfie',
            userId: authenticatedUserId,
          );
          selfiePath = path;
        }
      } on RegistrationException {
        // Un reintento sube archivos nuevos: no se dejan cargas parciales de
        // documentos de identidad huérfanas en el bucket.
        await _removeUploaded('user_documents', [?frontPath, ?backPath]);
        rethrow;
      }

      // 9. Inserción en verification_attempts con estado 'pendiente'.
      // Restricciones del esquema que se deben respetar:
      //  - GRANT INSERT solo cubre: user_id, status, document_front_path, document_back_path, selfie_path
      //  - La política verification_attempts_insert_own exige status = 'pendiente' y ai_result IS NULL
      //  - El trigger protect_verification_attempts_security_fields bloquea cualquier valor distinto
      // Por ello NO se incluyen ai_result, created_at, ocr_result, face_match_result ni campos de revisión.
      if (frontPath != null && backPath != null && selfiePath != null) {
        final attemptData = {
          'user_id': authenticatedUserId,
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
        } catch (attemptError) {
          // El índice único uq_verification_attempts_pending_user impide duplicar
          // solicitudes pendientes. Un reintento que encuentra la solicitud ya
          // creada debe considerarse idempotente, no un fallo de registro.
          if (_isDuplicateAttemptError(attemptError)) {
            return RegistrationResult(
              success: true,
              requiresConfirmation: false,
              documentsUploaded: true,
              userId: authenticatedUserId,
              message: '¡Registro completado con éxito! Tu solicitud ya está en revisión.',
            );
          }
          final reason = describeException(
            attemptError,
            stage: 'attempt_insert',
            redact: [authenticatedUserId, ...redact],
          );
          logAuthDiagnostic('registration', reason);
          throw RegistrationException(
            'Error al procesar el registro: no se pudo crear la solicitud de verificación.',
            stage: 'attempt',
            debugReason: reason,
          );
        }
      }

      return RegistrationResult(
        success: true,
        requiresConfirmation: false,
        documentsUploaded:
            frontPath != null && backPath != null && selfiePath != null,
        userId: authenticatedUserId,
        message:
            '¡Registro completado con éxito! Tu solicitud está en revisión.',
      );
    } on RegistrationException {
      rethrow;
    } on AuthException catch (error) {
      final reason = describeException(error, stage: 'auth', redact: redact);
      logAuthDiagnostic('registration', reason);
      if (_isAlreadyRegisteredError(error)) {
        throw RegistrationException(
          'El número de teléfono o correo ya se encuentra registrado. Inicia sesión para completar tu registro.',
          stage: 'auth',
          debugReason: reason,
        );
      }
      throw RegistrationException(
        'Error de autenticación. Verifica tus datos e inténtalo de nuevo.',
        stage: 'auth',
        debugReason: reason,
      );
    } catch (error) {
      if (_isNetworkError(error)) {
        final reason = describeException(
          error,
          stage: 'network',
          redact: redact,
        );
        logAuthDiagnostic('registration', reason);
        throw RegistrationException(
          'Error de conexión. Verifica tu internet y vuelve a intentar.',
          stage: 'network',
          debugReason: reason,
        );
      }
      if (error is ArgumentError) {
        rethrow;
      }
      final reason = describeException(
        error,
        stage: 'unexpected',
        redact: redact,
      );
      logAuthDiagnostic('registration', reason);
      throw RegistrationException(
        'Error al procesar el registro. Inténtalo de nuevo.',
        stage: 'unexpected',
        debugReason: reason,
      );
    }
  }

  /// Devuelve la sesión activa solo si pertenece a la misma cuenta que se está
  /// registrando. Así un reintento reanuda el registro sin volver a llamar a
  /// `signUp`, pero nunca escribe documentos en la carpeta de otro usuario.
  Session? _resumableSession(String emailToUse, String cleanContact) {
    final provider = _sessionProvider;
    final Session? session;
    if (provider != null) {
      session = provider();
    } else {
      // Con dependencias de Auth inyectadas (pruebas) no se consulta la sesión
      // global, salvo que se haya inyectado explícitamente un proveedor.
      if (_signUpInvoker != null || _signInInvoker != null) return null;
      try {
        session = _client.auth.currentSession;
      } catch (_) {
        return null;
      }
    }

    if (session == null) return null;

    final normalizedEmail = emailToUse.trim().toLowerCase();
    final sessionEmail = session.user.email?.trim().toLowerCase();
    if (sessionEmail != null &&
        sessionEmail.isNotEmpty &&
        sessionEmail == normalizedEmail) {
      return session;
    }

    final metadataPhone = session.user.userMetadata?['phone']?.toString();
    if (metadataPhone != null) {
      final normalizedPhone = metadataPhone.trim().replaceAll(
        RegExp(r'[\s\-()]+'),
        '',
      );
      if (normalizedPhone == cleanContact) return session;
    }

    return null;
  }

  bool _isContactConfirmationError(AuthException error) {
    final message = error.message.toLowerCase();
    final code = (error.code ?? '').toLowerCase();
    return message.contains('not confirmed') ||
        message.contains('email not confirmed') ||
        message.contains('phone not confirmed') ||
        message.contains('confirmation') ||
        code == 'email_not_confirmed' ||
        code == 'phone_not_confirmed';
  }

  bool _isAlreadyRegisteredError(AuthException error) {
    final message = error.message.toLowerCase();
    final code = (error.code ?? '').toLowerCase();
    return message.contains('already registered') ||
        message.contains('already exists') ||
        code == 'user_already_exists' ||
        code == 'email_exists' ||
        code == 'phone_exists';
  }

  bool _isDuplicateAttemptError(Object error) {
    if (error is PostgrestException && error.code == '23505') return true;
    final description = error.toString().toLowerCase();
    return description.contains('23505') ||
        description.contains('duplicate key');
  }

  bool _isNetworkError(Object error) {
    if (error is SocketException || error is HttpException) return true;
    if (error is TimeoutException) return true;
    final description = error.toString().toLowerCase();
    return description.contains('socketexception') ||
        description.contains('clientexception') ||
        description.contains('network') ||
        description.contains('timeoutexception') ||
        description.contains('failed host lookup');
  }

  /// Consulta de mejor esfuerzo para evitar volver a subir documentos cuando ya
  /// existe una solicitud pendiente completa. Un fallo de consulta no bloquea el
  /// registro: el índice único de la base de datos sigue siendo la garantía.
  Future<bool> _hasCompletePendingAttempt(String userId) async {
    try {
      Map<String, dynamic>? attempt;
      final fetcher = _pendingAttemptFetcher;
      if (fetcher != null) {
        attempt = await fetcher(userId);
      } else {
        if (_verificationAttemptSaver != null || _storageUploader != null) {
          return false;
        }
        attempt = await _client
            .from('verification_attempts')
            .select('document_front_path, document_back_path, selfie_path')
            .eq('user_id', userId)
            .inFilter('status', ['pendiente', 'en_revision_ia'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      }

      if (attempt == null) return false;
      return [
        attempt['document_front_path'],
        attempt['document_back_path'],
        attempt['selfie_path'],
      ].every((path) => path is String && path.trim().isNotEmpty);
    } catch (error) {
      logAuthDiagnostic(
        'registration',
        describeException(error, stage: 'pending_lookup', redact: [userId]),
      );
      return false;
    }
  }

  /// Limpieza de mejor esfuerzo; con un uploader inyectado (pruebas) no se
  /// toca el almacenamiento real.
  Future<void> _removeUploaded(String bucket, List<String> paths) async {
    if (paths.isEmpty || _storageUploader != null) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {}
  }

  Future<void> _uploadFile(
    String bucket,
    String path,
    File file, {
    required String stage,
    required String userId,
  }) async {
    final uploader = _storageUploader;

    // Con el almacenamiento real se leen los bytes antes de subir: se valida
    // que el archivo siga disponible y la carga ya no depende de él. Con un
    // uploader inyectado (pruebas) se respeta el doble sin tocar el disco.
    Uint8List? bytes;
    if (uploader == null) {
      try {
        if (!file.existsSync() || file.lengthSync() <= 0) {
          throw RegistrationException(
            'Error al procesar el registro: uno de los documentos no está disponible. Vuelve a seleccionarlo.',
            stage: stage,
            debugReason: 'stage=$stage; reason=file_missing_or_empty',
          );
        }
        bytes = await file.readAsBytes();
      } on RegistrationException {
        rethrow;
      } on FileSystemException catch (error) {
        throw RegistrationException(
          'Error al procesar el registro: uno de los documentos no está disponible. Vuelve a seleccionarlo.',
          stage: stage,
          debugReason: describeException(error, stage: stage, redact: [userId]),
        );
      }
    }

    try {
      await uploadWithRetry(() async {
        if (uploader != null) {
          await uploader(bucket, path, file);
        } else {
          await _client.storage
              .from(bucket)
              .uploadBinary(
                path,
                bytes!,
                fileOptions: documentUploadFileOptions(file.path),
              );
        }
      }, policy: _uploadRetryPolicy);
    } on RegistrationException {
      rethrow;
    } catch (error) {
      final reason = describeException(error, stage: stage, redact: [userId]);
      logAuthDiagnostic('registration', reason);
      throw RegistrationException(
        'Error al procesar el registro: no se pudo cargar uno de los documentos. Inténtalo de nuevo.',
        stage: stage,
        debugReason: reason,
      );
    }
  }
}
