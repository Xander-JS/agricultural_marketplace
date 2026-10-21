import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/crop/widgets/crop_card.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';
import 'package:agricultural_marketplace/features/profile/screens/farmer_profile_screen.dart';
import 'package:agricultural_marketplace/features/review/models/review_model.dart';
import 'package:agricultural_marketplace/features/review/services/review_service.dart';

class _FakeReviewService extends ReviewService {
  _FakeReviewService({
    this.summary = ReviewSummary.empty,
    this.reputations = const {},
    this.error,
    String userId = 'buyer-001',
  }) : super(currentUserIdForTesting: userId);

  ReviewSummary summary;
  Map<String, ReviewSummary> reputations;
  Object? error;
  int reputationCalls = 0;
  int batchCalls = 0;
  List<String> requestedUserIds = const [];

  @override
  Future<ReviewSummary> getReputation(String userId) async {
    reputationCalls++;
    if (error != null) throw error!;
    return summary;
  }

  @override
  Future<Map<String, ReviewSummary>> getReputationsForUsers(
    Iterable<String> userIds,
  ) async {
    batchCalls++;
    requestedUserIds = userIds.toList(growable: false);
    if (error != null) throw error!;
    return {
      for (final userId in requestedUserIds)
        userId: reputations[userId] ?? ReviewSummary.empty,
    };
  }
}

CropModel _crop({
  required String id,
  required String farmerId,
  required String title,
}) {
  return CropModel(
    id: id,
    farmerId: farmerId,
    title: title,
    description: '',
    cropType: 'Café',
    pricePerKg: 12000,
    stockTotal: 100,
    department: 'Antioquia',
    municipality: 'Medellín',
    status: CropStatus.activa,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

FarmerProfileData _profile({required String id, required String role}) {
  return FarmerProfileData(
    id: id,
    fullName: role == 'comprador' ? 'Ana Comerciante' : 'Carlos Agricultor',
    role: role,
    email: 'user@example.com',
    phone: '3001234567',
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: false,
      shareLocation: false,
      shareWhatsapp: false,
    ),
    stats: FarmerStatsData(published: 3, negotiating: 1, closed: 2),
  );
}

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    locale: locale,
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

  group('CropCard — reputación del productor', () {
    testWidgets('muestra promedio a un decimal y total de reseñas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: CropCard(
              crop: _crop(id: 'crop-1', farmerId: 'farmer-1', title: 'Café'),
              reputation: const ReviewSummary(
                averageRating: 4.75,
                totalReviews: 12,
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('★ 4.8 (12)'), findsOneWidget);
      expect(find.text('★ 4.8'), findsNothing);
    });

    testWidgets('muestra "★ New" cuando el productor no tiene reseñas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: CropCard(
              crop: _crop(id: 'crop-2', farmerId: 'farmer-2', title: 'Papa'),
              reputation: ReviewSummary.empty,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('★ New'), findsOneWidget);
    });

    testWidgets(
      'no muestra indicador si la reputación aún no está disponible',
      (tester) async {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: CropCard(
                crop: _crop(id: 'crop-3', farmerId: 'farmer-3', title: 'Maíz'),
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('crop_reputation_crop-3')),
          findsNothing,
        );
      },
    );
  });

  group('Marketplace — reutiliza una sola consulta de reputaciones', () {
    testWidgets('cada tarjeta usa la reputación del productor que la posee', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final reviewService = _FakeReviewService(
        reputations: {
          'farmer-high': const ReviewSummary(
            averageRating: 4.8,
            totalReviews: 12,
          ),
          // Reputación del comprador autenticado: no debe usarse en tarjetas.
          'buyer-001': const ReviewSummary(
            averageRating: 1.0,
            totalReviews: 99,
          ),
        },
      );

      await tester.pumpWidget(
        _app(
          MarketplaceScreen(
            role: 'comprador',
            initialCrops: [
              _crop(id: 'crop-high', farmerId: 'farmer-high', title: 'Café'),
              _crop(id: 'crop-new', farmerId: 'farmer-new', title: 'Papa'),
            ],
            reviewService: reviewService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('★ 4.8 (12)'), findsOneWidget);
      expect(find.text('★ New'), findsOneWidget);
      expect(find.text('★ 1.0 (99)'), findsNothing);
      expect(reviewService.batchCalls, 1);
      expect(reviewService.requestedUserIds.toSet(), {
        'farmer-high',
        'farmer-new',
      });
    });
  });

  group('FarmerProfileScreen — reputación para agricultor y comprador', () {
    testWidgets('perfil de agricultor muestra promedio y reseñas recibidas', (
      tester,
    ) async {
      final reviewService = _FakeReviewService(
        summary: const ReviewSummary(averageRating: 4.75, totalReviews: 12),
      );

      await tester.pumpWidget(
        _app(
          FarmerProfileScreen(
            initialProfileData: _profile(id: 'farmer-1', role: 'agricultor'),
            reviewService: reviewService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reputation'), findsOneWidget);
      expect(find.text('★ 4.8'), findsOneWidget);
      expect(find.text('Average rating'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Reviews received'), findsOneWidget);
      expect(reviewService.reputationCalls, 1);
    });

    testWidgets('perfil de comprador muestra la misma información', (
      tester,
    ) async {
      final reviewService = _FakeReviewService(
        summary: const ReviewSummary(averageRating: 3.04, totalReviews: 5),
      );

      await tester.pumpWidget(
        _app(
          FarmerProfileScreen(
            initialProfileData: _profile(id: 'buyer-1', role: 'comprador'),
            reviewService: reviewService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('★ 3.0'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Reviews received'), findsOneWidget);
      expect(reviewService.reputationCalls, 1);
    });

    testWidgets('muestra un estado neutral cuando no hay reseñas', (
      tester,
    ) async {
      final reviewService = _FakeReviewService(summary: ReviewSummary.empty);

      await tester.pumpWidget(
        _app(
          FarmerProfileScreen(
            initialProfileData: _profile(id: 'farmer-2', role: 'agricultor'),
            reviewService: reviewService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.text('★ 0.0'), findsNothing);
    });

    testWidgets('ante un error no inventa datos y permite reintentar', (
      tester,
    ) async {
      final reviewService = _FakeReviewService(
        error: Exception('sin conexión'),
      );

      await tester.pumpWidget(
        _app(
          FarmerProfileScreen(
            initialProfileData: _profile(id: 'farmer-3', role: 'agricultor'),
            reviewService: reviewService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load reputation.'), findsOneWidget);
      expect(find.text('★ 0.0'), findsNothing);

      reviewService
        ..error = null
        ..summary = const ReviewSummary(averageRating: 5, totalReviews: 2);

      final retryButton = find.byKey(
        const ValueKey('profile_reputation_retry'),
      );
      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(find.text('★ 5.0'), findsOneWidget);
      expect(find.text('Reviews received'), findsOneWidget);
      expect(reviewService.reputationCalls, 2);
    });
  });
}
