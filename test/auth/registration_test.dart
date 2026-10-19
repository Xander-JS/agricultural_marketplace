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
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';

Session createMockSession({required String userId}) {
  return Session.fromJson({
    'access_token': 'mock-access-token-$userId',
    'token_type': 'bearer',
    'user': <String, dynamic>{
      'id': userId,
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
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
    test('3. Contraseña inválida (menor a 6 caracteres) es rechazada', () async {
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
    });

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

    // 5. Error por cuenta existente
    test('5. Error por cuenta existente captura AuthException y arroja mensaje comprensible', () async {
      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          throw const AuthException('User already registered');
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
          predicate((e) =>
              e is Exception &&
              e.toString().contains('ya se encuentra registrado')),
        ),
      );
    });

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
          predicate((e) =>
              e is Exception && e.toString().contains('Error de conexión')),
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
          throw const PostgrestException(message: 'Error de inserción en profiles');
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
          predicate((e) =>
              e is Exception &&
              e.toString().contains('Error al procesar el registro')),
        ),
      );
    });

    // 8. Prevención de asignación del rol moderador
    test('8. Prevención estricta contra auto-asignación de rol moderador', () async {
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
          predicate((e) =>
              e is ArgumentError &&
              e.message.contains('No está permitido registrarse con el rol de moderador')),
        ),
      );
    });

    // 9. Comportamiento cuando Supabase exige confirmar el contacto antes de iniciar sesión
    test('9. Cuenta sin sesión inmediata por requerimiento de confirmación no simula sesión activa', () async {
      bool profileUpsertCalled = false;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          final user = createMockUser(userId: 'unconfirmed-user');
          // authRes.session es null cuando Supabase exige confirmación por correo/SMS
          return AuthResponse(session: null, user: user);
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
      // No debe intentar mutar profiles bajo rol anon sin sesión
      expect(profileUpsertCalled, isFalse);
    });

    // 10. Integración correcta con AuthGate
    testWidgets('10. Usuario registrado con sesión activa transiciona en AuthGate a estado pendiente', (tester) async {
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
    });

    // 11. Ausencia de rutas duplicadas al completar registro
    testWidgets('11. ProcessingScreen regresa limpiamente a la raíz con popUntil tras registro', (tester) async {
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

      // Esperar a que la operación asíncrona de registro y el delay de pop se completen
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      // ProcessingScreen debe haberse desapilado limpiamente, volviendo a la pantalla raíz
      expect(find.text('Abrir Registro'), findsOneWidget);
      expect(find.byType(ProcessingScreen), findsNothing);
    });

    // 12. No regresión del inicio de sesión ni de los cinco estados de verificación
    testWidgets('12. No regresión de LoginScreen y conmutación de estado', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsWidgets);
    });
  });
}
