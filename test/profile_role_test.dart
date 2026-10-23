import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';
import 'package:agricultural_marketplace/features/profile/screens/farmer_profile_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        publishableKey: 'placeholder-anon-key',
      );
    } catch (_) {
      // Ignorar si ya está inicializado
    }
  });

  Widget createTestWidget({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  final farmerData = FarmerProfileData(
    id: 'farmer-123',
    fullName: 'Carlos Agricultor',
    role: 'agricultor',
    email: 'carlos@agromarket.com',
    phone: '3001234567',
    profilePath: null,
    settings: FarmerSettingsData(
      enableEarlySale: true,
      sharePhone: true,
      shareLocation: false,
      shareWhatsapp: true,
    ),
    stats: FarmerStatsData(
      published: 8,
      negotiating: 3,
      closed: 12,
    ),
  );

  final buyerData = FarmerProfileData(
    id: 'buyer-456',
    fullName: 'Ana Comerciante',
    role: 'comprador',
    email: 'ana@compras.com',
    phone: '3159876543',
    profilePath: null,
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: false,
      shareLocation: false,
      shareWhatsapp: false,
    ),
    stats: FarmerStatsData(
      published: 0,
      negotiating: 5,
      closed: 9,
    ),
  );

  group('Etapa 3 — Perfil y Estadísticas por Rol', () {
    testWidgets('Perfil de Agricultor muestra 3 estadísticas (Publicados, Negociando, Cerradas)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(initialProfileData: farmerData),
        ),
      );
      await tester.pumpAndSettle();

      // Título del AppBar para Agricultor
      expect(find.text('Mi Finca'), findsOneWidget);
      expect(find.text('AGRICULTOR'), findsOneWidget);
      expect(find.text('Carlos Agricultor'), findsOneWidget);

      // Estadísticas del Agricultor
      expect(find.text('Publicados'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Negociando'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Cerradas'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('Perfil de Comerciante muestra ÚNICAMENTE 2 estadísticas (Negociando y Cerrados)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(initialProfileData: buyerData),
        ),
      );
      await tester.pumpAndSettle();

      // Título del AppBar para Comerciante
      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('COMPRADOR'), findsOneWidget);
      expect(find.text('Ana Comerciante'), findsOneWidget);

      // Estadísticas del Comerciante
      expect(find.text('Negociando'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Cerrados'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      // NO debe mostrar la estadística de Publicados
      expect(find.text('Publicados'), findsNothing);
      expect(find.text('Cerradas'), findsNothing);
    });

    testWidgets('Modal de configuración muestra opciones de negociación solo para agricultor', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(initialProfileData: farmerData),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir modal de configuración
      await tester.tap(find.byIcon(LucideIcons.settings));
      await tester.pumpAndSettle();

      // Opciones presentes para agricultor
      expect(find.text('Información de contacto'), findsOneWidget);
      expect(find.text('Opciones de negociación'), findsOneWidget);
      expect(find.text('Habilitar precompra'), findsOneWidget);
      expect(find.text('Visibilidad durante una negociación'), findsOneWidget);
      expect(find.text('Accesibilidad'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('Modal de configuración oculta opciones de negociación para comerciante', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(initialProfileData: buyerData),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir modal de configuración
      await tester.tap(find.byIcon(LucideIcons.settings));
      await tester.pumpAndSettle();

      // Opciones para comerciante
      expect(find.text('Información de contacto'), findsOneWidget);
      expect(find.text('Accesibilidad'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // Opciones de agricultor que NO deben aparecer para el comerciante
      expect(find.text('Opciones de negociación'), findsNothing);
      expect(find.text('Habilitar precompra'), findsNothing);
      expect(find.text('Visibilidad durante una negociación'), findsNothing);
    });

    testWidgets('Perfil de Comerciante soporta modo oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: FarmerProfileScreen(initialProfileData: buyerData),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Negociando'), findsOneWidget);
      expect(find.text('Cerrados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cierre de sesión desde FarmerProfileScreen invoca onSignOut tras confirmar diálogo', (tester) async {
      bool signedOut = false;

      await tester.pumpWidget(
        createTestWidget(
          child: FarmerProfileScreen(
            initialProfileData: farmerData,
            onSignOut: () async {
              signedOut = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir modal de configuración
      await tester.tap(find.byIcon(LucideIcons.settings));
      await tester.pumpAndSettle();

      // Desplazar y pulsar cerrar sesión en el modal
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // Confirmar en el diálogo
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });
  });
}
