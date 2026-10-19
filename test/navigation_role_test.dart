import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/navigation/app_bottom_navigation.dart';
import 'package:agricultural_marketplace/features/dashboard/screens/main_dashboard_screen.dart';
import 'package:agricultural_marketplace/features/purchases/screens/purchases_screen.dart';
import 'package:agricultural_marketplace/features/costs/screens/costs_screen.dart';

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

  group('Etapa 2 — Pruebas de AppBottomNavigation por Roles', () {
    testWidgets('AppBottomNavigation muestra pestañas de Agricultor en modo claro', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              role: 'agricultor',
              currentIndex: selectedIndex,
              onTap: (index) => selectedIndex = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Costos'), findsOneWidget);
      expect(find.text('Mi Finca'), findsOneWidget);
      expect(find.text('Compras'), findsNothing);
      expect(find.text('Mi mercado'), findsNothing);
    });

    testWidgets('AppBottomNavigation muestra pestañas de Comerciante/Comprador en modo claro', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              role: 'comprador',
              currentIndex: selectedIndex,
              onTap: (index) => selectedIndex = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi mercado'), findsOneWidget);
      expect(find.text('Tratos'), findsOneWidget);
      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Mi Finca'), findsOneWidget);
      expect(find.text('Costos'), findsNothing);
      expect(find.text('Mercado'), findsNothing);
    });

    testWidgets('AppBottomNavigation soporta también el rol comerciante como sinónimo', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              role: 'comerciante',
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Mi mercado'), findsOneWidget);
    });

    testWidgets('AppBottomNavigation soporta modo oscuro sin excepciones', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: Scaffold(
            bottomNavigationBar: AppBottomNavigation(
              role: 'comprador',
              currentIndex: 2,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compras'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Etapa 2 — Pruebas del Módulo PurchasesScreen', () {
    testWidgets('PurchasesScreen renderiza correctamente en modo claro con sistema de diseño', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PurchasesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Módulo de Compras'), findsOneWidget);
      expect(find.text('Rol Comerciante'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });

    testWidgets('PurchasesScreen renderiza correctamente en modo oscuro con sistema de diseño', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          themeMode: ThemeMode.dark,
          child: const PurchasesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compras'), findsOneWidget);
      expect(find.text('Módulo de Compras'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Etapa 2 — Parámetros y construcción de MainDashboardScreen', () {
    test('MainDashboardScreen conserva el rol especificado', () {
      const farmerDashboard = MainDashboardScreen(role: 'agricultor');
      expect(farmerDashboard.role, 'agricultor');

      const buyerDashboard = MainDashboardScreen(role: 'comprador');
      expect(buyerDashboard.role, 'comprador');

      const merchantDashboard = MainDashboardScreen(role: 'comerciante');
      expect(merchantDashboard.role, 'comerciante');
    });

    testWidgets('MainDashboardScreen con variantes buyer, mayúsculas y espacios monta PurchasesScreen y no CostsScreen', (tester) async {
      final buyerVariants = ['buyer', ' BUYER ', '  comprador  ', '  Comerciante  '];
      for (final variant in buyerVariants) {
        await tester.pumpWidget(
          createTestWidget(
            child: MainDashboardScreen(
              key: ValueKey(variant),
              role: variant,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PurchasesScreen, skipOffstage: false), findsOneWidget, reason: 'Falló PurchasesScreen para: "$variant"');
        expect(find.byType(CostsScreen, skipOffstage: false), findsNothing, reason: 'Mostró CostsScreen para: "$variant"');
        expect(find.text('Compras'), findsOneWidget, reason: 'Falló texto Compras en navegación para: "$variant"');
        expect(find.text('Costos'), findsNothing, reason: 'Mostró Costos en navegación para: "$variant"');
      }
    });
  });
}
