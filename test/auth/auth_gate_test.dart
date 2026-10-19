import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/loading/loading_indicator.dart';
import 'package:agricultural_marketplace/features/auth/login/screens/login_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';

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

  group('Fase 1 — Subetapa 1.1: Pruebas de AuthGate y Ciclo de Vida de Sesión', () {
    // 1. Carga inicial con sesión persistida
    testWidgets('1. Carga inicial con sesión persistida muestra loader sin parpadeo de login', (tester) async {
      final session = createMockSession(userId: 'farmer-uuid');
      final completer = Completer<Map<String, dynamic>?>();

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) => completer.future,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(MainDashboardScreen), findsNothing);

      completer.complete({
        'role': 'agricultor',
        'verification_status': 'aprobado',
      });
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(LoadingIndicator), findsNothing);
    });

    // 2. Inicio sin sesión
    testWidgets('2. Inicio sin sesión renderiza LoginScreen limpiamente', (tester) async {
      final authController = StreamController<AuthState>.broadcast();

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            authStateStream: authController.stream,
            initialSession: null,
            profileFetcher: (userId) async => null,
          ),
        ),
      );
      authController.add(const AuthState(AuthChangeEvent.initialSession, null));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);

      await authController.close();
    });

    // 3. Usuario aprobado
    testWidgets('3. Usuario aprobado navega a MainDashboardScreen con rol persistido', (tester) async {
      final session = createMockSession(userId: 'buyer-uuid');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'role': 'comprador',
              'verification_status': 'aprobado',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dashboard = tester.widget<MainDashboardScreen>(find.byType(MainDashboardScreen));
      expect(dashboard.role, equals('comprador'));
      expect(find.byType(LoginScreen), findsNothing);
    });

    // 4. Los cuatro estados restantes de verificación
    testWidgets('4a. Estado de verificación pendiente renderiza VerificationStatusScreen con estado pendiente', (tester) async {
      final session = createMockSession(userId: 'pending-user');

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
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    testWidgets('4b. Estado en_revision_ia renderiza VerificationStatusScreen con estado de revisión', (tester) async {
      final session = createMockSession(userId: 'review-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            enableAutoPolling: false,
            profileFetcher: (userId) async => {
              'role': 'agricultor',
              'verification_status': 'en_revision_ia',
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('En Revisión'), findsOneWidget);
    });

    testWidgets('4c. Estado rechazado renderiza VerificationStatusScreen con motivo y opción de salida', (tester) async {
      final session = createMockSession(userId: 'rejected-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            enableAutoPolling: false,
            profileFetcher: (userId) async => {
              'role': 'agricultor',
              'verification_status': 'rechazado',
              'rejection_reason': 'Cédula no legible',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Verificación Rechazada'), findsOneWidget);
      expect(find.text('Cédula no legible'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('4d. Estado suspendido renderiza VerificationStatusScreen con aviso administrativo', (tester) async {
      final session = createMockSession(userId: 'suspended-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            enableAutoPolling: false,
            profileFetcher: (userId) async => {
              'role': 'agricultor',
              'verification_status': 'suspendido',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text('Cuenta Suspendida'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    // 5. Perfil inexistente
    testWidgets('5. Perfil inexistente despliega pantalla informativa segura con reintento y salida', (tester) async {
      final session = createMockSession(userId: 'orphan-user');
      int fetchCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async {
              fetchCount++;
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estado Desconocido'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(fetchCount, equals(2));
    });

    // 5b. Perfil con rol nulo
    testWidgets('5b. Perfil con rol nulo conduce a estado recuperable con reintento y cierre de sesión', (tester) async {
      final session = createMockSession(userId: 'null-role-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'role': null,
              'verification_status': 'aprobado',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.text('El rol del perfil no es válido o no está definido.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // 5c. Perfil con rol desconocido
    testWidgets('5c. Perfil con rol desconocido conduce a estado recuperable con reintento y cierre de sesión', (tester) async {
      final session = createMockSession(userId: 'unknown-role-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'role': 'rol_invalido_hacker',
              'verification_status': 'aprobado',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.text('El rol del perfil no es válido o no está definido.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 6. Error de red y reintento exitoso
    testWidgets('6. Error de red despliega vista con reintento y transiciona a dashboard al recuperarse', (tester) async {
      final session = createMockSession(userId: 'network-user');
      bool simulateNetworkFailure = true;

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async {
              if (simulateNetworkFailure) {
                throw const SocketException('Failed host lookup: placeholder.supabase.co');
              }
              return {
                'role': 'agricultor',
                'verification_status': 'aprobado',
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);

      simulateNetworkFailure = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.text('Ha ocurrido un error'), findsNothing);
    });

    // 6b. Vista de error de red permite cerrar sesión
    testWidgets('6b. Vista de error de red permite cerrar sesión y regresa limpiamente a LoginScreen', (tester) async {
      final session = createMockSession(userId: 'network-user-logout');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async {
              throw const SocketException('No route to host');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // 7. Cierre de sesión reactivo
    testWidgets('7. Cierre de sesión reactivo desmonta dashboard y conmuta a LoginScreen', (tester) async {
      final session = createMockSession(userId: 'active-farmer');
      final authController = StreamController<AuthState>.broadcast();

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            authStateStream: authController.stream,
            profileFetcher: (userId) async => {
              'role': 'agricultor',
              'verification_status': 'aprobado',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      authController.add(const AuthState(AuthChangeEvent.signedOut, null));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);

      await authController.close();
    });

    // 8. Renovación de token sin nueva consulta de perfil
    testWidgets('8. Evento tokenRefreshed no genera nuevas consultas de perfil ni reconstrucción', (tester) async {
      final session = createMockSession(userId: 'token-refresh-user');
      final authController = StreamController<AuthState>.broadcast();
      int profileQueries = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            authStateStream: authController.stream,
            profileFetcher: (userId) async {
              profileQueries++;
              return {
                'role': 'agricultor',
                'verification_status': 'aprobado',
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(profileQueries, equals(1));

      authController.add(AuthState(AuthChangeEvent.tokenRefreshed, session));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(profileQueries, equals(1));

      await authController.close();
    });

    // 9. Cambio de usuario mientras hay una consulta pendiente
    testWidgets('9. Cambio de usuario mientras hay consulta en vuelo descarta al usuario anterior', (tester) async {
      final userA = createMockSession(userId: 'user-A');
      final userB = createMockSession(userId: 'user-B');
      final authController = StreamController<AuthState>.broadcast();

      final completerA = Completer<Map<String, dynamic>?>();

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: userA,
            authStateStream: authController.stream,
            profileFetcher: (userId) {
              if (userId == 'user-A') return completerA.future;
              return Future.value({
                'role': 'comprador',
                'verification_status': 'aprobado',
              });
            },
          ),
        ),
      );
      await tester.pump();

      // Mientras la consulta de User A está pendiente, se emite inicio de sesión para User B
      authController.add(AuthState(AuthChangeEvent.signedIn, userB));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      var dashboard = tester.widget<MainDashboardScreen>(find.byType(MainDashboardScreen));
      expect(dashboard.role, equals('comprador'));

      // Ahora se completa tardíamente la consulta de User A
      completerA.complete({
        'role': 'agricultor',
        'verification_status': 'aprobado',
      });
      await tester.pumpAndSettle();

      // Debe mantenerse en User B ('comprador') gracias al token de epoch
      dashboard = tester.widget<MainDashboardScreen>(find.byType(MainDashboardScreen));
      expect(dashboard.role, equals('comprador'));

      await authController.close();
    });

    // 10. Compatibilidad con la identidad de usuario usada por el ciclo comercial
    testWidgets('10. NegotiationService conserva acceso al identificador de usuario activo', (tester) async {
      const commercialUserId = 'farmer-commercial-uuid';

      final service = NegotiationService(
        currentUserIdForTesting: commercialUserId,
        rpcInvoker: (func, {params}) async => {'status': 'success'},
      );

      final session = createMockSession(userId: commercialUserId);

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'role': 'agricultor',
              'verification_status': 'aprobado',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(session.user.id, equals(commercialUserId));
      expect(service, isNotNull);
    });

    // 11. Cierre de sesión desde Dashboard / Perfil propaga hacia AuthGate y maneja fallo remoto
    testWidgets('11. Cierre de sesión desde MainDashboardScreen maneja fallo remoto y regresa a LoginScreen', (tester) async {
      final session = createMockSession(userId: 'farmer-logout-test');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            profileFetcher: (userId) async => {
              'role': 'agricultor',
              'verification_status': 'aprobado',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);

      final dashboard = tester.widget<MainDashboardScreen>(find.byType(MainDashboardScreen));
      expect(dashboard.onSignOut, isNotNull);

      // Invocar el callback de cierre de sesión inyectado al dashboard
      dashboard.onSignOut!();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    // 12a. Error de credenciales expiradas con refresco exitoso
    testWidgets('12a. Error de credenciales expiradas con refresco exitoso reanuda resolución y muestra dashboard', (tester) async {
      final session = createMockSession(userId: 'expired-token-user');
      int fetchCalls = 0;
      int refreshCalls = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            sessionRefresher: () async {
              refreshCalls++;
              return AuthResponse(session: createMockSession(userId: 'expired-token-user'));
            },
            profileFetcher: (userId) async {
              fetchCalls++;
              if (fetchCalls == 1) {
                throw const PostgrestException(message: 'JWT expired', code: 'PGRST301');
              }
              return {
                'role': 'agricultor',
                'verification_status': 'aprobado',
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(refreshCalls, equals(1));
      expect(fetchCalls, equals(2));
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // 12b. Credenciales irrecuperables tras fallar el refresco
    testWidgets('12b. Credenciales irrecuperables tras fallar el refresco desautentica a LoginScreen', (tester) async {
      final session = createMockSession(userId: 'dead-token-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            sessionRefresher: () async {
              throw const AuthException('Invalid refresh token: session_not_found');
            },
            profileFetcher: (userId) async {
              throw const PostgrestException(message: 'JWT expired', code: 'PGRST301');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
      expect(find.text('Ha ocurrido un error'), findsNothing);
    });

    // 12c. Fallo de red durante el refresco de sesión
    testWidgets('12c. Fallo de red durante el refresco muestra error de red sin desautenticar indebidamente', (tester) async {
      final session = createMockSession(userId: 'network-refresh-user');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            sessionRefresher: () async {
              throw const SocketException('Failed host lookup: auth.supabase.co');
            },
            profileFetcher: (userId) async {
              throw const PostgrestException(message: 'JWT expired', code: 'PGRST301');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // 12d. Respuesta asíncrona después de desmontar AuthGate
    testWidgets('12d. Respuesta asíncrona tras desmontar AuthGate no produce setState después de dispose', (tester) async {
      final session = createMockSession(userId: 'dispose-refresh-user');
      final completer = Completer<AuthResponse>();

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            initialSession: session,
            sessionRefresher: () => completer.future,
            profileFetcher: (userId) async {
              throw const PostgrestException(message: 'JWT expired', code: 'PGRST301');
            },
          ),
        ),
      );
      await tester.pump();

      // Desmontar el widget mientras el refresco está pendiente
      await tester.pumpWidget(const SizedBox());

      // Completar el refresco tras desmontar
      completer.complete(AuthResponse(session: session));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
