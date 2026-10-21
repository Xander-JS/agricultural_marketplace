import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';
import 'package:agricultural_marketplace/features/crop/widgets/crop_card.dart';
import 'package:agricultural_marketplace/features/review/models/review_model.dart';
import 'package:agricultural_marketplace/features/review/services/review_service.dart';

class _FakeReviewService extends ReviewService {
  _FakeReviewService(this.reputations)
    : super(currentUserIdForTesting: 'buyer-001');

  final Map<String, ReviewSummary> reputations;
  int batchCalls = 0;
  List<String> requestedUserIds = const [];

  @override
  Future<Map<String, ReviewSummary>> getReputationsForUsers(
    Iterable<String> userIds,
  ) async {
    batchCalls++;
    requestedUserIds = userIds.toList(growable: false);
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
  required String cropType,
  required double pricePerKg,
  required DateTime createdAt,
  String description = '',
}) {
  return CropModel(
    id: id,
    farmerId: farmerId,
    title: title,
    description: description,
    cropType: cropType,
    pricePerKg: pricePerKg,
    stockTotal: 100,
    department: 'Antioquia',
    municipality: 'Medellín',
    status: CropStatus.activa,
    createdAt: createdAt,
    updatedAt: createdAt,
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

  final premiumCoffee = _crop(
    id: 'crop-coffee',
    farmerId: 'farmer-high',
    title: 'Café Premium de Altura',
    cropType: 'Café',
    pricePerKg: 12000,
    createdAt: DateTime(2026, 1, 3),
  );
  final premiumPotato = _crop(
    id: 'crop-potato',
    farmerId: 'farmer-low',
    title: 'Papa Criolla Premium',
    cropType: 'Papa',
    pricePerKg: 3000,
    createdAt: DateTime(2026, 1, 2),
  );
  final northLot = _crop(
    id: 'crop-corn',
    farmerId: 'farmer-none',
    title: 'Lote Norte',
    cropType: 'Maíz',
    pricePerKg: 8000,
    createdAt: DateTime(2026, 1, 1),
    description: 'descripcionsecreta',
  );
  final premiumRice = _crop(
    id: 'crop-rice',
    farmerId: 'farmer-none-2',
    title: 'Arroz Premium',
    cropType: 'Arroz',
    pricePerKg: 5000,
    createdAt: DateTime(2026, 1, 4),
  );

  // Orden inicial equivalente a created_at descendente (el que entrega el
  // servicio real) para que los empates conserven ese orden.
  final crops = [premiumRice, premiumCoffee, premiumPotato, northLot];

  final reputations = {
    'farmer-high': const ReviewSummary(averageRating: 5, totalReviews: 2),
    'farmer-low': const ReviewSummary(averageRating: 2, totalReviews: 1),
  };

  Widget createTestWidget({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  Future<void> pumpMarketplace(
    WidgetTester tester, {
    required List<CropModel> initialCrops,
    required _FakeReviewService reviewService,
    Locale locale = const Locale('en'),
    String role = 'comprador',
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      createTestWidget(
        locale: locale,
        child: MarketplaceScreen(
          role: role,
          initialCrops: initialCrops,
          reviewService: reviewService,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> visibleTitles(WidgetTester tester) {
    return tester
        .widgetList<CropCard>(find.byType(CropCard))
        .map((card) => card.crop.title)
        .toList(growable: false);
  }

  ChoiceChip sortChip(WidgetTester tester, String keyName) {
    return tester.widget<ChoiceChip>(
      find.byKey(ValueKey('marketplace_sort_$keyName')),
    );
  }

  Future<void> selectSort(WidgetTester tester, String keyName) async {
    final finder = find.byKey(ValueKey('marketplace_sort_$keyName'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('search matches title and crop_type case-insensitively', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(reputations);
    await pumpMarketplace(
      tester,
      initialCrops: crops,
      reviewService: reviewService,
    );

    final searchField = find.byKey(const ValueKey('marketplace_search_field'));

    await tester.enterText(searchField, 'PREMIUM');
    await tester.pumpAndSettle();

    expect(visibleTitles(tester), [
      'Arroz Premium',
      'Café Premium de Altura',
      'Papa Criolla Premium',
    ]);

    // Coincidencia por crop_type, sin depender del título.
    await tester.enterText(searchField, 'MAÍZ');
    await tester.pumpAndSettle();

    expect(visibleTitles(tester), ['Lote Norte']);
  });

  testWidgets('search ignores description and shows the empty state', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(reputations);
    await pumpMarketplace(
      tester,
      initialCrops: crops,
      reviewService: reviewService,
    );

    await tester.enterText(
      find.byKey(const ValueKey('marketplace_search_field')),
      'descripcionsecreta',
    );
    await tester.pumpAndSettle();

    expect(find.byType(CropCard), findsNothing);
    expect(
      find.text('No crops were found matching these criteria'),
      findsOneWidget,
    );
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('sorts by recent, lowest price, highest price and reputation', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(reputations);
    await pumpMarketplace(
      tester,
      initialCrops: crops,
      reviewService: reviewService,
    );

    // Orden por defecto: created_at descendente.
    expect(visibleTitles(tester), [
      'Arroz Premium',
      'Café Premium de Altura',
      'Papa Criolla Premium',
      'Lote Norte',
    ]);
    expect(sortChip(tester, 'recent').selected, isTrue);

    await selectSort(tester, 'price_asc');
    expect(visibleTitles(tester), [
      'Papa Criolla Premium',
      'Arroz Premium',
      'Lote Norte',
      'Café Premium de Altura',
    ]);

    await selectSort(tester, 'price_desc');
    expect(visibleTitles(tester), [
      'Café Premium de Altura',
      'Lote Norte',
      'Arroz Premium',
      'Papa Criolla Premium',
    ]);

    await selectSort(tester, 'reputation');
    expect(visibleTitles(tester), [
      'Café Premium de Altura',
      'Papa Criolla Premium',
      'Arroz Premium',
      'Lote Norte',
    ], reason: 'Los productores sin reseñas deben quedar al final');

    expect(reviewService.batchCalls, 1);
    expect(reviewService.requestedUserIds.toSet(), {
      'farmer-high',
      'farmer-low',
      'farmer-none',
      'farmer-none-2',
    });
  });

  testWidgets('search and sorting work together', (tester) async {
    final reviewService = _FakeReviewService(reputations);
    await pumpMarketplace(
      tester,
      initialCrops: crops,
      reviewService: reviewService,
    );

    await tester.enterText(
      find.byKey(const ValueKey('marketplace_search_field')),
      'premium',
    );
    await tester.pumpAndSettle();

    await selectSort(tester, 'price_desc');

    expect(visibleTitles(tester), [
      'Café Premium de Altura',
      'Arroz Premium',
      'Papa Criolla Premium',
    ]);

    await tester.enterText(
      find.byKey(const ValueKey('marketplace_search_field')),
      'no-existe',
    );
    await tester.pumpAndSettle();

    expect(find.byType(CropCard), findsNothing);
    expect(
      find.text('No crops were found matching these criteria'),
      findsOneWidget,
    );
  });

  testWidgets('clear filters clears search and restores the recent order', (
    tester,
  ) async {
    final reviewService = _FakeReviewService(reputations);
    await pumpMarketplace(
      tester,
      initialCrops: crops,
      reviewService: reviewService,
    );

    await tester.enterText(
      find.byKey(const ValueKey('marketplace_search_field')),
      'no-existe',
    );
    await selectSort(tester, 'price_asc');

    expect(
      find.text('No crops were found matching these criteria'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('marketplace_clear_filters')));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const ValueKey('marketplace_search_field')),
    );
    expect(textField.controller?.text, isEmpty);
    expect(sortChip(tester, 'recent').selected, isTrue);
    expect(sortChip(tester, 'price_asc').selected, isFalse);
    expect(visibleTitles(tester), [
      'Arroz Premium',
      'Café Premium de Altura',
      'Papa Criolla Premium',
      'Lote Norte',
    ]);
  });

  testWidgets('farmers do not see buyer discovery tools', (tester) async {
    final reviewService = _FakeReviewService(reputations);
    await pumpMarketplace(
      tester,
      initialCrops: crops,
      reviewService: reviewService,
      role: 'agricultor',
    );

    expect(
      find.byKey(const ValueKey('marketplace_search_field')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('marketplace_sort_recent')), findsNothing);
  });
}
