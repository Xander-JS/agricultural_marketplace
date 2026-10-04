import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations.dart';

/// Centralized localization settings and configuration for the application.
abstract final class LocalizationConfig {
  /// Spanish (Default / Primary Language)
  static const Locale spanishLocale = Locale('es');

  /// English (Secondary Language)
  static const Locale englishLocale = Locale('en');

  /// Fallback / Default application locale
  static const Locale defaultLocale = spanishLocale;

  /// Complete list of supported locales
  static const List<Locale> supportedLocales = <Locale>[
    spanishLocale,
    englishLocale,
  ];

  /// Core delegates required by Flutter to enable localization
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Resolution callback logic if device locale needs fallback
  static Locale localeResolutionCallback(Locale? locale, Iterable<Locale> supported) {
    if (locale == null) return defaultLocale;

    for (final supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return defaultLocale;
  }
}
