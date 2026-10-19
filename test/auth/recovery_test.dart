import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/login/screens/login_screen.dart';
import 'package:agricultural_marketplace/features/auth/recovery/screens/forgot_password_screen.dart';
import 'package:agricultural_marketplace/features/auth/recovery/screens/reset_password_screen.dart';
import 'package:agricultural_marketplace/features/auth/recovery/services/recovery_service.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';

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

  group('Fase 1 — Subetapa 1.3: Pruebas de Recuperación Real de Contraseña', () {
    // 1. Validación de contacto vacío
    test('1. Validación de contacto vacío en RecoveryService', () async {
      int invokerCalls = 0;
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          invokerCalls++;
        },
      );

      final resultEmpty = await service.requestPasswordReset(contact: '');
      expect(resultEmpty.success, isFalse);
      expect(resultEmpty.isValidationError, isTrue);

      final resultWhitespace =
          await service.requestPasswordReset(contact: '   \t  ');
      expect(resultWhitespace.success, isFalse);
      expect(resultWhitespace.isValidationError, isTrue);

      expect(invokerCalls, equals(0));
    });

    testWidgets('1b. Validación de contacto vacío en ForgotPasswordScreen',
        (tester) async {
      int invokerCalls = 0;
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          invokerCalls++;
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ForgotPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      // Pulsar enviar sin ingresar correo
      final submitFinder = find.widgetWithText(ElevatedButton, 'Enviar instrucciones');
      expect(submitFinder, findsOneWidget);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Debe mostrarse el error de validación del formulario
      expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
      expect(invokerCalls, equals(0));
    });

    // 2. Solicitud de recuperación correcta
    test('2. Solicitud de recuperación correcta en RecoveryService', () async {
      String? sentEmail;
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          sentEmail = email;
        },
      );

      final result = await service.requestPasswordReset(
        contact: 'productor@ejemplo.com',
      );

      expect(result.success, isTrue);
      expect(sentEmail, equals('productor@ejemplo.com'));
      // Mensaje genérico para no revelar existencia de cuentas
      expect(result.message, contains('instrucciones'));
    });

    testWidgets('2b. Solicitud de recuperación correcta en ForgotPasswordScreen',
        (tester) async {
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {},
      );

      await tester.pumpWidget(
        createTestApp(
          child: ForgotPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      final inputFinder = find.byType(TextFormField);
      await tester.enterText(inputFinder, 'agricultor@campo.co');
      await tester.pumpAndSettle();

      final submitFinder = find.widgetWithText(ElevatedButton, 'Enviar instrucciones');
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Debe mostrarse el mensaje genérico de confirmación
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('instrucciones para restablecer'), findsOneWidget);
    });

    // 3. Error de conectividad
    test('3. Error de conectividad en RecoveryService', () async {
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          throw const SocketException('Failed host lookup: db.supabase.co');
        },
      );

      final result = await service.requestPasswordReset(
        contact: 'usuario@finca.org',
      );

      expect(result.success, isFalse);
      expect(result.isNetworkError, isTrue);
      expect(result.message, contains('Error de conexión'));
    });

    testWidgets('3b. Error de conectividad mostrado en ForgotPasswordScreen',
        (tester) async {
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          throw const SocketException('Network unreachable');
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ForgotPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'usuario@finca.org');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar instrucciones'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Error de conexión'), findsOneWidget);
    });

    // 4. Error del proveedor de autenticación
    test('4. Error del proveedor de autenticación (Rate limit) en RecoveryService',
        () async {
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          throw const AuthException(
            'Rate limit exceeded. Too many requests.',
            statusCode: '429',
          );
        },
      );

      final result = await service.requestPasswordReset(
        contact: 'usuario@correo.com',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Demasiadas solicitudes'));
    });

    // 5. Doble pulsación o envío repetido
    testWidgets('5. Doble pulsación no genera múltiples solicitudes en vuelo',
        (tester) async {
      int invokerCalls = 0;
      final completer = Completer<void>();

      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          invokerCalls++;
          await completer.future;
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ForgotPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'campesino@finca.co');
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton);

      // Primer toque
      await tester.tap(buttonFinder);
      await tester.pump(); // Inicia carga

      // Verificar estado de carga activo y botón deshabilitado
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(invokerCalls, equals(1));
      final elevatedButton = tester.widget<ElevatedButton>(buttonFinder);
      expect(elevatedButton.onPressed, isNull);

      // Segundo toque mientras está en vuelo
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pump();
      expect(invokerCalls, equals(1)); // NO debe haberse incrementado

      // Completar la llamada
      completer.complete();
      await tester.pumpAndSettle();

      expect(invokerCalls, equals(1));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    // 6. Validación de contraseña insuficiente (< 6 caracteres)
    test('6. Validación de contraseña menor a 6 caracteres en RecoveryService',
        () async {
      int updateCalls = 0;
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
        updateInvoker: (attributes) async {
          updateCalls++;
          return UserResponse.fromJson({
            'user': {
              'id': 'u1',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
            }
          });
        },
      );

      final result = await service.updatePassword(
        newPassword: '12345',
        confirmPassword: '12345',
      );

      expect(result.success, isFalse);
      expect(result.isValidationError, isTrue);
      expect(result.message, contains('al menos 6 caracteres'));
      expect(updateCalls, equals(0));
    });

    testWidgets('6b. Validación de contraseña insuficiente en ResetPasswordScreen',
        (tester) async {
      int updateCalls = 0;
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
        updateInvoker: (attributes) async {
          updateCalls++;
          return UserResponse.fromJson({
            'user': {
              'id': 'u1',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
            }
          });
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ResetPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '12345');
      await tester.enterText(textFields.at(1), '12345');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Actualizar contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('La contraseña debe tener al menos 6 caracteres.'),
          findsOneWidget);
      expect(updateCalls, equals(0));
    });

    // 7. Confirmación de contraseña distinta
    test('7. Confirmación de contraseña distinta en RecoveryService', () async {
      int updateCalls = 0;
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
        updateInvoker: (attributes) async {
          updateCalls++;
          return UserResponse.fromJson({
            'user': {
              'id': 'u1',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
            }
          });
        },
      );

      final result = await service.updatePassword(
        newPassword: 'claveSegura123',
        confirmPassword: 'claveDiferente456',
      );

      expect(result.success, isFalse);
      expect(result.isValidationError, isTrue);
      expect(result.message, contains('no coinciden'));
      expect(updateCalls, equals(0));
    });

    testWidgets('7b. Confirmación de contraseña distinta en ResetPasswordScreen',
        (tester) async {
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
      );

      await tester.pumpWidget(
        createTestApp(
          child: ResetPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'claveSecreta1');
      await tester.enterText(textFields.at(1), 'claveSecreta2');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Actualizar contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    // 8. Actualización de contraseña correcta
    test('8. Actualización de contraseña correcta en RecoveryService', () async {
      UserAttributes? capturedAttributes;
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
        updateInvoker: (attributes) async {
          capturedAttributes = attributes;
          return UserResponse.fromJson({
            'user': {
              'id': 'u1',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
            }
          });
        },
      );

      final result = await service.updatePassword(
        newPassword: 'nuevaClave2026',
        confirmPassword: 'nuevaClave2026',
      );

      expect(result.success, isTrue);
      expect(capturedAttributes?.password, equals('nuevaClave2026'));
      expect(result.message, contains('exitosamente'));
    });

    testWidgets('8b. Actualización de contraseña exitosa en ResetPasswordScreen',
        (tester) async {
      bool onUpdatedCalled = false;
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
        updateInvoker: (attributes) async {
          return UserResponse.fromJson({
            'user': {
              'id': 'u1',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
            }
          });
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ResetPasswordScreen(
            recoveryService: service,
            onPasswordUpdated: () {
              onUpdatedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'nuevaClaveValida99');
      await tester.enterText(textFields.at(1), 'nuevaClaveValida99');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Actualizar contraseña'));
      await tester.pumpAndSettle();

      expect(onUpdatedCalled, isTrue);
      expect(find.textContaining('actualizada exitosamente'), findsOneWidget);
    });

    // 9. Enlace inválido, caducado o ausencia de contexto válido
    test('9. Sesión de recuperación ausente o caducada en RecoveryService',
        () async {
      final service = RecoveryService(
        sessionChecker: () => null, // Sin sesión activa
      );

      final result = await service.updatePassword(
        newPassword: 'claveValida123',
        confirmPassword: 'claveValida123',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('inválido o ha caducado'));
    });

    testWidgets('9b. Manejo de error de sesión caducada en ResetPasswordScreen',
        (tester) async {
      final service = RecoveryService(
        sessionChecker: () => createMockSession(userId: 'u1'),
        updateInvoker: (attributes) async {
          throw const AuthException('JWT expired', statusCode: '401');
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ResetPasswordScreen(recoveryService: service),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'nuevaClaveValida99');
      await tester.enterText(textFields.at(1), 'nuevaClaveValida99');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Actualizar contraseña'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('inválido o ha caducado'), findsOneWidget);
    });

    // 10. Navegación posterior al éxito y prevención de rutas duplicadas
    testWidgets('10. Navegación fluida desde LoginScreen a ForgotPasswordScreen y retorno',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que estamos en LoginScreen
      expect(find.text('Iniciar sesión'), findsWidgets);

      // Tocar "¿Olvidaste tu contraseña?"
      final forgotBtn = find.text('¿Olvidaste tu contraseña?');
      expect(forgotBtn, findsOneWidget);
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // Verificar que se abrió ForgotPasswordScreen
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Recuperar contraseña'), findsOneWidget);

      // Tocar volver
      final backBtn = find.byIcon(Icons.arrow_back);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Regresó a LoginScreen limpiamente
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // 11. Conservación de las restricciones de verificación y roles
    testWidgets('11. AuthGate reacciona a passwordRecovery sin aprobar perfil ni bypass',
        (tester) async {
      final authController = StreamController<AuthState>.broadcast();
      final recoverySession = createMockSession(userId: 'farmer-recovering-uuid');

      int profileFetchCalls = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            authStateStream: authController.stream,
            profileFetcher: (userId) async {
              profileFetchCalls++;
              return {
                'id': userId,
                'role': 'agricultor',
                'verification_status': 'pendiente',
              };
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inicialmente sin sesión -> LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Supabase emite evento passwordRecovery por apertura de enlace profundo
      authController.add(
        AuthState(
          AuthChangeEvent.passwordRecovery,
          recoverySession,
        ),
      );
      await tester.pumpAndSettle();

      // AuthGate debe mostrar ResetPasswordScreen, NO el dashboard ni auto-aprobar
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
      expect(find.byType(VerificationStatusScreen), findsNothing);
      // No debe haberse consultado el perfil para otorgar acceso
      expect(profileFetchCalls, equals(0));

      await authController.close();
    });

    // 12. Comportamiento ante los tipos de identificador admitidos por el sistema
    test('12. Validación ante diversos formatos de identificador', () async {
      int invokerCalls = 0;
      final service = RecoveryService(
        resetInvoker: (email, {redirectTo}) async {
          invokerCalls++;
        },
      );

      // a) Teléfono puro: debe ser rechazado explicando que el enlace requiere correo
      final resPhone = await service.requestPasswordReset(contact: '3001234567');
      expect(resPhone.success, isFalse);
      expect(resPhone.isValidationError, isTrue);
      expect(resPhone.message, contains('requiere un correo electrónico'));

      // b) Teléfono con código de país: rechazado
      final resPhoneCountry =
          await service.requestPasswordReset(contact: '+57 300 123 4567');
      expect(resPhoneCountry.success, isFalse);
      expect(resPhoneCountry.isValidationError, isTrue);

      // c) Correo sintético interno (@agromarket.com): rechazado porque no tiene buzón real
      final resSynthetic = await service.requestPasswordReset(
          contact: '3001234567@agromarket.com');
      expect(resSynthetic.success, isFalse);
      expect(resSynthetic.isValidationError, isTrue);
      expect(resSynthetic.message, contains('sin buzón de correo'));

      // d) Correo real válido: aceptado y procesado
      final resValidEmail = await service.requestPasswordReset(
          contact: 'agricultor.real@finca.co');
      expect(resValidEmail.success, isTrue);
      expect(invokerCalls, equals(1));
    });
  });
}
