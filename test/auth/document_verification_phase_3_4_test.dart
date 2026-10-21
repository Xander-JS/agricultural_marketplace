import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/registro/models/registration_data.dart';
import 'package:agricultural_marketplace/features/auth/registro/screens/document_review_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/document_upload_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/services/document_submission_service.dart';
import 'package:agricultural_marketplace/features/auth/widgets/document_image_picker.dart';
import 'package:agricultural_marketplace/features/auth/widgets/document_selection_card.dart';
import 'package:agricultural_marketplace/features/moderation/models/moderation_request.dart';
import 'package:agricultural_marketplace/features/moderation/screens/moderation_detail_screen.dart';
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
    home: child,
  );
}

ModerationRequest createDiagnosisRequest({
  String? front = 'user-1/front_1.jpg',
  String? back = 'user-1/back_1.jpg',
  String? selfie = 'user-1/selfie_1.jpg',
  String phone = '+573001112233',
  String email = 'persona@example.com',
}) {
  return ModerationRequest(
    id: 'attempt-34',
    userId: 'user-1',
    fullName: 'Persona de Prueba',
    phone: phone,
    email: email,
    userRole: UserRole.agricultor,
    status: UserVerificationStatus.pendiente,
    documentFrontPath: front,
    documentBackPath: back,
    selfiePath: selfie,
    createdAt: DateTime.utc(2026, 10, 20),
  );
}

DocumentImageSelector selectorWithQueue(List<File> files) {
  var index = 0;
  return (source, {preferredCameraDevice = CameraDevice.rear}) async {
    if (index >= files.length) return null;
    return files[index++];
  };
}

