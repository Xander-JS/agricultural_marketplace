import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/login/screens/login_screen.dart';
import 'package:agricultural_marketplace/features/auth/recovery/screens/reset_password_screen.dart';
import 'package:agricultural_marketplace/features/auth/registro/screens/complete_registration_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/services/verification_service.dart';
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

  group('Fase 1 — Subetapa 1.4: Estados de Verificación del Perfil', () {
    // 1. Usuario no autenticado
    testWidgets('1. Usuario no autenticado renderiza LoginScreen sin acceso a estados',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AuthGate(
            initialSession: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 2. Perfil pendiente
    testWidgets('2. Perfil pendiente muestra VerificationStatusScreen y bloquea dashboard',
        (tester) async {
      final session = createMockSession(userId: 'farmer-pend-uuid');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'pendiente',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Pendiente de Documentos'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 3. Perfil aprobado
    testWidgets('3. Perfil aprobado navega a MainDashboardScreen según su rol',
        (tester) async {
      final session = createMockSession(userId: 'farmer-appr-uuid');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'aprobado',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);
    });

    // 4. Estados adicionales existentes
    testWidgets('4a. Estado en_revision_ia despliega vista de revisión en proceso',
        (tester) async {
      final session = createMockSession(userId: 'u-review');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'en_revision_ia',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('En Revisión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    testWidgets('4b. Estado rechazado muestra motivo de rechazo y opción de salida',
        (tester) async {
      final session = createMockSession(userId: 'u-rejected');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'rechazado',
              'rejection_reason': 'Documento frontal ilegible',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Verificación Rechazada'), findsOneWidget);
      expect(find.text('Documento frontal ilegible'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    testWidgets('4c. Estado suspendido despliega aviso administrativo y opción de salida',
        (tester) async {
      final session = createMockSession(userId: 'u-suspended');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'comprador',
              'verification_status': 'suspendido',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Cuenta Suspendida'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 5. Estado nulo o desconocido
    testWidgets('5a. verification_status nulo se mapea a desconocido y restringe acceso',
        (tester) async {
      final session = createMockSession(userId: 'u-null-status');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': null,
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar Estado Desconocido y NUNCA acceder a dashboard
      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Estado Desconocido'), findsOneWidget);
      expect(find.text('Actualizar estado'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    testWidgets('5b. verification_status con valor arbitrario/corrupto activa vista desconocida',
        (tester) async {
      final session = createMockSession(userId: 'u-corrupt-status');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'estado_corrupto_123',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Estado Desconocido'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 6. Perfil inexistente
    testWidgets('6. Perfil inexistente muestra la pantalla segura para completar el registro',
        (tester) async {
      final session = createMockSession(userId: 'u-no-profile');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('missing-profile-gate'),
            initialSession: session,
            profileFetcher: (userId) async => null,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CompleteRegistrationScreen), findsOneWidget);
      expect(find.text('Completa tu registro'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('complete_registration_submit')),
        findsOneWidget,
      );
      expect(find.text('Estado Desconocido'), findsNothing);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 7. Error de consulta y recuperación mediante reintento
    testWidgets('7. Error de red permite reintento y recupera acceso tras reconexión',
        (tester) async {
      final session = createMockSession(userId: 'u-net');
      bool hasFailed = true;

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async {
              if (hasFailed) {
                throw const SocketException('Network is down');
              }
              return {
                'id': userId,
                'role': 'agricultor',
                'verification_status': 'aprobado',
              };
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar vista de error de red
      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      // Simular recuperación de red y pulsar reintentar
      hasFailed = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
    });

    // 8. Cambio de estado de verificación durante la sesión
    testWidgets('8. Conmutación reactiva de estado pendiente a aprobado en sesión viva',
        (tester) async {
      final session = createMockSession(userId: 'u-live-transition');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'pendiente',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);

      // Simular que el callback de aprobación es invocado
      final statusScreenFinder = find.byType(VerificationStatusScreen);
      final statusScreenState =
          tester.widget<VerificationStatusScreen>(statusScreenFinder);
      statusScreenState.onVerificationApproved?.call(
        VerificationStatusData(status: 'aprobado', role: 'agricultor'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ahora transiciona a MainDashboardScreen reactivamente
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);
    });

    // 9. Evitar que consulta antigua sobrescriba sesión nueva (Epoch Token)
    testWidgets('9. Consulta desactualizada en vuelo no sobrescribe sesión de usuario nuevo',
        (tester) async {
      final authController = StreamController<AuthState>.broadcast();
      final completer1 = Completer<Map<String, dynamic>?>();

      final session1 = createMockSession(userId: 'farmer-1');
      final session2 = createMockSession(userId: 'farmer-2');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            authStateStream: authController.stream,
            profileFetcher: (userId) {
              if (userId == 'farmer-1') return completer1.future;
              return Future.value({
                'id': userId,
                'role': 'agricultor',
                'verification_status': 'aprobado',
              });
            },
            enableAutoPolling: false,
          ),
        ),
      );

      // Inicia sesión 1
      authController.add(AuthState(AuthChangeEvent.signedIn, session1));
      await tester.pump();

      // De inmediato inicia sesión 2 antes de que responda 1
      authController.add(AuthState(AuthChangeEvent.signedIn, session2));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);

      // Responde tarde la consulta 1 con estado pendiente
      completer1.complete({
        'id': 'farmer-1',
        'role': 'agricultor',
        'verification_status': 'pendiente',
      });
      await tester.pumpAndSettle();

      // Debe permanecer en el dashboard del usuario 2 (aprobado), ignorando el retorno tardío
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);

      await authController.close();
    });

    // 10. Aislamiento entre usuarios y roles
    testWidgets('10. Comprador aprobado ve Compras y Agricultor ve Costos',
        (tester) async {
      final buyerSession = createMockSession(userId: 'buyer-uuid');
      final farmerSession = createMockSession(userId: 'farmer-uuid');

      // Test Comprador
      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('buyer-gate'),
            initialSession: buyerSession,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'comprador',
              'verification_status': 'aprobado',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Costos'), findsNothing);

      // Test Agricultor
      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('farmer-gate'),
            initialSession: farmerSession,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'aprobado',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Costos'), findsOneWidget);
      expect(find.text('Compras'), findsNothing);
    });

    // 11. Integración con la pantalla de recuperación de contraseña
    testWidgets('11. Evento passwordRecovery muestra ResetPasswordScreen sin bypass de perfil',
        (tester) async {
      final authController = StreamController<AuthState>.broadcast();
      final recoverySession = createMockSession(userId: 'recovering-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            authStateStream: authController.stream,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'pendiente',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      authController.add(
        AuthState(
          AuthChangeEvent.passwordRecovery,
          recoverySession,
        ),
      );
      await tester.pumpAndSettle();

      // Debe montar ResetPasswordScreen y NO MainDashboardScreen ni VerificationStatusScreen
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
      expect(find.byType(VerificationStatusScreen), findsNothing);

      await authController.close();
    });

    // 12. Prevención de navegación indebida hacia funciones protegidas
    test('12. Estados no aprobados tienen isApproved = false de forma absoluta', () {
      final validUnapproved = [
        'pendiente',
        'en_revision_ia',
        'rechazado',
        'suspendido',
        'desconocido',
        'arbitrario',
        null,
      ];

      for (final st in validUnapproved) {
        final parsed = UserVerificationStatus.fromString(st);
        expect(
          parsed.isApproved,
          isFalse,
          reason: 'El estado $st no debe considerarse aprobado',
        );
      }

      expect(UserVerificationStatus.fromString('aprobado').isApproved, isTrue);
      expect(UserVerificationStatus.fromString('approved').isApproved, isTrue);
    });

    // Prueba de servicio con DI y manejo seguro de nulls
    test('13. VerificationService maneja nulls de forma segura sin TypeErrors', () async {
      final service = VerificationService(
        statusFetcher: () async => VerificationStatusData(
          status: 'desconocido',
          role: 'agricultor',
        ),
      );

      final statusData = await service.getCurrentVerificationStatus();
      expect(statusData.status, equals('desconocido'));
      expect(statusData.role, equals('agricultor'));
    });

    // 14a. Estado de verificación pendiente permite cerrar sesión y regresa a LoginScreen
    testWidgets('14a. Estado de verificación pendiente permite cerrar sesión y regresa a LoginScreen', (tester) async {
      final session = createMockSession(userId: 'farmer-pend-logout');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'pendiente',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Pendiente de Documentos'), findsOneWidget);

      await tester.ensureVisible(find.text('Cerrar sesión'));
      expect(find.text('Cerrar sesión'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);
    });

    // 14b. Estado de verificación en_revision_ia permite cerrar sesión y regresa a LoginScreen
    testWidgets('14b. Estado de verificación en_revision_ia permite cerrar sesión y regresa a LoginScreen', (tester) async {
      final session = createMockSession(userId: 'farmer-review-logout');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': 'en_revision_ia',
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('En Revisión'), findsOneWidget);

      await tester.ensureVisible(find.text('Cerrar sesión'));
      expect(find.text('Cerrar sesión'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);
    });

    // 14c. Estado de error en verificación despliega botón de cerrar sesión operable
    testWidgets('14c. Estado de error en verificación despliega botón de cerrar sesión operable', (tester) async {
      bool signedOut = false;

      final failingService = VerificationService(
        statusFetcher: () async => throw Exception('Fallo de conexión en verificación'),
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            verificationService: failingService,
            onSignOut: () async {
              signedOut = true;
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });
  });
}
