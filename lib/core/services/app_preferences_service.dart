import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/localization_config.dart';

/// Servicio centralizado y reactivo para la gestión y persistencia global
/// de las preferencias del usuario (Modo Oscuro e Idioma).
///
/// Utiliza [ChangeNotifier] para notificar cambios inmediatamente a [MaterialApp]
/// sin reiniciar la aplicación, y persiste los valores en [SharedPreferences].
class AppPreferencesService extends ChangeNotifier {
  static final AppPreferencesService _instance = AppPreferencesService._internal();
  static AppPreferencesService get instance => _instance;

  static const String keyThemeMode = 'app_preference_theme_mode';
  static const String keyLanguageCode = 'app_preference_language_code';

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = LocalizationConfig.defaultLocale;
  bool _isInitialized = false;

  AppPreferencesService._internal();

  /// Constructor para inyección en pruebas unitarias
  AppPreferencesService.withPreferences(SharedPreferences prefs) {
    _prefs = prefs;
    _loadFromPreferences();
  }

  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';

  /// Inicializa el servicio leyendo las preferencias guardadas
  Future<void> init() async {
    if (_isInitialized && _prefs != null) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _loadFromPreferences();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando AppPreferencesService: $e');
    }
  }

  void _loadFromPreferences() {
    if (_prefs == null) return;

    // 1. Cargar Modo de Tema
    final savedTheme = _prefs!.getString(keyThemeMode);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    // 2. Cargar Idioma
    final savedLang = _prefs!.getString(keyLanguageCode);
    if (savedLang == 'en') {
      _locale = LocalizationConfig.englishLocale;
    } else {
      _locale = LocalizationConfig.spanishLocale;
    }
    notifyListeners();
  }

  /// Cambia el modo de tema y lo persiste
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(keyThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error guardando preferencia de tema: $e');
    }
  }

  /// Alterna entre modo claro y modo oscuro
  Future<void> toggleDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Cambia el idioma y lo persiste
  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(keyLanguageCode, newLocale.languageCode);
    } catch (e) {
      debugPrint('Error guardando preferencia de idioma: $e');
    }
  }

  /// Alterna entre español e inglés
  Future<void> toggleEnglish(bool isEnglish) async {
    await setLocale(
      isEnglish ? LocalizationConfig.englishLocale : LocalizationConfig.spanishLocale,
    );
  }
}