Future<void> pickFromGallery(WidgetTester tester, String cardKey) async {
  await tester.tap(find.byKey(ValueKey(cardKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('document_pick_gallery_option')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 3.4 — Diagnóstico documental simulado', () {
    test('1. Con las tres imágenes presentes el informe sigue siendo SIMULADO y manual', () {
      const service = DocumentDiagnosisService();
      final report = service.build(createDiagnosisRequest());

      expect(report.isSimulated, isTrue);
      expect(report.requiresManualReview, isTrue);
      expect(report.canAutoApprove, isFalse);
      expect(report.hasAllRequiredDocuments, isTrue);
      expect(report.availableDocuments, 3);
      expect(report.missingDocumentTypes, isEmpty);
      expect(
        report.observations,
        contains(DocumentDiagnosisObservation.manualProfileReview),
      );
    });

    test('2. Detecta documentos faltantes y rutas inválidas sin inventar resultados', () {
      const service = DocumentDiagnosisService();
      final report = service.build(
        createDiagnosisRequest(
          back: null,
          selfie: 'https://public.example.com/selfie.jpg',
        ),
      );

      expect(report.hasAllRequiredDocuments, isFalse);
      expect(report.availableDocuments, 1);
      expect(
        report.missingDocumentTypes,
        containsAll([
          DocumentDiagnosisDocumentType.back,
          DocumentDiagnosisDocumentType.selfie,
        ]),
      );
      expect(
        report.observations,
        contains(DocumentDiagnosisObservation.missingDocuments),
      );
      expect(report.canAutoApprove, isFalse);
      expect(DocumentPathValidator.isValid('../privado.jpg'), isFalse);
      expect(DocumentPathValidator.isValid('/absoluta.jpg'), isFalse);
      expect(DocumentPathValidator.isValid('user-1/front.jpg'), isTrue);
    });

    test('3. Detecta rutas duplicadas y ausencia de correo como revisión manual', () {
      const service = DocumentDiagnosisService();
      final report = service.build(
        createDiagnosisRequest(
          front: 'user-1/misma.jpg',
          back: 'user-1/misma.jpg',
          email: '',
        ),
      );

      expect(
        report.observations,
        contains(DocumentDiagnosisObservation.sharedDocumentPaths),
      );
      expect(
        report.observations,
        contains(DocumentDiagnosisObservation.emailNotProvided),
      );
      expect(report.canAutoApprove, isFalse);
    });
  });

  group('Fase 3.4 — URLs firmadas de documentos privados', () {
    test('4. Rechaza rutas inválidas antes de solicitar una URL firmada', () async {
      var calls = 0;
      final service = DocumentImageUrlService(
        signer: (bucket, path, expires) async {
          calls++;
          return 'https://signed.example/document';
        },
      );

      final result = await service.createSignedUrl('../secreto.jpg');

      expect(result.isSuccess, isFalse);
      expect(calls, 0);
      expect(service.bucket, 'user_documents');
    });

    test('5. Devuelve la URL firmada y encapsula errores de red', () async {
      final success = DocumentImageUrlService(
        signer: (bucket, path, expires) async {
          expect(bucket, 'user_documents');
          expect(expires, greaterThan(0));
          return 'https://signed.example/document';
        },
      );
      final failed = DocumentImageUrlService(
        signer: (bucket, path, expires) async => throw Exception('network'),
      );

      expect(
        (await success.createSignedUrl('user-1/front.jpg')).url,
        'https://signed.example/document',
      );
      expect(
        (await failed.createSignedUrl('user-1/front.jpg')).isSuccess,
        isFalse,
      );
    });
  });

  group('Fase 3.4 — Envío de documentos', () {
    late Directory tempDir;
    late File front;
    late File back;
    late File selfie;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('phase34_docs_');
      front = File('${tempDir.path}/front.jpg')..writeAsBytesSync([1, 2, 3]);
      back = File('${tempDir.path}/back.jpg')..writeAsBytesSync([1, 2, 3]);
      selfie = File('${tempDir.path}/selfie.jpg')..writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('6. Sube las tres imágenes y registra la solicitud pendiente', () async {
      final uploads = <String>[];
      Map<String, dynamic>? savedAttempt;

      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        now: () => DateTime.utc(2026, 10, 20, 12),
        uploader: (bucket, path, file) async {
          expect(bucket, 'user_documents');
          uploads.add(path);
        },
        attemptInserter: (attemptData) async {
          savedAttempt = attemptData;
        },
      );

      final result = await service.submitDocuments(
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isTrue);
      expect(uploads.length, 3);
      expect(uploads[0], startsWith('user-123/front_'));
      expect(uploads[1], startsWith('user-123/back_'));
      expect(uploads[2], startsWith('user-123/selfie_'));
      expect(savedAttempt, isNotNull);
      expect(savedAttempt!['user_id'], 'user-123');
      expect(savedAttempt!['status'], 'pendiente');
      expect(savedAttempt!['document_front_path'], uploads[0]);
      expect(savedAttempt!['document_back_path'], uploads[1]);
      expect(savedAttempt!['selfie_path'], uploads[2]);
      expect(savedAttempt!.containsKey('reviewed_by'), isFalse);
      expect(savedAttempt!.containsKey('ocr_result'), isFalse);
    });

    test('7. No sube nada si falta una de las tres imágenes', () async {
      var uploadCalls = 0;
      var attemptCalls = 0;
      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async => uploadCalls++,
        attemptInserter: (_) async => attemptCalls++,
      );

      final result = await service.submitDocuments(
        documentFront: front,
        documentBack: null,
        selfie: selfie,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, DocumentSubmissionFailure.missingDocuments);
      expect(uploadCalls, 0);
      expect(attemptCalls, 0);
    });

    test('8. Un fallo de carga no registra la solicitud y limpia solo lo recién subido', () async {
      final uploads = <String>[];
      final removed = <String>[];
      var attemptCalls = 0;

      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async {
          uploads.add(path);
          if (uploads.length == 2) throw Exception('storage');
        },
        remover: (bucket, paths) async => removed.addAll(paths),
        attemptInserter: (_) async => attemptCalls++,
      );

      final result = await service.submitDocuments(
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, DocumentSubmissionFailure.storage);
      expect(attemptCalls, 0);
      expect(removed, [uploads.first]);
      expect(removed.length, 1);
    });

    test('9. Un fallo al insertar la solicitud limpia las cargas nuevas', () async {
      final uploads = <String>[];
      final removed = <String>[];

      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async => uploads.add(path),
        remover: (bucket, paths) async => removed.addAll(paths),
        attemptInserter: (_) async => throw Exception('database'),
      );

      final result = await service.submitDocuments(
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, DocumentSubmissionFailure.attempt);
      expect(removed, uploads);
      expect(removed.length, 3);
    });

    test('10. Impide envíos simultáneos duplicados', () async {
      final uploadGate = Completer<void>();
      var uploadCalls = 0;

      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async {
          uploadCalls++;
          await uploadGate.future;
        },
        attemptInserter: (_) async {},
      );

      final first = service.submitDocuments(
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );
      final second = await service.submitDocuments(
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(second.failure, DocumentSubmissionFailure.inProgress);
      uploadGate.complete();
      final firstResult = await first;
      expect(firstResult.isSuccess, isTrue);
      expect(uploadCalls, 3);
    });
  });

  group('Fase 3.4 — Revisión previa al registro', () {
    late Directory tempDir;
    late File front;
    late File back;
    late File selfie;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('phase34_review_');
      front = File('${tempDir.path}/front.jpg')..writeAsBytesSync([1, 2, 3]);
      back = File('${tempDir.path}/back.jpg')..writeAsBytesSync([1, 2, 3]);
      selfie = File('${tempDir.path}/selfie.jpg')..writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    RegistrationData completeData() {
      return RegistrationData()
        ..phone = '3151234567'
        ..firstName = 'Ana'
        ..lastName = 'Prueba'
        ..password = 'Password123!'
        ..role = 'agricultor'
        ..documentType = 'CC'
        ..documentFront = front
        ..documentBack = back
        ..selfie = selfie;
    }

    testWidgets('11. Impide continuar si faltan documentos', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var submitted = false;
      final data = RegistrationData()
        ..phone = '3151234567'
        ..firstName = 'Ana'
        ..lastName = 'Prueba'
        ..password = 'Password123!'
        ..role = 'agricultor'
        ..documentType = 'CC';

      await tester.pumpWidget(
        createTestApp(
          child: DocumentReviewScreen(
            data: data,
            onSubmit: () async => submitted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Enviar documentos'));
      await tester.tap(find.text('Enviar documentos'));
      await tester.pump();

      expect(
        find.text('Debes adjuntar el frente, el reverso y la selfie antes de enviar.'),
        findsOneWidget,
      );
      expect(submitted, isFalse);
    });

    testWidgets('12. Permite revisar las tres imágenes y reemplazar una antes de enviar',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var submitted = false;
      final replacement =
          File('${tempDir.path}/replacement.jpg')..writeAsBytesSync([4, 5, 6]);

      await tester.pumpWidget(
        createTestApp(
          child: DocumentReviewScreen(
            data: completeData(),
            imageSelector: selectorWithQueue([replacement]),
            onSubmit: () async => submitted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Las tres imágenes están listas para enviar.'), findsOneWidget);

      await pickFromGallery(tester, 'document_review_front_pick');

      final frontCard = tester.widget<DocumentSelectionCard>(
        find.byKey(const ValueKey('document_review_front')),
      );
      expect(frontCard.file?.path, replacement.path);

      await tester.ensureVisible(find.text('Enviar documentos'));
      await tester.tap(find.text('Enviar documentos'));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });
  });

  group('Fase 3.4 — Carga de documentos posterior al registro', () {
    late Directory tempDir;
    late File front;
    late File back;
    late File selfie;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('phase34_upload_');
      front = File('${tempDir.path}/front.jpg')..writeAsBytesSync([1, 2, 3]);
      back = File('${tempDir.path}/back.jpg')..writeAsBytesSync([1, 2, 3]);
      selfie = File('${tempDir.path}/selfie.jpg')..writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> selectAll(WidgetTester tester) async {
      await pickFromGallery(tester, 'document_upload_front_pick');
      await pickFromGallery(tester, 'document_upload_back_pick');
      await pickFromGallery(tester, 'document_upload_selfie_pick');
    }

    testWidgets('13. Valida que estén las tres imágenes antes de enviar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var uploadCalls = 0;
      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async => uploadCalls++,
        attemptInserter: (_) async {},
      );

      await tester.pumpWidget(
        createTestApp(
          child: DocumentUploadScreen(submissionService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('document_upload_submit')));
      await tester.pump();

      expect(
        find.text('Debes adjuntar el frente, el reverso y la selfie antes de enviar.'),
        findsOneWidget,
      );
      expect(uploadCalls, 0);
    });

    testWidgets('14. Muestra carga, evita duplicados y confirma el éxito', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final gate = Completer<void>();
      var uploadCalls = 0;

      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async {
          uploadCalls++;
          await gate.future;
        },
        attemptInserter: (_) async {},
      );

      await tester.pumpWidget(
        createTestApp(
          child: DocumentUploadScreen(
            submissionService: service,
            imageSelector: selectorWithQueue([front, back, selfie]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await selectAll(tester);

      await tester.tap(find.byKey(const ValueKey('document_upload_submit')));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Cargando documentos...'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('document_upload_submit')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(uploadCalls, 1);

      gate.complete();
      await tester.pumpAndSettle();

      expect(uploadCalls, 3);
      expect(find.text('Documentos enviados'), findsOneWidget);
      expect(
        find.text('Tu solicitud quedó registrada y está pendiente de revisión manual.'),
        findsOneWidget,
      );
    });

    testWidgets('15. Un fallo de carga muestra error y conserva las imágenes', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final service = DocumentSubmissionService(
        userIdFetcher: () => 'user-123',
        uploader: (bucket, path, file) async => throw Exception('storage'),
        attemptInserter: (_) async {},
      );

      await tester.pumpWidget(
        createTestApp(
          child: DocumentUploadScreen(
            submissionService: service,
            imageSelector: selectorWithQueue([front, back, selfie]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await selectAll(tester);

      await tester.tap(find.byKey(const ValueKey('document_upload_submit')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No se pudieron cargar las imágenes al almacenamiento privado. Revisa tu conexión e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Documentos enviados'), findsNothing);
      expect(find.text('Seleccionada'), findsNWidgets(3));
    });
  });

  group('Fase 3.4 — Interfaz de moderación y decisión manual', () {
    testWidgets('16. Muestra frente, reverso y selfie por separado y el informe SIMULADO',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var decisions = 0;
      final imageService = DocumentImageUrlService(
        signer: (bucket, path, expires) async =>
            'https://signed.example/$path',
      );

      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'moderator-1',
        decisionHandler: ({
          required attemptId,
          required userId,
          required decision,
          reason,
        }) async {
          decisions++;
          return ModerationDecisionResult.success(
            updatedStatus: UserVerificationStatus.fromString(decision),
            reason: reason,
          );
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: createDiagnosisRequest(),
            moderationService: service,
            documentImageService: imageService,
            documentImageBuilder: (context, url) => const Icon(
              Icons.image_outlined,
              key: ValueKey('mocked_document_image'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('moderation_document_front')), findsOneWidget);
      expect(find.byKey(const ValueKey('moderation_document_back')), findsOneWidget);
      expect(find.byKey(const ValueKey('moderation_document_selfie')), findsOneWidget);
      expect(find.byKey(const ValueKey('mocked_document_image')), findsNWidgets(3));
      expect(find.text('Documento disponible para revisión'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('moderation_diagnosis_simulated_badge')), findsOneWidget);
      expect(find.text('SIMULADO'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('moderation_diagnosis_pending_human')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('moderation_diagnosis_no_auto')),
        findsOneWidget,
      );
      expect(decisions, 0);
    });

    testWidgets('17. Identifica documentos faltantes y rutas inválidas en el detalle',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: createDiagnosisRequest(
              back: null,
              selfie: '../invalida.jpg',
            ),
            documentImageService: DocumentImageUrlService(
              signer: (bucket, path, expires) async =>
                  'https://signed.example/$path',
            ),
            documentImageBuilder: (context, url) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Documento no proporcionado'), findsWidgets);
      expect(find.text('Ruta de documento no válida o no disponible'), findsWidgets);
      expect(find.text('Faltante'), findsNWidgets(2));
    });

    testWidgets('18. El diagnóstico no dispara aprobación; el moderador decide manualmente',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var approvalCalls = 0;
      final service = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'moderator-1',
        decisionHandler: ({
          required attemptId,
          required userId,
          required decision,
          reason,
        }) async {
          approvalCalls++;
          return ModerationDecisionResult.success(
            updatedStatus: UserVerificationStatus.aprobado,
          );
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ModerationDetailScreen(
            request: createDiagnosisRequest(),
            moderationService: service,
            documentImageService: DocumentImageUrlService(
              signer: (bucket, path, expires) async =>
                  'https://signed.example/$path',
            ),
            documentImageBuilder: (context, url) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(approvalCalls, 0);

      await tester.ensureVisible(find.text('Aprobar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar Aprobación'), findsOneWidget);
      expect(approvalCalls, 0);

      final approveInDialog = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Aprobar'),
      );
      await tester.tap(approveInDialog);
      await tester.pumpAndSettle();

      expect(approvalCalls, 1);
    });
  });
}
