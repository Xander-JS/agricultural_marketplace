import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/screens/deal_detail_screen.dart';
import 'package:agricultural_marketplace/features/deals/services/negotiation_service.dart';
import 'package:agricultural_marketplace/features/review/models/review_model.dart';
import 'package:agricultural_marketplace/features/review/services/review_service.dart';

class _FakeReviewService extends ReviewService {
  _FakeReviewService({
    this.alreadyReviewed = false,
    this.checkError,
    this.submitError,
    String userId = 'buyer-001',
  }) : super(currentUserIdForTesting: userId);

  bool alreadyReviewed;
  Object? checkError;
  Object? submitError;
  int checkCalls = 0;
  int submitCalls = 0;
  int? submittedRating;
  String? submittedComment;

  @override
  Future<bool> hasReviewedNegotiation(String negotiationId) async {
    checkCalls++;
    if (checkError != null) throw checkError!;
    return alreadyReviewed;
  }

  @override
  Future<ReviewModel> submitReview({
    required String negotiationId,
    required int rating,
    String? comment,
  }) async {
    submitCalls++;
    submittedRating = rating;
    submittedComment = comment;
    if (submitError != null) throw submitError!;
    alreadyReviewed = true;
    return ReviewModel(
      id: 'review-1',
      negotiationId: negotiationId,
      reviewerId: 'buyer-001',
      reviewedUserId: 'farmer-001',
      rating: rating,
      comment: comment,
    );
  }
}

class _DelayedReviewStatusService extends _FakeReviewService {
  final Completer<bool> checkCompleter = Completer<bool>();

