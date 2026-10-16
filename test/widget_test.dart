import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/main.dart';
import 'package:agricultural_marketplace/core/services/app_preferences_service.dart';

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

  testWidgets('AgriculturalMarketplaceApp smoke test inicializa correctamente', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final prefService = AppPreferencesService.withPreferences(prefs);

    await tester.pumpWidget(AgriculturalMarketplaceApp(preferencesService: prefService));
    await tester.pumpAndSettle();

    expect(find.byType(AgriculturalMarketplaceApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
