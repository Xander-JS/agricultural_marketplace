import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/constants/user_roles.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/screens/verification_status_screen.dart';
import 'package:agricultural_marketplace/features/auth/widgets/auth_gate.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/publish_crop_screen.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';
import 'package:agricultural_marketplace/features/deals/exceptions/commercial_exception.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_offer_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/screens/deals_screen.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';
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

final sampleCrop = CropModel(
  id: 'crop-p36-1',
  farmerId: 'farmer-owner-1',
  title: 'Papa Pastusa Seleccionada',
  description: 'Papa de primera calidad lista para entrega en Pasto.',
  cropType: 'Papa',
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

final sampleNegotiation = NegotiationModel(
  id: 'neg-p36-1',
  cropId: 'crop-p36-1',
  buyerId: 'buyer-user-1',
  status: NegotiationStatus.propuesta,
  currentResponder: 'farmer',
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
  crop: sampleCrop,
  buyerProfile: {'full_name': 'Distribuidora del Sur'},
  farmerProfile: {'full_name': 'Finca Don Pedro'},
  offers: [
    NegotiationOfferModel(
      id: 'offer-p36-1',
      negotiationId: 'neg-p36-1',
      senderId: 'buyer-user-1',
      quantityKg: 200.0,
      proposedPricePerKg: 2400.0,
      deliveryMethod: 'Recogida en finca',
      message: 'Oferta seria para entrega inmediata.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
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

  group('Fase 3.6 — Control Funcional por Rol y Propiedad (CropService)', () {
    test('1. Comprador no puede crear ni editar cosechas a nivel de servicio', () async {
      final service = CropService(
        currentUserRoleFetcher: () async => UserRole.comprador.name,
        currentUserIdFetcher: () => 'buyer-id-1',
      );

      expect(
        () => service.saveCrop(sampleCrop),
        throwsA(isA<CommercialAuthorizationException>()),
      );
    });

    test('2. Moderador no puede crear ni gestionar publicaciones comerciales', () async {
      final service = CropService(
        currentUserRoleFetcher: () async => UserRole.moderador.name,
        currentUserIdFetcher: () => 'moderator-id-1',
      );

      expect(
        () => service.saveCrop(sampleCrop),
        throwsA(isA<CommercialAuthorizationException>()),
      );
      expect(
        () => service.updateCropStatus('crop-1', CropStatus.pausada),
        throwsA(isA<CommercialAuthorizationException>()),
      );
      expect(
        () => service.deleteCrop('crop-1'),
        throwsA(isA<CommercialAuthorizationException>()),
      );
    });

    test('3. Agricultor no puede editar ni borrar cosechas pertenecientes a otro productor', () async {
      final service = CropService(
        currentUserRoleFetcher: () async => UserRole.agricultor.name,
        currentUserIdFetcher: () => 'farmer-other-2',
      );

      // Intenta editar una cosecha existente cuyo farmerId es 'farmer-owner-1'
      expect(
        () => service.saveCrop(sampleCrop),
        throwsA(isA<CommercialAuthorizationException>()),
      );
    });
  });

  group('Fase 3.6 — Interfaz y Navegación según Rol y Propiedad', () {
    testWidgets('4. PublishCropScreen bloquea el acceso si el rol es comprador', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const PublishCropScreen(role: 'comprador'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso No Autorizado'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_outlined), findsOneWidget);
      expect(find.text('1. Información General'), findsNothing);
    });

    testWidgets('5. PublishCropScreen bloquea el acceso si el rol es moderador', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const PublishCropScreen(role: 'moderador'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso No Autorizado'), findsOneWidget);
      expect(find.text('1. Información General'), findsNothing);
    });

    testWidgets('6. CropDetailScreen para Comprador muestra opción de negociar y oculta gestión de cosecha',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'comprador',
            isOwner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el botón para hacer oferta / negociar
      expect(find.text('Hacer oferta / Negociar'), findsOneWidget);

      // NO debe mostrar los botones exclusivos del productor dueño
      expect(find.text('Pausar Publicación'), findsNothing);
      expect(find.text('Activar Publicación'), findsNothing);
      expect(find.text('Ver Negociaciones'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('7. CropDetailScreen para Productor dueño conecta a DealsScreen mediante Ver Negociaciones',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'agricultor',
            isOwner: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar botón de Pausar Publicación y Ver Negociaciones
      expect(find.text('Pausar Publicación'), findsOneWidget);
      final negotiationsBtn = find.byKey(const Key('crop_detail_farmer_negotiations_button'));
      expect(negotiationsBtn, findsOneWidget);

      // NO debe mostrar la opción de hacer oferta sobre su propio cultivo
      expect(find.text('Hacer oferta / Negociar'), findsNothing);

      // Al pulsar "Ver Negociaciones", navega a DealsScreen
      await tester.ensureVisible(negotiationsBtn);
      await tester.tap(negotiationsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DealsScreen), findsOneWidget);
      expect(find.text('Tratos'), findsOneWidget);
    });
  });

  group('Fase 3.6 — Catálogo Comercial y Manejo de Estados', () {
    testWidgets('8. MarketplaceScreen muestra cosechas activas y navega al detalle', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: MarketplaceScreen(
            role: 'comprador',
            initialCrops: [sampleCrop],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Papa Pastusa Seleccionada'), findsOneWidget);
      expect(find.text('Pasto'), findsOneWidget);

      // Al pulsar sobre la tarjeta de la cosecha, abre CropDetailScreen
      await tester.tap(find.text('Papa Pastusa Seleccionada'));
      await tester.pumpAndSettle();

      expect(find.byType(CropDetailScreen), findsOneWidget);
      expect(find.text('Papa Pastusa Seleccionada'), findsOneWidget);
    });

    testWidgets('9. MarketplaceScreen maneja lista vacía para comprador', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MarketplaceScreen(
            role: 'comprador',
            initialCrops: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay cosechas disponibles'), findsOneWidget);
    });
  });

  group('Fase 3.6 — Ciclo Completo de Autenticación, Verificación y Moderación', () {
    testWidgets('10. Usuario pendiente es retenido en VerificationStatusScreen', (tester) async {
      final session = createMockSession(userId: 'user-pending-123');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('pending-test-gate'),
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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    testWidgets('11. Usuario aprobado con rol agricultor accede a MainDashboardScreen', (tester) async {
      final session = createMockSession(userId: 'user-approved-farmer');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('approved-farmer-gate'),
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
      expect(find.text('Costos'), findsOneWidget);
    });

    testWidgets('12. Usuario con rol moderador accede a ModerationQueueScreen', (tester) async {
      final session = createMockSession(userId: 'user-moderator-1');

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
            enableAutoPolling: false,
            moderationService: ModerationService(
              currentUserRoleFetcher: () async => UserRole.moderador,
              currentUserIdFetcher: () => 'user-moderator-1',
              requestsFetcher: ({int limit = 50, int offset = 0, String? statusFilter}) async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModerationQueueScreen), findsOneWidget);
      expect(find.text('Cola de Moderación'), findsOneWidget);
      expect(find.byType(MainDashboardScreen), findsNothing);
    });

    testWidgets('13. Decisión de moderación (Aprobar) persiste estado y habilita acceso', (tester) async {
      var persistedStatus = 'pendiente';

      final moderationService = ModerationService(
        currentUserRoleFetcher: () async => UserRole.moderador,
        currentUserIdFetcher: () => 'mod-1',
        decisionHandler: ({
          required String attemptId,
          required String userId,
          required String decision,
          String? reason,
        }) async {
          persistedStatus = 'aprobado';
          return ModerationDecisionResult.success(
            updatedStatus: UserVerificationStatus.aprobado,
          );
        },
      );

      // 1. Ejecutar aprobación de solicitud
      final result = await moderationService.approveRequest(
        attemptId: 'attempt-101',
        userId: 'farmer-applicant-1',
      );

      expect(result.isSuccess, isTrue);
      expect(persistedStatus, equals('aprobado'));

      // 2. Con el estado actualizado en base de datos, el AuthGate del usuario abre MainDashboardScreen
      final farmerSession = createMockSession(userId: 'farmer-applicant-1');

      await tester.pumpWidget(
        createTestApp(
          child: AuthGate(
            key: const ValueKey('dynamically-approved-gate'),
            initialSession: farmerSession,
            profileFetcher: (userId) async => {
              'id': userId,
              'role': 'agricultor',
              'verification_status': persistedStatus,
            },
            enableAutoPolling: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(VerificationStatusScreen), findsNothing);
    });
  });
}