  @override
  Future<bool> hasReviewedNegotiation(String negotiationId) {
    checkCalls++;
    return checkCompleter.future;
  }
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

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  CropModel buildCrop() {
    return CropModel(
      id: 'crop-100',
      farmerId: 'farmer-001',
      title: 'Café Especial Castillo',
      description: 'Café de altura con notas florales y frutales.',
      cropType: 'Café',
      pricePerKg: 15000.0,
      stockTotal: 500.0,
      department: 'Huila',
      municipality: 'Pitalito',
      status: CropStatus.activa,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  NegotiationModel buildNegotiation({
    NegotiationStatus status = NegotiationStatus.completada,
    String id = 'neg-completed',
  }) {
    return NegotiationModel(
      id: id,
      cropId: 'crop-100',
      buyerId: 'buyer-001',
      status: status,
      currentResponder: 'agricultor',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
      crop: buildCrop(),
      buyerProfile: {'full_name': 'Andrés Mercader'},
      farmerProfile: {'full_name': 'Don Jaime Cafetero'},
      offers: const [],
    );
  }

  NegotiationService buildNegotiationService({String userId = 'buyer-001'}) {
    return NegotiationService(
      currentUserIdForTesting: userId,
      rpcInvoker: (func, {params}) async {
        throw StateError('contacto no disponible');
      },
    );
  }

  Widget buildScreen({
    required NegotiationModel negotiation,
    required ReviewService reviewService,
    String role = 'comprador',
    String userId = 'buyer-001',
  }) {
    return createTestWidget(
      DealDetailScreen(
        negotiationId: negotiation.id,
        role: role,
        initialNegotiation: negotiation,
        service: buildNegotiationService(userId: userId),
        reviewService: reviewService,
      ),
    );
  }

  testWidgets('muestra el estado de verificación antes de habilitar el form', (
    tester,
  ) async {
    final reviewService = _DelayedReviewStatusService();
    await tester.pumpWidget(
      buildScreen(
        negotiation: buildNegotiation(),
        reviewService: reviewService,
      ),
    );
    await tester.pump();

    expect(find.text('Verificando calificación...'), findsOneWidget);
    expect(find.text('Calificar productor'), findsNothing);

    reviewService.checkCompleter.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Trato calificado'), findsOneWidget);
    expect(find.text('Verificando calificación...'), findsNothing);
  });

  testWidgets('muestra "Trato calificado" y bloquea el formulario existente', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(alreadyReviewed: true);
    await tester.pumpWidget(
      buildScreen(
        negotiation: buildNegotiation(),
        reviewService: reviewService,
      ),
    );
    await tester.pumpAndSettle();

    expect(reviewService.checkCalls, 1);
    expect(find.text('Trato calificado'), findsOneWidget);
    expect(
      find.text('Ya enviaste tu calificación para este trato.'),
      findsOneWidget,
    );
    expect(find.text('Calificar productor'), findsNothing);
    expect(find.byKey(const ValueKey('rating_submit_button')), findsNothing);
  });

  testWidgets('envía la calificación con estrellas y comentario opcional', (
    tester,
  ) async {
    final reviewService = _FakeReviewService();
    await tester.pumpWidget(
      buildScreen(
        negotiation: buildNegotiation(),
        reviewService: reviewService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calificar productor'), findsOneWidget);
    await tester.ensureVisible(find.text('Calificar productor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calificar productor'));
    await tester.pumpAndSettle();

    final submitFinder = find.byKey(const ValueKey('rating_submit_button'));
    expect(
      tester.widget<ElevatedButton>(submitFinder).onPressed,
      isNull,
      reason: 'No debe enviarse sin estrellas seleccionadas',
    );

    await tester.tap(find.byKey(const ValueKey('rating_star_4')));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const ValueKey('rating_comment_field')),
      'Excelente producto y entrega puntual.',
    );
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(reviewService.submitCalls, 1);
    expect(reviewService.submittedRating, 4);
    expect(
      reviewService.submittedComment,
      'Excelente producto y entrega puntual.',
    );
    expect(find.text('Calificación enviada correctamente'), findsOneWidget);
    expect(find.text('Trato calificado'), findsOneWidget);
    expect(find.text('Calificar productor'), findsNothing);
    expect(find.text('Café Especial Castillo'), findsOneWidget);
  });

  testWidgets(
    'mantiene el formulario y muestra un error entendible al fallar',
    (tester) async {
      final reviewService = _FakeReviewService(
        submitError: Exception('No fue posible guardar la calificación.'),
      );
      await tester.pumpWidget(
        buildScreen(
          negotiation: buildNegotiation(),
          reviewService: reviewService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Calificar productor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calificar productor'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rating_star_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('rating_submit_button')));
      await tester.pumpAndSettle();

      expect(reviewService.submitCalls, 1);
      expect(
        find.text('No fue posible guardar la calificación.'),
        findsWidgets,
      );
      expect(find.text('Calificación enviada correctamente'), findsNothing);
      expect(find.text('Trato calificado'), findsNothing);
      expect(find.text('Enviar calificación'), findsOneWidget);
      expect(find.text('Café Especial Castillo'), findsOneWidget);
    },
  );

  testWidgets('muestra error de verificación y permite reintentar', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(
      checkError: Exception('Sin conexión para verificar la calificación.'),
    );
    await tester.pumpWidget(
      buildScreen(
        negotiation: buildNegotiation(),
        reviewService: reviewService,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sin conexión para verificar la calificación.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Calificar productor'), findsNothing);
    expect(find.text('Café Especial Castillo'), findsOneWidget);
  });

  testWidgets('el agricultor califica al comprador desde su propia sesión', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(userId: 'farmer-001');
    await tester.pumpWidget(
      buildScreen(
        negotiation: buildNegotiation(),
        reviewService: reviewService,
        role: 'agricultor',
        userId: 'farmer-001',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calificar comprador'), findsOneWidget);
    await tester.ensureVisible(find.text('Calificar comprador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calificar comprador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rating_star_5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating_submit_button')));
    await tester.pumpAndSettle();

    expect(reviewService.submitCalls, 1);
    expect(reviewService.submittedRating, 5);
    expect(find.text('Calificación enviada correctamente'), findsOneWidget);
    expect(find.text('Trato calificado'), findsOneWidget);
  });

  testWidgets('no permite calificar una negociación que no está completada', (
    tester,
  ) async {
    final reviewService = _FakeReviewService();
    await tester.pumpWidget(
      buildScreen(
        negotiation: buildNegotiation(status: NegotiationStatus.acordada),
        reviewService: reviewService,
      ),
    );
    await tester.pumpAndSettle();

    expect(reviewService.checkCalls, 0);
    expect(find.text('Calificar productor'), findsNothing);
    expect(find.text('Trato calificado'), findsNothing);
    expect(find.text('Café Especial Castillo'), findsOneWidget);
  });
}
