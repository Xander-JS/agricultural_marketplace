import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/registro/models/registration_data.dart';
import 'package:agricultural_marketplace/features/auth/registro/screens/processing_screen.dart';
import 'package:agricultural_marketplace/features/auth/registro/services/registration_service.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/services/verification_service.dart';
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';
import 'package:agricultural_marketplace/features/costs/data/simulated_regional_price_references.dart';
import 'package:agricultural_marketplace/features/costs/models/regional_price_reference.dart';
import 'package:agricultural_marketplace/features/costs/screens/crop_profitability_screen.dart';
import 'package:agricultural_marketplace/features/costs/services/crop_cost_calculator.dart';
import 'package:agricultural_marketplace/features/costs/services/regional_price_reference_service.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
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

final sampleCrop = CropModel(
  id: 'crop-stab-1',
  farmerId: 'farmer-owner-1',
  title: 'Papa Pastusa Seleccionada',
  description: 'Papa de primera calidad lista para entrega en Pasto.',
  cropType: 'Papa Pastusa',
  pricePerKg: 2500.0,
  stockTotal: 1000.0,
  stockCommitted: 0.0,
  stockSold: 0.0,
  minOrderKg: 50.0,
  department: 'Nariño',
  municipality: 'Pasto',
  status: CropStatus.activa,
  createdAt: DateTime.now().subtract(const Duration(days: 2)),
  updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
);

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

  group('Punto 1 — Referencias regionales simuladas desde Supabase', () {
    test('1.1. RegionalPriceReferenceService consulta Supabase prioritariamente', () async {
      bool supabaseCalled = false;
      final service = RegionalPriceReferenceService(
        fetcher: () async {
          supabaseCalled = true;
          return const [
            RegionalPriceReference(
              cropName: 'Papa Pastusa',
              aliases: ['Papa Pastusa'],
              region: 'Nariño, Colombia',
              referencePricePerKg: 2400.0,
              isSimulated: true,
              disclaimer: 'Referencia simulada para demostración; no corresponde a un precio oficial ni a una cotización real.',
            ),
          ];
        },
      );

      final refs = await service.getReferences();
      expect(supabaseCalled, isTrue);
      expect(refs, isNotEmpty);
      expect(refs.first.cropName, equals('Papa Pastusa'));
      expect(refs.first.referencePricePerKg, equals(2400.0));
    });

    test('1.2. RegionalPriceReferenceService recurre a fallback local ante desconexión o lista vacía', () async {
      final service = RegionalPriceReferenceService(
        fetcher: () async => throw Exception('Network timeout'),
      );

      final ref = await service.findForCrop(
        cropType: 'Papa Pastusa',
        title: 'Papa Pastusa Seleccionada',
      );

      expect(ref, isNotNull);
      expect(ref!.referencePricePerKg, equals(2200.0)); // Precio del fallback local
      expect(ref.region, contains('Nariño'));
    });

    testWidgets('1.3. CropProfitabilityScreen muestra la referencia y la etiqueta obligatoria',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CropProfitabilityScreen(
            crop: sampleCrop,
            costPerKgResult: const CropCostPerKgResult(
              status: CropCostPerKgStatus.calculated,
              costPerKg: 1800.0,
              denominator: 1000.0,
              denominatorSource: CropCostDenominatorSource.stockTotal,
              message: 'Costo calculado',
            ),
            initialReference: const RegionalPriceReference(
              cropName: 'Papa Pastusa',
              aliases: ['Papa Pastusa'],
              region: 'Nariño, Colombia',
              referencePricePerKg: 2300.0,
              isSimulated: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Índice de referencia regional (Nariño)'), findsOneWidget);
      expect(find.text(SimulatedRegionalPriceReferences.notice), findsNothing);
      expect(find.text('PROYECCIÓN IA'), findsOneWidget);
    });

    testWidgets('1.4. CropDetailScreen muestra banner de referencia regional con disclaimer obligatorio',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'comprador',
            isOwner: false,
            initialRegionalReference: const RegionalPriceReference(
              cropName: 'Papa Pastusa',
              aliases: ['Papa Pastusa'],
              region: 'Nariño, Colombia',
              referencePricePerKg: 2200.0,
              isSimulated: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('crop_detail_regional_reference_card')), findsOneWidget);
      expect(find.text('PROYECCIÓN IA'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('crop_detail_regional_reference_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('crop_detail_regional_reference_card')));
      await tester.pumpAndSettle();
      expect(find.text(SimulatedRegionalPriceReferences.notice), findsOneWidget);
    });
  });

  group('Punto 2 — Persistencia atómica de registro y cola de moderación', () {
    test('2.1. RegistrationService asegura inserción obligatoria en profiles con estado pendiente antes de attempts',
        () async {
      final executionOrder = <String>[];
      Map<String, dynamic>? savedProfile;
      Map<String, dynamic>? savedAttempt;

      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          executionOrder.add('signUp');
          final user = User(
            id: 'uuid-atomic-user',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          );
          final session = createMockSession(userId: 'uuid-atomic-user');
          return AuthResponse(session: session, user: user);
        },
        profileUpserter: (profileData) async {
          executionOrder.add('profileUpsert');
          savedProfile = profileData;
        },
        storageUploader: (bucket, path, file) async {
          executionOrder.add('storageUpload');
          return path;
        },
        verificationAttemptSaver: (attemptData) async {
          executionOrder.add('attemptInsert');
          savedAttempt = attemptData;
        },
      );

      final dummyFront = File('${Directory.systemTemp.path}/front.jpg')..writeAsStringSync('front');
      final dummyBack = File('${Directory.systemTemp.path}/back.jpg')..writeAsStringSync('back');
      final dummySelfie = File('${Directory.systemTemp.path}/selfie.jpg')..writeAsStringSync('selfie');

      final result = await service.registerUser(
        phone: '3109998877',
        firstName: 'Pedro',
        lastName: 'Pasto',
        password: 'Password123!',
        role: 'agricultor',
        documentFront: dummyFront,
        documentBack: dummyBack,
        selfie: dummySelfie,
      );

      expect(result.success, isTrue);
      // profiles DEBE insertarse antes de verification_attempts para evitar error 23503
      expect(executionOrder, containsAllInOrder(['signUp', 'profileUpsert', 'attemptInsert']));

      expect(savedProfile, isNotNull);
      expect(savedProfile!['id'], equals('uuid-atomic-user'));
      // El perfil nace en 'pendiente'; pasa a 'en_revision_ia' solo tras la aprobación del moderador.
      expect(savedProfile!['verification_status'], equals('pendiente'));

      expect(savedAttempt, isNotNull);
      expect(savedAttempt!['user_id'], equals('uuid-atomic-user'));
      expect(savedAttempt!['status'], equals('pendiente'));
      expect(savedAttempt!['ai_result'], isNull);
    });

    test('2.2. Si falla la inserción en profiles o verification_attempts, arroja error y no finge éxito', () async {
      final service = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          final user = User(
            id: 'uuid-fail-user',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          );
          return AuthResponse(session: createMockSession(userId: 'uuid-fail-user'), user: user);
        },
        profileUpserter: (profileData) async {
          throw const PostgrestException(message: 'Database connection failed 500');
        },
      );

      expect(
        () => service.registerUser(
          phone: '3109998877',
          firstName: 'Pedro',
          lastName: 'Pasto',
          password: 'Password123!',
          role: 'agricultor',
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('2.3. ProcessingScreen muestra el error en pantalla en lugar de fingir éxito', (tester) async {
      final regData = RegistrationData()
        ..phone = '3109998877'
        ..firstName = 'Pedro'
        ..lastName = 'Pasto'
        ..password = 'Password123!'
        ..role = 'agricultor'
        ..documentType = 'CC'
        ..documentFront = (File('${Directory.systemTemp.path}/front.jpg')..writeAsStringSync('f'))
        ..documentBack = (File('${Directory.systemTemp.path}/back.jpg')..writeAsStringSync('b'))
        ..selfie = (File('${Directory.systemTemp.path}/selfie.jpg')..writeAsStringSync('s'));

      final failingService = RegistrationService(
        signUpInvoker: ({required email, required password, data}) async {
          throw Exception('Foreign key violation 23503');
        },
      );

      await tester.pumpWidget(
        createTestApp(
          child: ProcessingScreen(
            data: regData,
            registrationService: failingService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Error al procesar el registro'),
        findsOneWidget,
      );
      expect(find.textContaining('Foreign key violation 23503'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('Punto 3 — Control de acceso y pantalla de espera por estados de verificación', () {
    testWidgets('3.1. Estado en_revision_ia bloquea operaciones y muestra mensaje oficial', (tester) async {
      final session = createMockSession(userId: 'u-en-revision');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('en-revision-gate'),
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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
      expect(
        find.text('Análisis preliminar de IA completado; tu cuenta está en revisión final por parte de un moderador.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('verification_status_refresh')), findsOneWidget);
    });

    testWidgets('3.2. Estado pendiente redirige a completar la carga de documentos', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: VerificationStatusData(
              status: 'pendiente',
              role: 'agricultor',
              hasAllDocuments: false,
            ),
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('verification_upload_documents')), findsOneWidget);
      expect(find.text('Subir Documentos'), findsOneWidget);
    });

    testWidgets('3.3. Estado rechazado muestra motivo y botón para volver a enviar documentos', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: VerificationStatusData(
              status: 'rechazado',
              role: 'agricultor',
              rejectionReason: 'La fotografía de la cédula no es legible.',
            ),
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('La fotografía de la cédula no es legible.'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_upload_documents')), findsOneWidget);
    });

    testWidgets('3.4. Estado suspendido muestra aviso de suspensión sin acceso a operaciones', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            initialData: VerificationStatusData(
              status: 'suspendido',
              role: 'agricultor',
            ),
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Cuenta Suspendida'), findsOneWidget);
      expect(find.byKey(const ValueKey('verification_upload_documents')), findsNothing);
      expect(find.byKey(const ValueKey('verification_status_refresh')), findsNothing);
      expect(find.byKey(const ValueKey('verification_status_logout')), findsOneWidget);
    });

    testWidgets('3.5. Al refrescar y detectar aprobación, transiciona inmediatamente a la aplicación', (tester) async {
      var currentStatus = 'en_revision_ia';
      bool enteredDashboard = false;

      final verificationService = VerificationService(
        statusFetcher: () async => VerificationStatusData(
          status: currentStatus,
          role: 'agricultor',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: VerificationStatusScreen(
            verificationService: verificationService,
            enableAutoPolling: false,
            onVerificationApproved: (data) {
              enteredDashboard = true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Análisis preliminar de IA completado; tu cuenta está en revisión final por parte de un moderador.'), findsOneWidget);

      // Simular que el moderador aprobó la cuenta en base de datos
      currentStatus = 'aprobado';

      // Presionar el botón de refresco
      await tester.tap(find.byKey(const ValueKey('verification_status_refresh')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(enteredDashboard, isTrue);
    });
  });
}
