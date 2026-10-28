import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/supabase_client.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/localization_config.dart';
import 'core/services/app_preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_formatters.dart';
import 'features/auth/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Plus Jakarta Sans viene empaquetada en assets/google_fonts/: la tipografía
  // nunca depende de descargas en tiempo de ejecución (zonas rurales).
  GoogleFonts.config.allowRuntimeFetching = false;

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
        DateFormatters.languageCode = prefs.locale.languageCode;
        return MaterialApp(
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.app_title ?? '',
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

          // Tamaño de texto e iconos: multiplica la escala del sistema.
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  media.textScaler.scale(1) * prefs.textSize.factor,
                ),
              ),
              child: child!,
            );
          },

          // ---------------------------------------------------------
          // Punto de entrada de la app
          // ---------------------------------------------------------
          home: home ?? const AuthGate(),
        );
      },
    );
  }
}
