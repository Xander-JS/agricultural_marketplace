import 'package:flutter/material.dart';
import 'core/config/supabase_client.dart';
import 'core/localization/localization_config.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con variables de entorno (.env)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  runApp(const AgriculturalMarketplaceApp());
}

/// Punto de entrada global y configuración central de la aplicación.
class AgriculturalMarketplaceApp extends StatelessWidget {
  const AgriculturalMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agricultural Marketplace',
      debugShowCheckedModeBanner: false,

      // ---------------------------------------------------------
      // 🎨 Configuración Global de Temas
      // ---------------------------------------------------------
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Tema claro como principal por defecto

      // ---------------------------------------------------------
      // 🌎 Configuración Global de Localización
      // ---------------------------------------------------------
      locale: LocalizationConfig.defaultLocale, // Español por defecto
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      localeResolutionCallback: LocalizationConfig.localeResolutionCallback,

      // ---------------------------------------------------------
      // Placeholder base temporal sin lógica de módulos
      // ---------------------------------------------------------
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
