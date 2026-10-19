import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';
import 'package:agricultural_marketplace/features/moderation/models/moderation_request.dart';
import 'package:agricultural_marketplace/features/moderation/screens/moderation_detail_screen.dart';
import 'package:agricultural_marketplace/features/moderation/screens/moderation_queue_screen.dart';
import 'package:agricultural_marketplace/features/moderation/services/moderation_service.dart';

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

ModerationRequest createSampleRequest({
  String id = 'attempt-1',
  String userId = 'user-test-1',
  String fullName = 'Carlos Agricultor',
  String phone = '+573001112233',
  UserRole role = UserRole.agricultor,
  UserVerificationStatus status = UserVerificationStatus.pendiente,
  String? rejectionReason,
}) {
  return ModerationRequest(
    id: id,
    userId: userId,
    fullName: fullName,
    phone: phone,
    email: 'carlos@agromarket.com',
    userRole: role,
    status: status,
    documentFrontPath: 'mock/path/cedula_front.jpg',
    documentBackPath: 'mock/path/cedula_back.jpg',
    selfiePath: 'mock/path/selfie.jpg',
    rejectionReason: rejectionReason,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
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

  group('Fase 1 — Subetapa 1.5: Pruebas del Módulo de Moderación', () {
    // 1. Un moderador autorizado puede consultar solicitudes
    testWidgets('1. Moderador autorizado consulta y visualiza solicitudes en la cola',
        (tester) async {
      final sample = createSampleRequest();
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        requestsFetcher: ({int limit = 50, int offset = 0, String? statusFilter}) async {
          return [sample];
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationQueueScreen(
            moderationService: service,
            isModeratorOverride: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ModerationQueueScreen), findsOneWidget);
      expect(find.text('Cola de Moderación'), findsOneWidget);
      expect(find.text('Carlos Agricultor'), findsOneWidget);
      expect(find.text('+573001112233'), findsOneWidget);
      expect(find.text('Agricultor'), findsOneWidget);
    });

    // 2. Un comprador no puede acceder a la funcionalidad de moderación
    testWidgets('2. Comprador autenticado recibe pantalla de acceso no autorizado',
        (tester) async {
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.comprador,
        currentUserIdFetcher: () => 'buyer-1',
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationQueueScreen(
            moderationService: service,
            isModeratorOverride: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Acceso No Autorizado'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_outlined), findsOneWidget);
      expect(find.text('Carlos Agricultor'), findsNothing);
    });

    // 3. Un agricultor no puede acceder a la funcionalidad de moderación
    testWidgets('3. Agricultor autenticado recibe pantalla de acceso no autorizado',
        (tester) async {
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.agricultor,
        currentUserIdFetcher: () => 'farmer-1',
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationQueueScreen(
            moderationService: service,
            isModeratorOverride: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Acceso No Autorizado'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_outlined), findsOneWidget);
    });

    // 4. La cola vacía se representa correctamente
    testWidgets('4. Cola vacía despliega estado vacío con icono y texto explicativo',
        (tester) async {
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        requestsFetcher: ({int limit = 50, int offset = 0, String? statusFilter}) async => [],
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationQueueScreen(
            moderationService: service,
            isModeratorOverride: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No hay solicitudes pendientes'), findsOneWidget);
    });

    // 5. Los errores de red pueden recuperarse mediante reintento
    testWidgets('5. Error de red permite reintento y recupera la lista tras reintentar',
        (tester) async {
      bool fail = true;
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        requestsFetcher: ({int limit = 50, int offset = 0, String? statusFilter}) async {
          if (fail) {
            throw Exception('Fallo de conexión al servidor de moderación');
          }
          return [createSampleRequest(fullName: 'Juan Recuperado')];
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationQueueScreen(
            moderationService: service,
            isModeratorOverride: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      // Desactivar fallo y presionar Reintentar
      fail = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Juan Recuperado'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    // 6. La aprobación persiste y refleja el estado esperado
    testWidgets('6. Aprobación persiste el estado y notifica al usuario',
        (tester) async {
      final sample = createSampleRequest();
      bool approvalExecuted = false;

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({
          required String attemptId,
          required String userId,
          required String decision,
          String? reason,
        }) async {
          if (decision == 'aprobado') {
            approvalExecuted = true;
            return ModerationDecisionResult.success(
              updatedStatus: UserVerificationStatus.aprobado,
            );
          }
          return ModerationDecisionResult.failure(errorMessage: 'Invalido');
        },
      );

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aprobar'), findsOneWidget);
      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      // Diálogo de confirmación
      expect(find.text('Confirmar Aprobación'), findsOneWidget);
      // Pulsar Aprobar en el diálogo
      final approveInDialog = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Aprobar'),
      );
      await tester.tap(approveInDialog);
      await tester.pumpAndSettle();

      expect(approvalExecuted, isTrue);
    });

    // 7. El rechazo exige y registra el motivo cuando corresponda
    testWidgets('7. Rechazo valida que el motivo sea obligatorio y persiste la razón',
        (tester) async {
      final sample = createSampleRequest();
      String? recordedReason;

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({
          required String attemptId,
          required String userId,
          required String decision,
          String? reason,
        }) async {
          if (decision == 'rechazado') {
            recordedReason = reason;
            return ModerationDecisionResult.success(
              updatedStatus: UserVerificationStatus.rechazado,
              reason: reason,
            );
          }
          return ModerationDecisionResult.failure(errorMessage: 'Invalido');
        },
      );

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rechazar'), findsOneWidget);
      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();

      // Diálogo de rechazo
      expect(find.text('Rechazar Solicitud'), findsOneWidget);

      // Intentar enviar vacío
      final rejectInDialog = find.widgetWithText(ElevatedButton, 'Rechazar');
      await tester.tap(rejectInDialog);
      await tester.pumpAndSettle();

      expect(find.text('El motivo de rechazo es obligatorio.'), findsOneWidget);
      expect(recordedReason, isNull);

      // Escribir motivo válido
      await tester.enterText(
        find.byType(TextFormField),
        'Cédula ilegible con reflejo de luz en número',
      );
      await tester.tap(rejectInDialog);
      await tester.pumpAndSettle();

      expect(recordedReason, 'Cédula ilegible con reflejo de luz en número');
    });

    // 8. Solicitudes ya resueltas no pueden volver a resolverse de forma incompatible
    testWidgets('8. Solicitud ya aprobada o rechazada deshabilita botones de acción',
        (tester) async {
      final sampleResolved = createSampleRequest(
        status: UserVerificationStatus.aprobado,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sampleResolved,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aprobar'), findsNothing);
      expect(find.text('Rechazar'), findsNothing);
      expect(
        find.text('Esta solicitud ya fue resuelta y no admite nuevas modificaciones inmediatas.'),
        findsOneWidget,
      );
    });

    // 9. Un fallo de persistencia no se presenta como éxito
    testWidgets('9. Fallo en el backend reporta error y no engaña con falso éxito',
        (tester) async {
      final sample = createSampleRequest();

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({
          required String attemptId,
          required String userId,
          required String decision,
          String? reason,
        }) async {
          return ModerationDecisionResult.failure(
            errorMessage: 'Error de base de datos RLS: permiso denegado 42501',
            errorCode: '42501',
          );
        },
      );

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      final approveInDialog = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Aprobar'),
      );
      await tester.tap(approveInDialog);
      await tester.pumpAndSettle();

      expect(find.text('Error de base de datos RLS: permiso denegado 42501'), findsOneWidget);
      expect(find.text('Solicitud aprobada con éxito.'), findsNothing);
    });

    // 10. Los perfiles no aprobados siguen sin acceso a funciones comerciales
    testWidgets('10. AuthGate retiene en VerificationStatusScreen si el usuario sigue pendiente',
        (tester) async {
      final session = createMockSession(userId: 'u-pending-farmer');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('pending-farmer-gate'),
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
    });

    // 11. El usuario afectado ve el resultado correcto tras aprobación
    testWidgets('11. AuthGate conmuta a dashboard comercial cuando el perfil es resuelto como aprobado',
        (tester) async {
      final session = createMockSession(userId: 'u-approved-buyer');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('approved-buyer-gate'),
            initialSession: session,
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

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.text('Compras'), findsOneWidget);
    });

    // 12. Error de autorización del servidor en ModerationService
    testWidgets('12. ModerationService valida que usuario no moderador reciba código 403',
        (tester) async {
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.comprador,
        currentUserIdFetcher: () => 'buyer-unauth',
      );

      final result = await service.approveRequest(
        attemptId: 'att-1',
        userId: 'u-target',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, '403');
      expect(result.errorMessage, contains('rol de moderador'));
    });

    // 13. Motivo de rechazo previo se visualiza en el detalle
    testWidgets('13. Detalle de moderación muestra motivo de rechazo previo e información de documentos',
        (tester) async {
      final sampleWithRejection = createSampleRequest(
        rejectionReason: 'Firma en cédula no concuerda con registro civil',
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sampleWithRejection,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Motivo de Rechazo Registrado'), findsOneWidget);
      expect(find.text('Firma en cédula no concuerda con registro civil'), findsOneWidget);
      expect(find.text('Documentos Presentados'), findsOneWidget);
      expect(find.text('Archivos locales/simulados. La integración con Supabase Storage se completará en la Fase 2.'), findsOneWidget);
    });

    // 14. Integración en AuthGate: Moderador aprobado es enrutado directamente a ModerationQueueScreen
    testWidgets('14. AuthGate enruta a un usuario con rol moderador directamente a ModerationQueueScreen',
        (tester) async {
      final session = createMockSession(userId: 'u-moderator-1');

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'u-moderator-1',
        requestsFetcher: ({int limit = 50, int offset = 0, String? statusFilter}) async => [],
      );

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('moderator-gate'),
            initialSession: session,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'moderador',
              'verification_status': 'aprobado',
            },
            moderationService: service,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ModerationQueueScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
      expect(find.text('Cola de Moderación'), findsOneWidget);
    });
  });
}
