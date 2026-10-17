import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/main.dart';
import 'package:agricultural_marketplace/core/services/app_preferences_service.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';

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

  group('Etapa B & C — AppPreferencesService (Tema e Idioma Global)', () {
    test('Configuración por defecto inicia en modo claro y español', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppPreferencesService.withPreferences(prefs);

      expect(service.themeMode, equals(ThemeMode.light));
      expect(service.isDarkMode, isFalse);
      expect(service.locale, equals(LocalizationConfig.spanishLocale));
      expect(service.isEnglish, isFalse);
    });

    test('toggleDarkMode cambia reactivamente y persiste en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppPreferencesService.withPreferences(prefs);

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.toggleDarkMode(true);
      expect(service.themeMode, equals(ThemeMode.dark));
      expect(service.isDarkMode, isTrue);
      expect(notifyCount, equals(1));
      expect(prefs.getString(AppPreferencesService.keyThemeMode), equals('dark'));

      await service.toggleDarkMode(false);
      expect(service.themeMode, equals(ThemeMode.light));
      expect(service.isDarkMode, isFalse);
      expect(notifyCount, equals(2));
      expect(prefs.getString(AppPreferencesService.keyThemeMode), equals('light'));
    });

    test('toggleEnglish cambia reactivamente y persiste en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppPreferencesService.withPreferences(prefs);

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.toggleEnglish(true);
      expect(service.locale, equals(LocalizationConfig.englishLocale));
      expect(service.isEnglish, isTrue);
      expect(notifyCount, equals(1));
      expect(prefs.getString(AppPreferencesService.keyLanguageCode), equals('en'));

      await service.toggleEnglish(false);
      expect(service.locale, equals(LocalizationConfig.spanishLocale));
      expect(service.isEnglish, isFalse);
      expect(notifyCount, equals(2));
      expect(prefs.getString(AppPreferencesService.keyLanguageCode), equals('es'));
    });

    test('Reapertura del servicio restaura las preferencias previamente guardadas', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferencesService.keyThemeMode: 'dark',
        AppPreferencesService.keyLanguageCode: 'en',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = AppPreferencesService.withPreferences(prefs);

      expect(service.themeMode, equals(ThemeMode.dark));
      expect(service.isDarkMode, isTrue);
      expect(service.locale, equals(LocalizationConfig.englishLocale));
      expect(service.isEnglish, isTrue);
    });
  });

  group('Etapa B & C — Reactividad en MaterialApp', () {
    testWidgets('MaterialApp se reconstruye inmediatamente con el nuevo tema e idioma sin reiniciar la app', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppPreferencesService.withPreferences(prefs);

      await tester.pumpWidget(
        AgriculturalMarketplaceApp(
          preferencesService: service,
          home: const Scaffold(body: Text('Test Preferences')),
        ),
      );
      await tester.pumpAndSettle();

      MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.light));
      expect(app.locale, equals(const Locale('es')));

      // Cambiar a modo oscuro en vivo
      await service.toggleDarkMode(true);
      await tester.pumpAndSettle();

      app = tester.widget(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.dark));

      // Cambiar a inglés en vivo
      await service.toggleEnglish(true);
      await tester.pumpAndSettle();

      app = tester.widget(find.byType(MaterialApp));
      expect(app.locale, equals(const Locale('en')));
    });
  });

  group('Etapa C — Paridad de Claves de Localización ARB', () {
    test('app_es.arb y app_en.arb tienen paridad total de claves', () {
      final esFile = File('lib/core/localization/app_es.arb');
      final enFile = File('lib/core/localization/app_en.arb');

      expect(esFile.existsSync(), isTrue, reason: 'app_es.arb debe existir');
      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb debe existir');

      final Map<String, dynamic> esMap = jsonDecode(esFile.readAsStringSync());
      final Map<String, dynamic> enMap = jsonDecode(enFile.readAsStringSync());

      final esKeys = esMap.keys.where((k) => !k.startsWith('@')).toSet();
      final enKeys = enMap.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInEn = esKeys.difference(enKeys);
      final missingInEs = enKeys.difference(esKeys);

      expect(
        missingInEn,
        isEmpty,
        reason: 'Las siguientes claves están en app_es.arb pero faltan en app_en.arb: $missingInEn',
      );
      expect(
        missingInEs,
        isEmpty,
        reason: 'Las siguientes claves están en app_en.arb pero faltan en app_es.arb: $missingInEs',
      );
      expect(esKeys.length, equals(enKeys.length));
    });
  });
}
