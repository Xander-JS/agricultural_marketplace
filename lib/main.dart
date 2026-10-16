import 'package:flutter/material.dart';
import 'core/config/supabase_client.dart';
import 'core/localization/localization_config.dart';
import 'core/services/app_preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de preferencias globales de la app (Modo oscuro e Idioma)
  try {
    await AppPreferencesService.instance.init();
  } catch (e) {
    debugPrint('Preferences initialization warning: $e');
  }

  // Inicialización de Supabase con variables de entorno (.env)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(const AgriculturalMarketplaceApp());
}

/// Punto de entrada global y configuración central de la aplicación.
///
/// Conectado reactivamente con [AppPreferencesService] para actualizar inmediatamente
/// el tema (claro/oscuro) y el idioma (es/en) en toda la aplicación tras cualquier cambio en Mi Finca.
class AgriculturalMarketplaceApp extends StatelessWidget {
  final AppPreferencesService? preferencesService;
  final Widget? home;

  const AgriculturalMarketplaceApp({
    super.key,
    this.preferencesService,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = preferencesService ?? AppPreferencesService.instance;

    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        return MaterialApp(
          title: 'Agricultural Marketplace',
          debugShowCheckedModeBanner: false,

          // ---------------------------------------------------------
          // 🎨 Configuración Global de Temas (Reactivo)
          // ---------------------------------------------------------
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: prefs.themeMode,

          // ---------------------------------------------------------
          // 🌎 Configuración Global de Localización (Reactivo)
          // ---------------------------------------------------------
          locale: prefs.locale,
          supportedLocales: LocalizationConfig.supportedLocales,
          localizationsDelegates: LocalizationConfig.localizationsDelegates,
          localeResolutionCallback: LocalizationConfig.localeResolutionCallback,

          // ---------------------------------------------------------
          // Punto de entrada de la app
          // ---------------------------------------------------------
          home: home ?? const LoginScreen(),
        );
      },
    );
  }
}
