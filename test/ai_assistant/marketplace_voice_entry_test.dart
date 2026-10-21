import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/screens/marketplace_screen.dart';

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

  testWidgets('El acceso provisional de voz abre la asistencia funcional', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: LocalizationConfig.defaultLocale,
        supportedLocales: LocalizationConfig.supportedLocales,
        localizationsDelegates: LocalizationConfig.localizationsDelegates,
        home: const MarketplaceScreen(role: 'agricultor', initialCrops: []),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Publicación por Nota de Voz'), findsOneWidget);

    await tester.tap(find.text('Publicación por Nota de Voz'));
    await tester.pumpAndSettle();

    expect(find.text('Publicar por voz'), findsOneWidget);
    expect(find.byKey(const Key('voice_crop_start_button')), findsOneWidget);
    expect(find.byKey(const Key('voice_crop_manual_button')), findsOneWidget);
  });
}
