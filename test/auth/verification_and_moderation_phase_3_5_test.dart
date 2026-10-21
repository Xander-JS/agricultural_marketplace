import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/services/verification_service.dart';
import 'package:agricultural_marketplace/features/moderation/models/moderation_request.dart';
import 'package:agricultural_marketplace/features/moderation/screens/moderation_detail_screen.dart';
import 'package:agricultural_marketplace/features/moderation/screens/moderation_queue_screen.dart';
import 'package:agricultural_marketplace/features/moderation/services/document_diagnosis_service.dart';
import 'package:agricultural_marketplace/features/moderation/services/document_image_service.dart';
import 'package:agricultural_marketplace/features/moderation/services/moderation_service.dart';

Widget createTestApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    locale: LocalizationConfig.defaultLocale,
    supportedLocales: LocalizationConfig.supportedLocales,
    localizationsDelegates: LocalizationConfig.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

ModerationRequest createSampleRequest({
  String id = 'attempt-1',
  String userId = 'user-test-1',
  String fullName = 'Marlon Agricultor',
  String phone = '+573001112233',
  UserRole role = UserRole.agricultor,
  UserVerificationStatus status = UserVerificationStatus.pendiente,
  String? rejectionReason,
  String documentFrontPath = 'docs/front.jpg',
  String documentBackPath = 'docs/back.jpg',
  String selfiePath = 'docs/selfie.jpg',
}) {
  return ModerationRequest(
    id: id,
    userId: userId,
    fullName: fullName,
    phone: phone,
    email: 'marlon@agromarket.com',
    userRole: role,
    status: status,
    documentFrontPath: documentFrontPath,
    documentBackPath: documentBackPath,
    selfiePath: selfiePath,
    rejectionReason: rejectionReason,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

DocumentImageUrlService createOfflineImageService() {
  return DocumentImageUrlService(
    signer: (bucket, path, expiresInSeconds) async => 'https://mock.storage/$path',
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

  group('Fase 3.5 — Modelos y Enumeradores de Verificación', () {
    test('1. UserVerificationStatus parsea y expone getters para todos los estados oficiales', () {
      expect(UserVerificationStatus.fromString('pendiente'), UserVerificationStatus.pendiente);
      expect(UserVerificationStatus.fromString('pending'), UserVerificationStatus.pendiente);
      expect(UserVerificationStatus.fromString('en_revision_ia'), UserVerificationStatus.enRevisionIa);
      expect(UserVerificationStatus.fromString('aprobado'), UserVerificationStatus.aprobado);
      expect(UserVerificationStatus.fromString('approved'), UserVerificationStatus.aprobado);
      expect(UserVerificationStatus.fromString('rechazado'), UserVerificationStatus.rechazado);
      expect(UserVerificationStatus.fromString('rejected'), UserVerificationStatus.rechazado);
      expect(UserVerificationStatus.fromString('suspendido'), UserVerificationStatus.suspendido);
      expect(UserVerificationStatus.fromString('suspended'), UserVerificationStatus.suspendido);
      expect(UserVerificationStatus.fromString(null), UserVerificationStatus.desconocido);
      expect(UserVerificationStatus.fromString('valor_invalido'), UserVerificationStatus.desconocido);

      // Verificación de flags booleanos
      expect(UserVerificationStatus.pendiente.isPending, isTrue);
      expect(UserVerificationStatus.pendiente.isApproved, isFalse);

      expect(UserVerificationStatus.enRevisionIa.isUnderAiReview, isTrue);
      expect(UserVerificationStatus.enRevisionIa.isApproved, isFalse);

      expect(UserVerificationStatus.aprobado.isApproved, isTrue);
      expect(UserVerificationStatus.aprobado.isPending, isFalse);

      expect(UserVerificationStatus.rechazado.isRejected, isTrue);
      expect(UserVerificationStatus.rechazado.isApproved, isFalse);

      expect(UserVerificationStatus.suspendido.isSuspended, isTrue);
      expect(UserVerificationStatus.suspendido.isApproved, isFalse);

      expect(UserVerificationStatus.desconocido.isUnknown, isTrue);

      // Conversión a valor de BD
      expect(UserVerificationStatus.pendiente.toDbValue(), 'pendiente');
      expect(UserVerificationStatus.enRevisionIa.toDbValue(), 'en_revision_ia');
      expect(UserVerificationStatus.aprobado.toDbValue(), 'aprobado');
      expect(UserVerificationStatus.rechazado.toDbValue(), 'rechazado');
      expect(UserVerificationStatus.suspendido.toDbValue(), 'suspendido');
      expect(UserVerificationStatus.desconocido.toDbValue(), 'desconocido');

      // Nombres amigables en español
      expect(UserVerificationStatus.pendiente.displayName, 'Pendiente');
      expect(UserVerificationStatus.enRevisionIa.displayName, 'En revisión');
      expect(UserVerificationStatus.aprobado.displayName, 'Aprobado');
      expect(UserVerificationStatus.rechazado.displayName, 'Rechazado');
      expect(UserVerificationStatus.suspendido.displayName, 'Suspendido');
      expect(UserVerificationStatus.desconocido.displayName, 'Desconocido');
    });

    test('2. VerificationStatusData mapea correctamente el status a enum y booleanos', () {
      final pendingData = VerificationStatusData(status: 'pendiente');
      expect(pendingData.verificationStatus, UserVerificationStatus.pendiente);
      expect(pendingData.isPending, isTrue);
      expect(pendingData.isApproved, isFalse);

      final reviewData = VerificationStatusData(status: 'en_revision_ia');
      expect(reviewData.verificationStatus, UserVerificationStatus.enRevisionIa);
      expect(reviewData.isUnderAiReview, isTrue);
      expect(reviewData.isApproved, isFalse);

      final approvedData = VerificationStatusData(status: 'aprobado');
      expect(approvedData.verificationStatus, UserVerificationStatus.aprobado);
      expect(approvedData.isApproved, isTrue);

      final rejectedData = VerificationStatusData(status: 'rechazado', rejectionReason: 'Foto ilegible');
      expect(rejectedData.verificationStatus, UserVerificationStatus.rechazado);
      expect(rejectedData.isRejected, isTrue);
      expect(rejectedData.rejectionReason, 'Foto ilegible');

      final suspendedData = VerificationStatusData(status: 'suspendido');
      expect(suspendedData.verificationStatus, UserVerificationStatus.suspendido);
      expect(suspendedData.isSuspended, isTrue);

      final unknownData = VerificationStatusData(status: 'desconocido');
      expect(unknownData.verificationStatus, UserVerificationStatus.desconocido);
      expect(unknownData.isUnknown, isTrue);
    });

    test('3. ModerationRequest expone getters isSuspended e isUnderAiReview', () {
      final reqReview = createSampleRequest(status: UserVerificationStatus.enRevisionIa);
      expect(reqReview.isUnderAiReview, isTrue);
      expect(reqReview.isPending, isTrue);
      expect(reqReview.isApproved, isFalse);

      final reqSusp = createSampleRequest(status: UserVerificationStatus.suspendido);
      expect(reqSusp.isSuspended, isTrue);
      expect(reqSusp.isPending, isFalse);
    });
  });

  group('Fase 3.5 — Pantalla de Estado del Usuario (VerificationStatusScreen)', () {
    testWidgets('4. Estado pendiente: muestra insignia Pendiente, spinner y acción de actualizar',
        (tester) async {
      final data = VerificationStatusData(
        status: 'pendiente',
        role: 'agricultor',
        hasAllDocuments: true,
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('verification_status_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_status_badge')), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_status_title')), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_status_refresh')), findsOneWidget);
    });

    testWidgets('5. Estado pendiente sin documentos: muestra botón de cargar documentos',
        (tester) async {
      final data = VerificationStatusData(
        status: 'pendiente',
        role: 'agricultor',
        hasAllDocuments: false,
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('verification_upload_documents')), findsOneWidget);
    });

    testWidgets('6. Estado en_revision_ia: muestra insignia En revisión y título descriptivo',
        (tester) async {
      final data = VerificationStatusData(
        status: 'en_revision_ia',
        role: 'agricultor',
        hasAllDocuments: true,
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('verification_status_badge')), findsOneWidget);
      expect(find.text('En revisión'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_status_title')), findsOneWidget);
      expect(find.text('En Revisión'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_status_refresh')), findsOneWidget);
    });

    testWidgets('7. Estado aprobado: muestra insignia Aprobado y botón de ingreso',
        (tester) async {
      bool approvedInvoked = false;
      final data = VerificationStatusData(
        status: 'aprobado',
        role: 'agricultor',
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
            onVerificationApproved: (updatedData) {
              approvedInvoked = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verification_status_badge')), findsOneWidget);
      expect(find.text('Aprobado'), findsOneWidget);
      expect(find.text('Verificación Aprobada'), findsOneWidget);

      final enterBtn = find.byKey(const ValueKey('verification_status_enter_app'));
      expect(enterBtn, findsOneWidget);

      await tester.tap(enterBtn);
      await tester.pumpAndSettle();

      expect(approvedInvoked, isTrue);
    });

    testWidgets('8. Estado rechazado: muestra motivo del rechazo y botón para reintentar carga',
        (tester) async {
      final data = VerificationStatusData(
        status: 'rechazado',
        rejectionReason: 'La foto de la cédula está cortada y borrosa.',
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verification_status_badge')), findsOneWidget);
      expect(find.text('Rechazado'), findsOneWidget);
      expect(find.text('Verificación Rechazada'), findsOneWidget);
      expect(find.text('La foto de la cédula está cortada y borrosa.'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_upload_documents')), findsOneWidget);
    });

    testWidgets('9. Estado suspendido: preserva aviso de suspensión y acción de cerrar sesión',
        (tester) async {
      bool signedOut = false;
      final data = VerificationStatusData(status: 'suspendido');

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
            onSignOut: () async {
              signedOut = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verification_status_badge')), findsOneWidget);
      expect(find.text('Suspendido'), findsOneWidget);
      expect(find.text('Cuenta Suspendida'), findsOneWidget);

      final logoutBtn = find.byKey(const ValueKey('verification_status_logout'));
      expect(logoutBtn, findsOneWidget);

      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });

    testWidgets('10. Estado nulo/desconocido: se maneja con gracia sin lanzar excepciones',
        (tester) async {
      final data = VerificationStatusData(status: 'desconocido_o_corrupto');

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: data,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verification_status_badge')), findsOneWidget);
      expect(find.text('Desconocido'), findsOneWidget);
      expect(find.text('Estado Desconocido'), findsOneWidget);
    });

    testWidgets('11. Error al cargar estado despliega reintento y se recupera',
        (tester) async {
      int fetchCount = 0;
      final service = VerificationService(
        statusFetcher: () async {
          fetchCount++;
          if (fetchCount == 1) {
            throw Exception('Error temporal de conexión');
          }
          return VerificationStatusData(
            status: 'pendiente',
            hasAllDocuments: true,
          );
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            verificationService: service,
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ha ocurrido un error'), findsOneWidget);
      final retryBtn = find.byKey(const ValueKey('verification_status_retry_btn'));
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ha ocurrido un error'), findsNothing);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(fetchCount, 2);
    });
  });

  group('Fase 3.5 — Moderación: Poner en revisión y flujo manual', () {
    test('12. ModerationService.markInReview valida rol y ejecuta decisión controlada', () async {
      bool handlerInvoked = false;
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-42',
        decisionHandler: ({required attemptId, required userId, required decision, reason}) async {
          handlerInvoked = true;
          expect(decision, 'en_revision_ia');
          return ModerationDecisionResult.success(
            updatedStatus: UserVerificationStatus.enRevisionIa,
          );
        },
      );

      final result = await service.markInReview(
        attemptId: 'att-100',
        userId: 'usr-200',
      );

      expect(handlerInvoked, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.updatedStatus, UserVerificationStatus.enRevisionIa);
    });

    testWidgets('13. ModerationDetailScreen permite poner solicitud pendiente en revisión',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sample = createSampleRequest(
        id: 'att-pending',
        userId: 'usr-1',
        status: UserVerificationStatus.pendiente,
      );

      ModerationRequest? updatedRequest;
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({required attemptId, required userId, required decision, reason}) async {
          return ModerationDecisionResult.success(
            updatedStatus: UserVerificationStatus.enRevisionIa,
          );
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
            documentImageService: createOfflineImageService(),
            documentDiagnosisService: const DocumentDiagnosisService(),
            onRequestUpdated: (req) {
              updatedRequest = req;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Muestra la insignia Pendiente
      expect(find.byKey(const ValueKey('moderation_detail_status_badge')), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);

      // Botón "Poner en revisión" visible para solicitudes pendientes
      final markInReviewBtn = find.byKey(const ValueKey('moderation_btn_mark_in_review'));
      await tester.ensureVisible(markInReviewBtn);
      await tester.pumpAndSettle();
      expect(markInReviewBtn, findsOneWidget);

      // Tocar el botón
      await tester.tap(markInReviewBtn);
      await tester.pumpAndSettle();

      // Debe haberse actualizado a en_revision_ia
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.status, UserVerificationStatus.enRevisionIa);
      expect(find.text('En revisión'), findsWidgets);

      // El botón ya no debe aparecer tras ponerse en revisión
      expect(find.byKey(const ValueKey('moderation_btn_mark_in_review')), findsNothing);
    });

    testWidgets('14. ModerationDetailScreen: aprobación manual persiste y desactiva acciones',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sample = createSampleRequest(
        id: 'att-review',
        userId: 'usr-1',
        status: UserVerificationStatus.enRevisionIa,
      );

      bool approvalExecuted = false;
      ModerationRequest? updatedRequest;
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({required attemptId, required userId, required decision, reason}) async {
          if (decision == 'aprobado') {
            approvalExecuted = true;
            return ModerationDecisionResult.success(
              updatedStatus: UserVerificationStatus.aprobado,
            );
          }
          return ModerationDecisionResult.failure(errorMessage: 'Inválido');
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
            documentImageService: createOfflineImageService(),
            documentDiagnosisService: const DocumentDiagnosisService(),
            onRequestUpdated: (req) {
              updatedRequest = req;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Botón Aprobar visible
      final approveBtn = find.byKey(const ValueKey('moderation_btn_approve'));
      await tester.ensureVisible(approveBtn);
      await tester.pumpAndSettle();
      expect(approveBtn, findsOneWidget);

      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      // Diálogo de confirmación
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Aprobar'),
      );
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(approvalExecuted, isTrue);
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.status, UserVerificationStatus.aprobado);
    });

    testWidgets('15. ModerationDetailScreen: rechazo manual exige motivo y persiste la razón',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sample = createSampleRequest(
        id: 'att-review-2',
        userId: 'usr-2',
        status: UserVerificationStatus.enRevisionIa,
      );

      String? capturedReason;
      ModerationRequest? updatedRequest;
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({required attemptId, required userId, required decision, reason}) async {
          capturedReason = reason;
          return ModerationDecisionResult.success(
            updatedStatus: UserVerificationStatus.rechazado,
            reason: reason,
          );
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
            documentImageService: createOfflineImageService(),
            documentDiagnosisService: const DocumentDiagnosisService(),
            onRequestUpdated: (req) {
              updatedRequest = req;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rejectBtn = find.byKey(const ValueKey('moderation_btn_reject'));
      await tester.ensureVisible(rejectBtn);
      await tester.pumpAndSettle();
      expect(rejectBtn, findsOneWidget);

      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      // Diálogo de rechazo
      final confirmRejectBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Rechazar'),
      );
      await tester.tap(confirmRejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('El motivo de rechazo es obligatorio.'), findsOneWidget);

      // Ingresar motivo
      final reasonField = find.byType(TextFormField);
      await tester.enterText(reasonField, 'Documento con esquinas cortadas');
      await tester.pumpAndSettle();

      await tester.tap(confirmRejectBtn);
      await tester.pumpAndSettle();

      expect(capturedReason, 'Documento con esquinas cortadas');
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.status, UserVerificationStatus.rechazado);
      expect(updatedRequest!.rejectionReason, 'Documento con esquinas cortadas');
    });

    testWidgets('16. ModerationDetailScreen: error de backend en decisión no engaña con falso éxito',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sample = createSampleRequest(
        id: 'att-error',
        userId: 'usr-3',
        status: UserVerificationStatus.pendiente,
      );

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({required attemptId, required userId, required decision, reason}) async {
          return ModerationDecisionResult.failure(
            errorMessage: 'Error 500: Database lock timeout',
            errorCode: '500',
          );
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: sample,
            moderationService: service,
            documentImageService: createOfflineImageService(),
            documentDiagnosisService: const DocumentDiagnosisService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markInReviewBtn = find.byKey(const ValueKey('moderation_btn_mark_in_review'));
      await tester.ensureVisible(markInReviewBtn);
      await tester.pumpAndSettle();

      await tester.tap(markInReviewBtn);
      await tester.pumpAndSettle();

      // Sigue estando pendiente, no cambia falsamente a en_revision_ia
      expect(find.byKey(const ValueKey('moderation_btn_mark_in_review')), findsOneWidget);
      expect(find.text('Error 500: Database lock timeout'), findsOneWidget);
    });
  });

  group('Fase 3.5 — Cola de Moderación (ModerationQueueScreen)', () {
    testWidgets('17. Muestra insignias de estado para cada ítem en la cola y filtra por estado',
        (tester) async {
      final req1 = createSampleRequest(
        id: 'item-1',
        fullName: 'Juan Pendiente',
        status: UserVerificationStatus.pendiente,
      );
      final req2 = createSampleRequest(
        id: 'item-2',
        fullName: 'Pedro En Revision',
        status: UserVerificationStatus.enRevisionIa,
      );

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        requestsFetcher: ({int limit = 50, int offset = 0, String? statusFilter}) async {
          final all = [req1, req2];
          if (statusFilter != null && statusFilter.isNotEmpty) {
            return all.where((r) => r.status.toDbValue() == statusFilter).toList();
          }
          return all;
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
      await tester.pumpAndSettle();

      // Verificamos que ambos elementos y sus chips de estado están presentes
      expect(find.text('Juan Pendiente'), findsOneWidget);
      expect(find.text('Pedro En Revision'), findsOneWidget);
      expect(find.byKey(const ValueKey('moderation_queue_item_status_item-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('moderation_queue_item_status_item-2')), findsOneWidget);

      // Verificamos los filtros
      final filterAll = find.byKey(const ValueKey('moderation_filter_all'));
      final filterPending = find.byKey(const ValueKey('moderation_filter_pending'));
      final filterInReview = find.byKey(const ValueKey('moderation_filter_in_review'));

      expect(filterAll, findsOneWidget);
      expect(filterPending, findsOneWidget);
      expect(filterInReview, findsOneWidget);

      // Seleccionar filtro "Pendientes"
      await tester.tap(filterPending);
      await tester.pumpAndSettle();

      expect(find.text('Juan Pendiente'), findsOneWidget);
      expect(find.text('Pedro En Revision'), findsNothing);

      // Seleccionar filtro "En revisión"
      await tester.tap(filterInReview);
      await tester.pumpAndSettle();

      expect(find.text('Pedro En Revision'), findsOneWidget);
      expect(find.text('Juan Pendiente'), findsNothing);

      // Regresar a "Todos"
      await tester.tap(filterAll);
      await tester.pumpAndSettle();

      expect(find.text('Juan Pendiente'), findsOneWidget);
      expect(find.text('Pedro En Revision'), findsOneWidget);
    });
  });
}
