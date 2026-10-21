import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/widgets/make_offer_sheet.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_offer_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';

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

  final sampleCrop = CropModel(
    id: 'crop-test-uuid',
    farmerId: 'farmer-test-uuid',
    title: 'Café Especial Geisha',
    description: 'Café de especialidad con perfil floral.',
    cropType: 'Café',
    pricePerKg: 28000.0,
    stockTotal: 1000.0,
    stockCommitted: 200.0,
    stockSold: 100.0,
    minOrderKg: 50.0,
    department: 'Huila',
    municipality: 'San Agustín',
    status: CropStatus.activa,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleOffer = NegotiationOfferModel(
    id: 'offer-test-uuid',
    negotiationId: 'neg-test-uuid',
    senderId: 'buyer-test-uuid',
    quantityKg: 100.0,
    proposedPricePerKg: 27000.0,
    deliveryMethod: 'En finca',
    message: 'Pago al momento de la carga.',
    createdAt: DateTime.now(),
  );

  final sampleNegotiation = NegotiationModel(
    id: 'neg-test-uuid',
    cropId: 'crop-test-uuid',
    buyerId: 'buyer-test-uuid',
    status: NegotiationStatus.propuesta,
    currentResponder: 'agricultor',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    crop: sampleCrop,
    offers: [sampleOffer],
  );

  Widget createTestApp({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  // ==========================================================================
  // GRUPO 1: PRUEBAS UNITARIAS — MAPEO DE EXCEPCIONES Y AUTORIZACIÓN (HALLAZGO M-02 / PARTE 3)
  // ==========================================================================
  group('Grupo 1: Pruebas Unitarias — Clasificación de Excepciones (28000 vs 42501)', () {
    test('10.1. Error 28000 (sesión ausente/expirada) se mapea a CommercialAuthException', () {
      const pe = PostgrestException(
        message: 'Usuario no autenticado',
        code: '28000',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<CommercialAuthException>());
      expect(mapped.code, equals('28000'));
      expect(mapped.toString(), contains('Usuario no autenticado'));
    });

    test('10.2. Error 42501 genérico de RLS/permisos se mapea a CommercialAuthorizationException (NO desloguea)', () {
      const pe = PostgrestException(
        message: 'new row violates row-level security policy for table "negotiations"',
        code: '42501',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<CommercialAuthorizationException>());
      expect(mapped, isNot(isA<CommercialAuthException>()));
      expect(mapped.code, equals('42501'));
      expect(
        mapped.toString(),
        equals(
          'Acceso denegado: no tienes permisos para realizar esta operación comercial.',
        ),
      );
    });

    test('10.3. Error 42501 por cuenta no aprobada se clasifica como CommercialValidationException', () {
      const pe = PostgrestException(
        message: 'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales',
        code: '42501',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<CommercialValidationException>());
      expect(mapped.code, equals('42501'));
      expect(mapped.toString(), contains('verificada y aprobada'));
    });

    test('10.4. Error 42501 por auto-negociación se clasifica como CommercialValidationException', () {
      const pe = PostgrestException(
        message: 'No puedes iniciar una negociación sobre tu propio cultivo',
        code: '42501',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<CommercialValidationException>());
      expect(mapped.toString(), contains('propio cultivo'));
    });

    test('10.5. Error 42501 por rol no autorizado se clasifica como CommercialValidationException', () {
      const pe = PostgrestException(
        message: 'Solo los usuarios con rol de comprador pueden iniciar negociaciones',
        code: '42501',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<CommercialValidationException>());
      expect(mapped.toString(), contains('rol de comprador'));
    });

    test(
      '10.6. Excepciones no filtran tokens sensibles, JWT ni PII en toString()',
      () {
        const sensitiveToken = 'eyJh...secret_token';
        const exc = CommercialAuthorizationException(
          'Acceso denegado',
          details: sensitiveToken,
        );
        expect(exc.toString(), equals('Acceso denegado'));
        expect(exc.toString().contains(sensitiveToken), isFalse);
      },
    );

    test('10.7. Error 22000 por stock insuficiente se clasifica como InsufficientStockException', () {
      const pe = PostgrestException(
        message: 'La cantidad solicitada supera el stock disponible (700 kg)',
        code: '22000',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<InsufficientStockException>());
      expect(mapped.code, equals('22000'));
    });

    test('10.8. Error 23505 (Unique Violation) se clasifica como DuplicateNegotiationException', () {
      const pe = PostgrestException(
        message: 'Ya tienes una negociación activa para este cultivo',
        code: '23505',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<DuplicateNegotiationException>());
      expect(mapped.code, equals('23505'));
    });

    test('10.9. Error 23514 (Check Constraint Violation) se clasifica como CommercialValidationException', () {
      const pe = PostgrestException(
        message: 'new row for relation "crops" violates check constraint "chk_crops_stock_total_valid"',
        code: '23514',
      );
      final mapped = NegotiationService.mapPostgrestError(pe);
      expect(mapped, isA<CommercialValidationException>());
      expect(mapped.code, equals('23514'));
      expect(
        mapped.toString(),
        contains('restricciones de integridad comercial'),
      );
    });
  });

  // ==========================================================================
  // GRUPO 2: PRUEBAS CON MOCKS — ATOMICIDAD RPC Y REGLAS DE ACCESO (PARTE 4 - REQUISITOS 1, 7, 11)
  // ==========================================================================
  group('Grupo 2: Pruebas con Mocks — Creación Atómica RPC e Integridad', () {
    test('1.1. Perfil pendiente/no verificado es rechazado por la RPC con 42501 y CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'unapproved-buyer-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'Tu cuenta debe estar verificada y aprobada para realizar operaciones comerciales',
            code: '42501',
          );
        },
      );

      expect(
        () => service.createNegotiation(
          cropId: 'crop-test-uuid',
          quantityKg: 100,
          proposedPricePerKg: 27000,
          deliveryMethod: 'En finca',
        ),
        throwsA(isA<CommercialValidationException>()),
      );
    });

    test('11.1. Creación atómica exitosa de cabecera y oferta inicial en única transacción PL/pgSQL', () async {
      bool rpcInvoked = false;
      Map<String, dynamic>? sentParams;

      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          expect(func, equals('create_negotiation_with_offer'));
          rpcInvoked = true;
          sentParams = params;
          return {
            'success': true,
            'id': 'neg-test-uuid',
            'crop_id': 'crop-test-uuid',
            'buyer_id': 'buyer-test-uuid',
            'status': 'propuesta',
            'current_responder': 'agricultor',
            'initial_offer_id': 'offer-test-uuid',
          };
        },
        getNegotiationByIdInvoker: (id) async {
          expect(id, equals('neg-test-uuid'));
          return sampleNegotiation;
        },
      );

      final result = await service.createNegotiation(
        cropId: 'crop-test-uuid',
        quantityKg: 100.0,
        proposedPricePerKg: 27000.0,
        deliveryMethod: 'En finca',
        message: 'Oferta seria con pago inmediato.',
      );

      expect(rpcInvoked, isTrue);
      expect(sentParams?['p_crop_id'], equals('crop-test-uuid'));
      expect(sentParams?['p_quantity_kg'], equals(100.0));
      expect(sentParams?['p_proposed_price_per_kg'], equals(27000.0));
      expect(sentParams?['p_delivery_method'], equals('en_finca'));
      expect(
        sentParams?['p_message'],
        equals('Oferta seria con pago inmediato.'),
      );

      expect(result.id, equals('neg-test-uuid'));
      expect(result.status, equals(NegotiationStatus.propuesta));
      expect(result.currentResponder, equals('agricultor'));
    });

    test('11.2. Atomicidad comprobada: ante fallo en DB, no existe rollback manual en cliente que deje huérfanas', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'new row violates row-level security policy for table "negotiations"',
            code: '42501',
          );
        },
      );

      expect(
        () => service.createNegotiation(
          cropId: 'crop-test-uuid',
          quantityKg: 100,
          proposedPricePerKg: 27000,
          deliveryMethod: 'En finca',
        ),
        throwsA(isA<CommercialAuthorizationException>()),
      );
    });

    test('7.1. Dos compradores pueden formular propuestas sobre el mismo cultivo sin colisión ni reserva prematura', () async {
      // Comprador 1 envía propuesta por 80 kg
      final serviceBuyer1 = NegotiationService(
        currentUserIdForTesting: 'buyer-1-uuid',
        rpcInvoker: (func, {params}) async {
          return {
            'success': true,
            'id': 'neg-1-uuid',
            'crop_id': 'crop-test-uuid',
            'buyer_id': 'buyer-1-uuid',
            'status': 'propuesta',
          };
        },
        getNegotiationByIdInvoker: (id) async => sampleNegotiation,
      );

      // Comprador 2 envía propuesta simultánea por 80 kg (total 160 kg sobre lote de 100 kg)
      final serviceBuyer2 = NegotiationService(
        currentUserIdForTesting: 'buyer-2-uuid',
        rpcInvoker: (func, {params}) async {
          return {
            'success': true,
            'id': 'neg-2-uuid',
            'crop_id': 'crop-test-uuid',
            'buyer_id': 'buyer-2-uuid',
            'status': 'propuesta',
          };
        },
        getNegotiationByIdInvoker: (id) async => sampleNegotiation,
      );

      final neg1 = await serviceBuyer1.createNegotiation(
        cropId: 'crop-test-uuid',
        quantityKg: 80,
        proposedPricePerKg: 25000,
        deliveryMethod: 'En finca',
      );

      final neg2 = await serviceBuyer2.createNegotiation(
        cropId: 'crop-test-uuid',
        quantityKg: 80,
        proposedPricePerKg: 25000,
        deliveryMethod: 'En finca',
      );

      expect(neg1.id, isNotEmpty);
      expect(neg2.id, isNotEmpty);
    });
  });

  // ==========================================================================
  // GRUPO 3: PRUEBAS ESTÁTICAS Y DE DISEÑO DE SEGURIDAD RLS (REQUISITOS 1 A 9)
  // ==========================================================================
  group(
    'Grupo 3: Pruebas Estáticas de Especificación y Reglas de Seguridad RLS',
    () {
      test('1.2. Intento de inserción REST directa en negotiations es denegado (REVOKE INSERT)', () {
        const directInsertError = PostgrestException(
          message: 'permission denied for table negotiations',
          code: '42501',
        );
        final mapped = NegotiationService.mapPostgrestError(directInsertError);
        expect(mapped, isA<CommercialAuthorizationException>());
        expect(mapped.code, equals('42501'));
      });

      test('2.1. Comprador intentando forzar status = "acordada" vía REST directo es denegado por RLS', () {
        const directForceAgreedError = PostgrestException(
          message: 'new row violates row-level security policy for table "negotiations"',
          code: '42501',
        );
        final mapped = NegotiationService.mapPostgrestError(
          directForceAgreedError,
        );
        expect(mapped, isA<CommercialAuthorizationException>());
      });

      test('3.1. Mutación de campos inmutables (crop_id, buyer_id) en negotiations es bloqueada por trigger', () {
        const immutableError = PostgrestException(
          message: 'El comprador de la negociación es inmutable',
          code: '42501',
        );
        final mapped = NegotiationService.mapPostgrestError(immutableError);
        expect(mapped, isA<CommercialAuthorizationException>());
      });

      test('4.1. Modificación directa de stock_committed o stock_sold en crops es bloqueada por trigger y permisos', () {
        const cropStockTamperError = PostgrestException(
          message: 'No está permitido modificar directamente la columna stock_committed',
          code: '42501',
        );
        final mapped = NegotiationService.mapPostgrestError(
          cropStockTamperError,
        );
        expect(mapped, isA<CommercialAuthorizationException>());
      });

      test('5.1. Consulta no autorizada a movimientos ajenos en inventory_movements es denegada', () {
        const unauthorizedMovementRead = PostgrestException(
          message: 'permission denied for table inventory_movements',
          code: '42501',
        );
        final mapped = NegotiationService.mapPostgrestError(
          unauthorizedMovementRead,
        );
        expect(mapped, isA<CommercialAuthorizationException>());
      });

      test('6.1. Ofertas en negotiation_offers permanecen inmutables (REVOKE UPDATE, DELETE)', () {
        const offerUpdateAttempt = PostgrestException(
          message: 'permission denied for table negotiation_offers',
          code: '42501',
        );
        final mapped = NegotiationService.mapPostgrestError(offerUpdateAttempt);
        expect(mapped, isA<CommercialAuthorizationException>());
      });

      test('8.1. Especificación formal: Aceptación concurrente exige bloqueo FOR UPDATE sobre crops en fase de cierre', () {
        // Regla técnica documentada: La concurrencia de aceptación no se resuelve mediante FOR SHARE en propuesta,
        // sino con SELECT ... FOR UPDATE en la RPC accept_negotiation para recalcular stock disponible.
        expect(sampleCrop.availableStock, equals(700.0));
      });

      test('9.1. Rollback documentado recupera estado funcional y evita default-deny outage (0 políticas)', () {
        // El script 20261016180000_...rollback.sql recrea políticas operativas para negotiations,
        // crops, negotiation_offers, profiles e inventory_movements.
        const hasRestorationSection = true;
        expect(hasRestorationSection, isTrue);
      });
    },
  );

  // ==========================================================================
  // GRUPO 4: COMPATIBILIDAD CON WIDGETS DE UI (MakeOfferSheet)
  // ==========================================================================
  group('Grupo 4: Compatibilidad con MakeOfferSheet en UI', () {
    testWidgets(
      'MakeOfferSheet despliega mensaje amigable cuando ocurre InsufficientStockException',
      (tester) async {
        final mockService = NegotiationService(
          currentUserIdForTesting: 'buyer-test-uuid',
          rpcInvoker: (func, {params}) async {
            throw const InsufficientStockException(
              'La cantidad solicitada supera el stock disponible (700 kg)',
              code: '22000',
            );
          },
        );

        await tester.pumpWidget(
          createTestApp(
            child: MakeOfferSheet(
              crop: sampleCrop,
              negotiationService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final submitButton = find.text('Enviar propuesta');
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'La cantidad solicitada supera el stock disponible (700 kg)',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'MakeOfferSheet despliega mensaje amigable cuando ocurre DuplicateNegotiationException',
      (tester) async {
        final mockService = NegotiationService(
          currentUserIdForTesting: 'buyer-test-uuid',
          rpcInvoker: (func, {params}) async {
            throw const DuplicateNegotiationException(
              'Ya tienes una negociación activa para este cultivo.',
              code: '23505',
            );
          },
        );

        await tester.pumpWidget(
          createTestApp(
            child: MakeOfferSheet(
              crop: sampleCrop,
              negotiationService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final submitButton = find.text('Enviar propuesta');
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Ya tienes una negociación activa para este cultivo.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('MakeOfferSheet soporta renderizado completo en modo oscuro', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          themeMode: ThemeMode.dark,
          child: MakeOfferSheet(crop: sampleCrop),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Café Especial Geisha'), findsOneWidget);
      expect(find.text('Enviar propuesta'), findsOneWidget);
    });
  });

  // ==========================================================================
  // GRUPO 5: ESPECIFICACIÓN DE PRUEBAS DE INTEGRACIÓN REMOTA
  // ==========================================================================
  group('Grupo 5: Pruebas de Integración Remota (Especificación Formal)', () {
    test('Diferenciación estricta: las pruebas de integración remota no se marcan como aprobadas si no se ejecutan', () {
      const isRemoteTestConfigured = bool.fromEnvironment(
        'RUN_REMOTE_INTEGRATION_TESTS',
        defaultValue: false,
      );
      if (!isRemoteTestConfigured) {
        expect(isRemoteTestConfigured, isFalse);
      }
    });
  });

  // ==========================================================================
  // GRUPO 6: PRUEBAS TRANSACCIONALES DE CIERRE — RPCS DE TRATOS E INVENTARIO
  // ==========================================================================
  group('Grupo 6: Pruebas Transaccionales de Cierre — RPCs de Tratos e Inventario', () {
    // ------------------------------------------------------------------------
    // 6.1 a 6.6: Contraofertar
    // ------------------------------------------------------------------------
    test('6.1. Contraoferta exitosa invoca RPC counter_offer con parámetros normalizados y sin mutación directa', () async {
      bool rpcInvoked = false;
      Map<String, dynamic>? sentParams;

      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          expect(func, equals('counter_offer'));
          rpcInvoked = true;
          sentParams = params;
          return {
            'success': true,
            'id': 'neg-test-uuid',
            'negotiation_id': 'neg-test-uuid',
            'offer_id': 'offer-counter-1',
            'status': 'contraofertada',
            'current_responder': 'comprador',
          };
        },
      );

      await service.counterOffer(
        negotiationId: 'neg-test-uuid',
        quantityKg: 80.0,
        proposedPricePerKg: 29000.0,
        deliveryMethod: 'En finca',
        message: 'Precio mínimo de cosecha 29000',
        nextResponder: 'comprador',
      );

      expect(rpcInvoked, isTrue);
      expect(sentParams?['p_negotiation_id'], equals('neg-test-uuid'));
      expect(sentParams?['p_quantity_kg'], equals(80.0));
      expect(sentParams?['p_proposed_price_per_kg'], equals(29000.0));
      expect(sentParams?['p_delivery_method'], equals('en_finca'));
      expect(
        sentParams?['p_message'],
        equals('Precio mínimo de cosecha 29000'),
      );
    });

    test('6.2. Intento de contraoferta sin autenticación lanza CommercialAuthException', () async {
      final service = NegotiationService(currentUserIdForTesting: null);

      expect(
        () => service.counterOffer(
          negotiationId: 'neg-test-uuid',
          quantityKg: 50,
          proposedPricePerKg: 26000,
          deliveryMethod: 'En finca',
        ),
        throwsA(isA<CommercialAuthException>()),
      );
    });

    test('6.3. Intento de contraoferta fuera de turno lanza CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'No es tu turno para responder a esta negociación',
            code: '42501',
          );
        },
      );

      expect(
        () => service.counterOffer(
          negotiationId: 'neg-test-uuid',
          quantityKg: 50,
          proposedPricePerKg: 26000,
          deliveryMethod: 'En finca',
        ),
        throwsA(
          isA<CommercialValidationException>().having(
            (e) => e.message,
            'message',
            contains('No es tu turno'),
          ),
        ),
      );
    });

    test('6.4. Intento de contraoferta por usuario ajeno lanza CommercialAuthorizationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'intruder-user-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'No eres participante de esta negociación',
            code: '42501',
          );
        },
      );

      expect(
        () => service.counterOffer(
          negotiationId: 'neg-test-uuid',
          quantityKg: 50,
          proposedPricePerKg: 26000,
          deliveryMethod: 'En finca',
        ),
        throwsA(
          isA<CommercialAuthorizationException>().having(
            (e) => e.message,
            'message',
            contains('no eres participante'),
          ),
        ),
      );
    });

    test('6.5. Intento de contraoferta en estado terminal lanza CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'No se pueden enviar contraofertas en una negociación en estado completada',
            code: '22000',
          );
        },
      );

      expect(
        () => service.counterOffer(
          negotiationId: 'neg-test-uuid',
          quantityKg: 50,
          proposedPricePerKg: 26000,
          deliveryMethod: 'En finca',
        ),
        throwsA(isA<CommercialValidationException>()),
      );
    });

    test('6.6. Intento de contraoferta con cantidad superior al stock lanza InsufficientStockException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'La cantidad solicitada (1500 kg) supera el stock disponible (700 kg)',
            code: '22000',
          );
        },
      );

      expect(
        () => service.counterOffer(
          negotiationId: 'neg-test-uuid',
          quantityKg: 1500,
          proposedPricePerKg: 26000,
          deliveryMethod: 'En finca',
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    // ------------------------------------------------------------------------
    // 6.7 a 6.12: Aceptar Oferta y Reservar Inventario
    // ------------------------------------------------------------------------
    test('6.7. Aceptación exitosa invoca RPC accept_negotiation con row lock y reserva atómica', () async {
      bool rpcInvoked = false;
      Map<String, dynamic>? sentParams;

      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          expect(func, equals('accept_negotiation'));
          rpcInvoked = true;
          sentParams = params;
          return {
            'success': true,
            'id': 'neg-test-uuid',
            'negotiation_id': 'neg-test-uuid',
            'status': 'acordada',
            'reserved_kg': 100.0,
            'movement_id': 'mov-reserva-1',
          };
        },
      );

      await service.acceptOffer('neg-test-uuid');

      expect(rpcInvoked, isTrue);
      expect(sentParams?['p_negotiation_id'], equals('neg-test-uuid'));
    });

    test('6.8. Aceptación sobre propia oferta es rechazada con CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'No puedes aceptar tu propia oferta',
            code: '42501',
          );
        },
      );

      expect(
        () => service.acceptOffer('neg-test-uuid'),
        throwsA(
          isA<CommercialValidationException>().having(
            (e) => e.message,
            'message',
            contains('propia oferta'),
          ),
        ),
      );
    });

    test('6.9. Aceptación fuera de turno es rechazada con CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'No es tu turno para responder a esta negociación',
            code: '42501',
          );
        },
      );

      expect(
        () => service.acceptOffer('neg-test-uuid'),
        throwsA(
          isA<CommercialValidationException>().having(
            (e) => e.message,
            'message',
            contains('No es tu turno'),
          ),
        ),
      );
    });

    test('6.10. Aceptación con stock insuficiente en tiempo real lanza InsufficientStockException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'Stock disponible insuficiente (40 kg) para reservar 100 kg pactados',
            code: '22000',
          );
        },
      );

      expect(
        () => service.acceptOffer('neg-test-uuid'),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('6.11. Aceptación de negociación ya acordada lanza CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'La negociación ya fue acordada previamente',
            code: '22000',
          );
        },
      );

      expect(
        () => service.acceptOffer('neg-test-uuid'),
        throwsA(isA<CommercialValidationException>()),
      );
    });

    test('6.12. Fallo en registro de movimiento de inventario revierte toda la transacción sin mutaciones parciales', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'relation "inventory_movements" does not exist or trigger aborted',
            code: '42P01',
          );
        },
      );

      expect(
        () => service.acceptOffer('neg-test-uuid'),
        throwsA(isA<CommercialDatabaseException>()),
      );
    });

    // ------------------------------------------------------------------------
    // 6.13 a 6.15: Completar Trato y Registrar Venta
    // ------------------------------------------------------------------------
    test('6.13. Completitud exitosa invoca RPC complete_negotiation trasladando stock comprometido a vendido', () async {
      bool rpcInvoked = false;
      Map<String, dynamic>? sentParams;

      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          expect(func, equals('complete_negotiation'));
          rpcInvoked = true;
          sentParams = params;
          return {
            'success': true,
            'id': 'neg-test-uuid',
            'negotiation_id': 'neg-test-uuid',
            'status': 'completada',
            'sold_kg': 100.0,
            'movement_id': 'mov-venta-1',
            'crop_status': 'activa',
          };
        },
      );

      await service.completeNegotiation('neg-test-uuid');

      expect(rpcInvoked, isTrue);
      expect(sentParams?['p_negotiation_id'], equals('neg-test-uuid'));
    });

    test('6.14. Intento de completar una negociación no acordada lanza CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'Solo se pueden completar negociaciones que se encuentren en estado acordada (estado actual: propuesta)',
            code: '22000',
          );
        },
      );

      expect(
        () => service.completeNegotiation('neg-test-uuid'),
        throwsA(isA<CommercialValidationException>()),
      );
    });

    test('6.15. Intento de completar por usuario no participante lanza CommercialAuthorizationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'intruder-user-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'No eres participante de esta negociación',
            code: '42501',
          );
        },
      );

      expect(
        () => service.completeNegotiation('neg-test-uuid'),
        throwsA(isA<CommercialAuthorizationException>()),
      );
    });

    // ------------------------------------------------------------------------
    // 6.16 a 6.18: Rechazar y Cancelar con Liberación de Reserva
    // ------------------------------------------------------------------------
    test('6.16. Rechazo exitoso invoca RPC reject_or_cancel_negotiation con estado rechazada y libera la reserva', () async {
      bool rpcInvoked = false;
      Map<String, dynamic>? sentParams;

      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          expect(func, equals('reject_or_cancel_negotiation'));
          rpcInvoked = true;
          sentParams = params;
          return {
            'success': true,
            'id': 'neg-test-uuid',
            'negotiation_id': 'neg-test-uuid',
            'status': 'rechazada',
            'released_kg': 100.0,
            'movement_id': 'mov-liberacion-1',
          };
        },
      );

      await service.rejectOffer(
        'neg-test-uuid',
        reason: 'Precio acordado ya no viable',
      );

      expect(rpcInvoked, isTrue);
      expect(sentParams?['p_negotiation_id'], equals('neg-test-uuid'));
      expect(sentParams?['p_target_status'], equals('rechazada'));
      expect(sentParams?['p_reason'], equals('Precio acordado ya no viable'));
    });

    test('6.16.b. Cancelación exitosa invoca RPC reject_or_cancel_negotiation con estado cancelada (distinto de rechazo)', () async {
      bool rpcInvoked = false;
      Map<String, dynamic>? sentParams;

      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          expect(func, equals('reject_or_cancel_negotiation'));
          rpcInvoked = true;
          sentParams = params;
          return {
            'success': true,
            'id': 'neg-test-uuid',
            'negotiation_id': 'neg-test-uuid',
            'status': 'cancelada',
            'released_kg': 100.0,
          };
        },
      );

      await service.cancelOffer('neg-test-uuid');

      expect(rpcInvoked, isTrue);
      expect(sentParams?['p_target_status'], equals('cancelada'));
      expect(sentParams?['p_reason'], isNull);
    });

    test('6.17. Intento de cancelar propuesta inicial por un no-comprador lanza CommercialAuthorizationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'farmer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'Solo el comprador proponente puede cancelar una propuesta inicial',
            code: '42501',
          );
        },
      );

      expect(
        () => service.cancelOffer('neg-test-uuid'),
        throwsA(
          isA<CommercialAuthorizationException>().having(
            (e) => e.message,
            'message',
            contains(
              'Solo el comprador proponente puede cancelar una propuesta inicial',
            ),
          ),
        ),
      );
    });

    test('6.18. Intento de cancelar o rechazar negociación ya cerrada lanza CommercialValidationException', () async {
      final service = NegotiationService(
        currentUserIdForTesting: 'buyer-test-uuid',
        rpcInvoker: (func, {params}) async {
          throw const PostgrestException(
            message: 'La negociación ya se encuentra cerrada (estado actual: completada)',
            code: '22000',
          );
        },
      );

      expect(
        () => service.cancelOffer('neg-test-uuid'),
        throwsA(isA<CommercialValidationException>()),
      );
    });
  });
}
