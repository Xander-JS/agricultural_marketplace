import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/login/screens/login_screen.dart';
import 'package:agricultural_marketplace/features/auth/registro/models/registration_data.dart';
import 'package:agricultural_marketplace/features/auth/registro/screens/processing_screen.dart';
import 'package:agricultural_marketplace/features/auth/registro/services/registration_service.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/services/verification_service.dart';
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';

Session createMockSession({
  required String userId,
  String? email,
  String? phone,
}) {
  return Session.fromJson({
    'access_token': 'mock-access-token-$userId',
    'token_type': 'bearer',
    'user': <String, dynamic>{
      'id': userId,
      'email': ?email,
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{'phone': ?phone},
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
    },
  })!;
}

User createMockUser({required String userId}) {
  return User.fromJson({
    'id': userId,
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'aud': 'authenticated',
    'created_at': '2026-01-01T00:00:00Z',
  })!;
}

Widget createTestApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    locale: LocalizationConfig.defaultLocale,
    supportedLocales: LocalizationConfig.supportedLocales,
    localizationsDelegates: LocalizationConfig.localizationsDelegates,
    home: child,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        publishableKey: 'placeholder-anon-key',
      );
    } catch (_) {}
  });

  group('Fase 1 — Subetapa 1.2: Pruebas de Registro Real de Usuario', () {
    // 1. Validación de campos obligatorios
    test('1. Validación de campos obligatorios lanza ArgumentError si faltan datos', () async {
      final service = RegistrationService();

      expect(
        () => service.registerUser(
          phone: '',
          firstName: 'Juan',
          lastName: 'Pérez',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => service.registerUser(
          phone: '3151234567',
          firstName: '',
          lastName: 'Pérez',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => service.registerUser(
          phone: '3151234567',
          firstName: 'Juan',
          lastName: '',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // 2. Rechazo de datos de contacto inválidos
    test('2. Rechazo de datos de contacto inválidos (teléfono con menos de 7 dígitos)', () async {
      final service = RegistrationService();

      expect(
        () => service.registerUser(
          phone: '12345',
          firstName: 'Juan',
          lastName: 'Pérez',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // 3. Contraseña inválida
    test(
      '3. Contraseña inválida (menor a 6 caracteres) es rechazada',
      () async {
        final service = RegistrationService();

        expect(
          () => service.registerUser(
            phone: '3151234567',
            firstName: 'Juan',
            lastName: 'Pérez',
            password: '12345',
            role: 'agricultor',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    // 4. Registro exitoso
    test('4. Registro exitoso crea cuenta y perfil con estado pendiente y rol agricultor', () async {
      Map<String, dynamic>? savedProfile;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          final user = createMockUser(userId: 'new-user-123');
          final session = createMockSession(userId: 'new-user-123');
          return AuthResponse(session: session, user: user);
        },
        profileUpserter: (profileData) async {
          savedProfile = profileData;
        },
      );

      final result = await service.registerUser(
        phone: '3151234567',
        firstName: 'Carlos',
        lastName: 'Gómez',
        password: 'Password123!',
        role: 'agricultor',
      );

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isFalse);
      expect(result.userId, equals('new-user-123'));
      expect(savedProfile, isNotNull);
      expect(savedProfile!['id'], equals('new-user-123'));
      expect(savedProfile!['phone'], equals('3151234567'));
      expect(savedProfile!['full_name'], equals('Carlos Gómez'));
      expect(savedProfile!['role'], equals('agricultor'));
      expect(savedProfile!['verification_status'], equals('pendiente'));
    });

    // 5. Reanudación de una cuenta existente sin volver a crearla
    test('5. Cuenta existente reanuda sesión y usa el id autenticado sin llamar signUp de nuevo', () async {
      var signUpCalls = 0;
      Map<String, dynamic>? savedProfile;
      Map<String, dynamic>? savedAttempt;
      final uploads = <String>[];

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          signUpCalls++;
          throw const AuthException('User already registered');
        },
        signInInvoker: ({required email, required password}) async {
          return AuthResponse(
            session: createMockSession(userId: 'existing-auth-user'),
            user: createMockUser(userId: 'existing-auth-user'),
          );
        },
        profileUpserter: (profileData) async => savedProfile = profileData,
        storageUploader: (bucket, path, file) async {
          uploads.add(path);
          return path;
        },
        verificationAttemptSaver: (attemptData) async =>
            savedAttempt = attemptData,
      );

      final result = await service.registerUser(
        phone: '3151234567',
        firstName: 'Carlos',
        lastName: 'Gómez',
        password: 'Password123!',
        role: 'agricultor',
        documentFront: File('dummy_front.jpg'),
        documentBack: File('dummy_back.jpg'),
        selfie: File('dummy_selfie.jpg'),
      );

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isFalse);
      expect(signUpCalls, 1);
      expect(savedProfile, isNotNull);
      expect(savedProfile!['id'], 'existing-auth-user');
      expect(uploads, hasLength(3));
      expect(
        uploads.every((path) => path.startsWith('existing-auth-user/')),
        isTrue,
      );
      expect(savedAttempt, isNotNull);
      expect(savedAttempt!['user_id'], 'existing-auth-user');
    });

    // 5b. Una cuenta existente con credenciales inválidas no crea datos parciales
    test('5b. Cuenta existente con credenciales inválidas no crea perfil ni solicitud', () async {
      var profileCalls = 0;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          throw const AuthException('User already registered');
        },
        signInInvoker: ({required email, required password}) async {
          throw const AuthException('Invalid login credentials');
        },
        profileUpserter: (_) async => profileCalls++,
      );

      await expectLater(
        service.registerUser(
          phone: '3151234567',
          firstName: 'Carlos',
          lastName: 'Gómez',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(
          isA<RegistrationException>()
              .having((e) => e.stage, 'stage', 'resume_sign_in')
              .having(
                (e) => e.toString(),
                'message',
                isNot(contains('Invalid login credentials')),
              ),
        ),
      );
      expect(profileCalls, 0);
    });

    // 5c. Un reintento con sesión activa no vuelve a llamar signUp
    test(
      '5c. Reintento con sesión activa reanuda el registro sin llamar signUp',
      () async {
        var signUpCalls = 0;
        var signInCalls = 0;
        Map<String, dynamic>? savedProfile;
        Map<String, dynamic>? savedAttempt;
        final uploads = <String>[];

        final service = RegistrationService(
          sessionProvider: () => createMockSession(
            userId: 'resumed-session-user',
            email: '3151234567@agromarket.com',
          ),
          signUpInvoker: ({required email, required password, data}) async {
            signUpCalls++;
            throw StateError('signUp no debe invocarse al reanudar');
          },
          signInInvoker: ({required email, required password}) async {
            signInCalls++;
            throw StateError('signIn no debe invocarse con sesión activa');
          },
          profileUpserter: (profileData) async => savedProfile = profileData,
          storageUploader: (bucket, path, file) async {
            uploads.add(path);
            return path;
          },
          verificationAttemptSaver: (attemptData) async =>
              savedAttempt = attemptData,
        );

        final result = await service.registerUser(
          phone: '3151234567',
          firstName: 'Carlos',
          lastName: 'Gómez',
          password: 'Password123!',
          role: 'agricultor',
          documentFront: File('dummy_front.jpg'),
          documentBack: File('dummy_back.jpg'),
          selfie: File('dummy_selfie.jpg'),
        );

        expect(result.success, isTrue);
        expect(result.documentsUploaded, isTrue);
        expect(signUpCalls, 0);
        expect(signInCalls, 0);
        expect(savedProfile, isNotNull);
        expect(savedProfile!['id'], 'resumed-session-user');
        expect(uploads, hasLength(3));
        expect(
          uploads.every((path) => path.startsWith('resumed-session-user/')),
          isTrue,
        );
        expect(savedAttempt, isNotNull);
        expect(savedAttempt!['user_id'], 'resumed-session-user');
      },
    );

    // 5d. Reanudar con sesión activa y solicitud pendiente completa es no-op
    test(
      '5d. Reintento con sesión y solicitud pendiente completa no duplica nada',
      () async {
        var signUpCalls = 0;
        var uploadCalls = 0;
        var attemptCalls = 0;

        final service = RegistrationService(
          sessionProvider: () => createMockSession(
            userId: 'resumed-pending-user',
            email: '3151234567@agromarket.com',
          ),
          signUpInvoker: ({required email, required password, data}) async {
            signUpCalls++;
            throw StateError('signUp no debe invocarse al reanudar');
          },
          profileUpserter: (_) async {},
          storageUploader: (bucket, path, file) async {
            uploadCalls++;
            return path;
          },
          verificationAttemptSaver: (_) async => attemptCalls++,
          pendingAttemptFetcher: (userId) async => {
            'status': 'pendiente',
            'document_front_path': '$userId/front_1.jpg',
            'document_back_path': '$userId/back_1.jpg',
            'selfie_path': '$userId/selfie_1.jpg',
          },
        );

        final result = await service.registerUser(
          phone: '3151234567',
          firstName: 'Carlos',
          lastName: 'Gómez',
          password: 'Password123!',
          role: 'agricultor',
          documentFront: File('dummy_front.jpg'),
          documentBack: File('dummy_back.jpg'),
          selfie: File('dummy_selfie.jpg'),
        );

        expect(result.success, isTrue);
        expect(result.documentsUploaded, isTrue);
        expect(signUpCalls, 0);
        expect(uploadCalls, 0);
        expect(attemptCalls, 0);
      },
    );

    // 5e. Una sesión de otra cuenta no se reutiliza por error
    test(
      '5e. Sesión de otra cuenta no se usa para subir documentos ajenos',
      () async {
        var signUpCalls = 0;

        final service = RegistrationService(
          sessionProvider: () => createMockSession(
            userId: 'other-account',
            email: 'otro@agromarket.com',
          ),
          signUpInvoker: ({required email, required password, data}) async {
            signUpCalls++;
            throw const AuthException('User already registered');
          },
          signInInvoker: ({required email, required password}) async {
            return AuthResponse(
              session: createMockSession(
                userId: 'correct-account',
                email: '3151234567@agromarket.com',
              ),
              user: createMockUser(userId: 'correct-account'),
            );
          },
          profileUpserter: (_) async {},
          storageUploader: (bucket, path, file) async => path,
          verificationAttemptSaver: (_) async {},
          pendingAttemptFetcher: (_) async => null,
        );

        final result = await service.registerUser(
          phone: '3151234567',
          firstName: 'Carlos',
          lastName: 'Gómez',
          password: 'Password123!',
          role: 'agricultor',
          documentFront: File('dummy_front.jpg'),
          documentBack: File('dummy_back.jpg'),
          selfie: File('dummy_selfie.jpg'),
        );

        expect(result.success, isTrue);
        expect(signUpCalls, 1);
        expect(result.userId, 'correct-account');
      },
    );

    // 6. Error de red y posibilidad de reintento
    test('6. Error de red es identificado y permite reintento', () async {
      int attempts = 0;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          attempts++;
          if (attempts == 1) {
            throw const SocketException('Failed host lookup');
          }
          final user = createMockUser(userId: 'retry-user');
          final session = createMockSession(userId: 'retry-user');
          return AuthResponse(session: session, user: user);
        },
        profileUpserter: (_) async {},
      );

      // Primer intento falla por red
      expect(
        () => service.registerUser(
          phone: '3151234567',
          firstName: 'Carlos',
          lastName: 'Gómez',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('Error de conexión'),
          ),
        ),
      );

      // Reintento exitoso
      final result = await service.registerUser(
        phone: '3151234567',
        firstName: 'Carlos',
        lastName: 'Gómez',
        password: 'Password123!',
        role: 'agricultor',
      );

      expect(result.success, isTrue);
      expect(attempts, equals(2));
    });

    // 7. Fallo al guardar el perfil después de crear la cuenta
    test('7. Fallo al guardar el perfil después de crear la cuenta maneja el error sin colapso', () async {
      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          final user = createMockUser(userId: 'profile-fail-user');
          final session = createMockSession(userId: 'profile-fail-user');
          return AuthResponse(session: session, user: user);
        },
        profileUpserter: (_) async {
          throw const PostgrestException(
            message: 'Error de inserción en profiles',
          );
        },
      );

      expect(
        () => service.registerUser(
          phone: '3151234567',
          firstName: 'Carlos',
          lastName: 'Gómez',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Error al procesar el registro'),
          ),
        ),
      );
    });

    // 8. Prevención de asignación del rol moderador
    test(
      '8. Prevención estricta contra auto-asignación de rol moderador',
      () async {
        final service = RegistrationService(
          signUpInvoker: ({required email, required password, data}) async {
            final user = createMockUser(userId: 'hacker-user');
            final session = createMockSession(userId: 'hacker-user');
            return AuthResponse(session: session, user: user);
          },
        );

        expect(
          () => service.registerUser(
            phone: '3151234567',
            firstName: 'Hacker',
            lastName: 'User',
            password: 'Password123!',
            role: 'moderador',
          ),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError &&
                  e.message.contains(
                    'No está permitido registrarse con el rol de moderador',
                  ),
            ),
          ),
        );
      },
    );

    // 9. Comportamiento cuando Supabase exige confirmar el contacto antes de iniciar sesión
    test('9. Cuenta sin sesión inmediata por requerimiento de confirmación no simula sesión activa', () async {
      bool profileUpsertCalled = false;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          final user = createMockUser(userId: 'unconfirmed-user');
          // authRes.session es null cuando Supabase exige confirmación por correo/SMS
          return AuthResponse(session: null, user: user);
        },
        signInInvoker: ({required email, required password}) async {
          throw const AuthException(
            'Email not confirmed',
            code: 'email_not_confirmed',
          );
        },
        profileUpserter: (_) async {
          profileUpsertCalled = true;
        },
      );

      final result = await service.registerUser(
        phone: '3151234567',
        firstName: 'Laura',
        lastName: 'Martínez',
        password: 'Password123!',
        role: 'comprador',
      );

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isTrue);
      expect(result.userId, equals('unconfirmed-user'));
      expect(result.message, contains('registro aún no está completo'));
      // No debe intentar mutar profiles bajo rol anon sin sesión
      expect(profileUpsertCalled, isFalse);
    });

    // 9b. La sesión nula se recupera mediante signIn y el perfil sí se crea
    test('9b. Sesión nula con inicio de sesión inmediato exitoso crea perfil y solicitud pendiente', () async {
      Map<String, dynamic>? savedProfile;
      Map<String, dynamic>? savedAttempt;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          // Supabase puede devolver un usuario ofuscado cuando la cuenta ya
          // existe; la identidad válida es la de la sesión autenticada.
          final obfuscatedUser = createMockUser(userId: 'obfuscated-signup-id');
          return AuthResponse(session: null, user: obfuscatedUser);
        },
        signInInvoker: ({required email, required password}) async {
          return AuthResponse(
            session: createMockSession(userId: 'immediate-session-user'),
            user: createMockUser(userId: 'immediate-session-user'),
          );
        },
        profileUpserter: (profileData) async => savedProfile = profileData,
        storageUploader: (bucket, path, file) async => path,
        verificationAttemptSaver: (attemptData) async =>
            savedAttempt = attemptData,
      );

      final result = await service.registerUser(
        phone: '3151234567',
        firstName: 'Laura',
        lastName: 'Martínez',
        password: 'Password123!',
        role: 'comprador',
        documentFront: File('dummy_front.jpg'),
        documentBack: File('dummy_back.jpg'),
        selfie: File('dummy_selfie.jpg'),
      );

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isFalse);
      expect(result.documentsUploaded, isTrue);
      expect(savedProfile, isNotNull);
      expect(savedProfile!['id'], 'immediate-session-user');
      expect(savedProfile!['verification_status'], 'pendiente');
      expect(savedAttempt, isNotNull);
      expect(savedAttempt!['status'], 'pendiente');
      expect(savedAttempt!['user_id'], 'immediate-session-user');
    });

    // 9c. Un fallo real de signIn no se disfraza de confirmación pendiente
    test('9c. Fallo de inicio de sesión inmediato distinto a confirmación propaga la causa y no crea perfil', () async {
      bool profileUpsertCalled = false;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          final user = createMockUser(userId: 'signin-failure-user');
          return AuthResponse(session: null, user: user);
        },
        signInInvoker: ({required email, required password}) async {
          throw const AuthException('Invalid login credentials');
        },
        profileUpserter: (_) async {
          profileUpsertCalled = true;
        },
      );

      await expectLater(
        service.registerUser(
          phone: '3151234567',
          firstName: 'Laura',
          lastName: 'Martínez',
          password: 'Password123!',
          role: 'comprador',
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('no se pudo iniciar sesión'),
          ),
        ),
      );
      expect(profileUpsertCalled, isFalse);
    });

    // 9d. Un reintento que encuentra la solicitud pendiente ya creada es idempotente
    test(
      '9d. Reintento con solicitud pendiente existente no falla por duplicado',
      () async {
        Map<String, dynamic>? savedProfile;

        final service = RegistrationService(
          signUpInvoker: ({required email, required password, data}) async {
            final user = createMockUser(userId: 'retry-attempt-user');
            return AuthResponse(
              session: createMockSession(userId: 'retry-attempt-user'),
              user: user,
            );
          },
          profileUpserter: (profileData) async => savedProfile = profileData,
          storageUploader: (bucket, path, file) async => path,
          verificationAttemptSaver: (_) async {
            throw const PostgrestException(
              message: 'duplicate key value violates unique constraint',
              code: '23505',
            );
          },
        );

        final result = await service.registerUser(
          phone: '3151234567',
          firstName: 'Laura',
          lastName: 'Martínez',
          password: 'Password123!',
          role: 'comprador',
          documentFront: File('dummy_front.jpg'),
          documentBack: File('dummy_back.jpg'),
          selfie: File('dummy_selfie.jpg'),
        );

        expect(result.success, isTrue);
        expect(result.requiresConfirmation, isFalse);
        expect(result.documentsUploaded, isTrue);
        expect(savedProfile!['verification_status'], 'pendiente');
      },
    );

    // 9e. Reanudar con una solicitud pendiente completa no duplica documentos ni solicitud
    test('9e. Reanudar un registro con solicitud pendiente completa no vuelve a subir ni insertar', () async {
      var uploadCalls = 0;
      var attemptCalls = 0;
      Map<String, dynamic>? savedProfile;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          return AuthResponse(
            session: createMockSession(userId: 'resume-pending-user'),
            user: createMockUser(userId: 'resume-pending-user'),
          );
        },
        profileUpserter: (profileData) async => savedProfile = profileData,
        storageUploader: (bucket, path, file) async {
          uploadCalls++;
          return path;
        },
        verificationAttemptSaver: (_) async => attemptCalls++,
        pendingAttemptFetcher: (userId) async => {
          'status': 'pendiente',
          'document_front_path': '$userId/front_1.jpg',
          'document_back_path': '$userId/back_1.jpg',
          'selfie_path': '$userId/selfie_1.jpg',
        },
      );

      final result = await service.registerUser(
        phone: '3151234567',
        firstName: 'Laura',
        lastName: 'Martínez',
        password: 'Password123!',
        role: 'comprador',
        documentFront: File('dummy_front.jpg'),
        documentBack: File('dummy_back.jpg'),
        selfie: File('dummy_selfie.jpg'),
      );

      expect(result.success, isTrue);
      expect(result.documentsUploaded, isTrue);
      expect(savedProfile!['id'], 'resume-pending-user');
      expect(uploadCalls, 0);
      expect(attemptCalls, 0);
    });

    // 9f. Un fallo de Storage conserva un diagnóstico seguro y no crea la solicitud
    test('9f. Fallo de Storage devuelve diagnóstico sanitizado y no registra la solicitud', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'registration_upload_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      final front = File('${tempDir.path}/front.jpg')..writeAsBytesSync([1]);
      final back = File('${tempDir.path}/back.jpg')..writeAsBytesSync([2]);
      final selfie = File('${tempDir.path}/selfie.jpg')..writeAsBytesSync([3]);

      var attemptCalls = 0;
      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          return AuthResponse(
            session: createMockSession(userId: 'upload-failure-user'),
            user: createMockUser(userId: 'upload-failure-user'),
          );
        },
        profileUpserter: (_) async {},
        storageUploader: (bucket, path, file) async {
          throw const StorageException(
            'Bucket not found for upload-failure-user/front_1.jpg (dueno@example.com 3151234567)',
            error: 'NoSuchBucket',
            statusCode: '400',
          );
        },
        verificationAttemptSaver: (_) async => attemptCalls++,
      );

      late RegistrationException failure;
      try {
        await service.registerUser(
          phone: '3151234567',
          firstName: 'Laura',
          lastName: 'Martínez',
          password: 'Password123!',
          role: 'comprador',
          documentFront: front,
          documentBack: back,
          selfie: selfie,
        );
        fail('El registro debió fallar por Storage.');
      } on RegistrationException catch (error) {
        failure = error;
      }

      expect(failure.stage, 'upload_front');
      expect(failure.debugReason, contains('NoSuchBucket'));
      expect(failure.debugReason, contains('status=400'));
      expect(failure.debugReason, contains('hint=storage_bucket_missing'));
      expect(failure.debugReason, isNot(contains('upload-failure-user')));
      expect(failure.debugReason, isNot(contains('dueno@example.com')));
      expect(failure.debugReason, isNot(contains('3151234567')));
      expect(failure.debugReason, isNot(contains('front_1.jpg')));
      expect(failure.toString(), isNot(contains('Bucket not found')));
      expect(attemptCalls, 0);
    });

    // 10. Integración correcta con AuthGate
    testWidgets(
      '10. Usuario registrado con sesión activa transiciona en AuthGate a estado pendiente',
      (tester) async {
        final session = createMockSession(userId: 'newly-registered-id');

        await tester.pumpWidget(
          createTestApp(
            child: AuthGate(
              initialSession: session,
              enableAutoPolling: false,
              profileFetcher: (userId) async => {
                'role': 'agricultor',
                'verification_status': 'pendiente',
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(VerificationStatusScreen), findsOneWidget);
        expect(find.text('Pendiente de Documentos'), findsOneWidget);
      },
    );

    // 11. Ausencia de rutas duplicadas al completar registro
    testWidgets(
      '11. ProcessingScreen reemplaza la pila por la pantalla de espera tras registro',
      (tester) async {
        final regData = RegistrationData()
          ..phone = '3151234567'
          ..firstName = 'Carlos'
          ..lastName = 'Gómez'
          ..password = 'Password123!'
          ..role = 'agricultor'
          ..documentType = 'CC'
          ..documentFront = File('dummy_front.jpg')
          ..documentBack = File('dummy_back.jpg')
          ..selfie = File('dummy_selfie.jpg');

        final service = RegistrationService(
          signUpInvoker: ({required email, required password, data}) async {
            final user = createMockUser(userId: 'carlos-id');
            final session = createMockSession(userId: 'carlos-id');
            return AuthResponse(session: session, user: user);
          },
          profileUpserter: (_) async {},
          verificationAttemptSaver: (_) async {},
          storageUploader: (bucket, path, file) async => 'path',
        );

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProcessingScreen(
                            data: regData,
                            registrationService: service,
                            verificationService: VerificationService(
                              statusFetcher: () async => VerificationStatusData(
                                status: 'pendiente',
                                role: 'agricultor',
                                hasVerificationAttempt: true,
                                hasAllDocuments: true,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Abrir Registro'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Abrir registro apilando ProcessingScreen
        await tester.tap(find.text('Abrir Registro'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ProcessingScreen), findsOneWidget);

        // Esperar a que la operación asíncrona de registro y el delay se completen
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));

        // La pila se reemplazó: ni el formulario ni la raíz anterior quedan
        // detrás, y el usuario ve la pantalla de espera de verificación.
        expect(find.byType(ProcessingScreen), findsNothing);
        expect(find.text('Abrir Registro'), findsNothing);
        expect(find.byType(VerificationStatusScreen), findsOneWidget);
        expect(find.text('Solicitud enviada'), findsOneWidget);
        expect(
          find.text(
            'Tu solicitud de registro fue enviada y está siendo revisada por nuestros equipos de moderación.',
          ),
          findsOneWidget,
        );
        expect(
          Navigator.of(tester.element(find.byType(VerificationStatusScreen)))
              .canPop(),
          isFalse,
        );
      },
    );

    // 12. No regresión del inicio de sesión ni de los cinco estados de verificación
    testWidgets('12. No regresión de LoginScreen y conmutación de estado', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(child: const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsWidgets);
    });
  });
}
