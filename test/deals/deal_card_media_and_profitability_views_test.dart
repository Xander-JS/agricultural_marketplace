import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/avatars/user_avatar.dart';
import 'package:agricultural_marketplace/features/costs/screens/crop_profitability_screen.dart';
import 'package:agricultural_marketplace/features/costs/services/crop_cost_calculator.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_model.dart';
import 'package:agricultural_marketplace/features/deals/models/negotiation_status.dart';
import 'package:agricultural_marketplace/features/deals/screens/deals_screen.dart';

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

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    locale: LocalizationConfig.defaultLocale,
    supportedLocales: LocalizationConfig.supportedLocales,
    localizationsDelegates: LocalizationConfig.localizationsDelegates,
    home: child,
  );

  CropModel crop({double pricePerKg = 10000}) => CropModel(
    id: 'crop-1',
    farmerId: 'farmer-1',
    title: 'Papa Pastusa',
    description: 'Lote de papa',
    cropType: 'Papa',
    pricePerKg: pricePerKg,
    stockTotal: 1000,
    department: 'Nariño',
    municipality: 'Ipiales',
    status: CropStatus.activa,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  NegotiationModel negotiation({Map<String, dynamic>? farmerProfile}) =>
      NegotiationModel(
        id: 'neg-1',
        cropId: 'crop-1',
        buyerId: 'buyer-1',
        status: NegotiationStatus.propuesta,
        currentResponder: 'agricultor',
        createdAt: DateTime(2026, 10, 2),
        updatedAt: DateTime(2026, 10, 2),
        crop: crop(),
        farmerProfile: farmerProfile,
      );

  group('Tarjeta de trato (comprador)', () {
    testWidgets('muestra la foto del productor y su primer nombre y apellido', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          DealsScreen(
            role: 'comprador',
            initialNegotiations: [
              negotiation(
                farmerProfile: {
                  'full_name': 'Juan Carlos Pérez Gómez',
                  'profile_path': 'farmer-1/avatar.jpg',
                },
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final avatar = tester.widget<UserAvatar>(
        find.byKey(const ValueKey('deal_farmer_avatar_neg-1')),
      );
      expect(avatar.imageUrl, 'farmer-1/avatar.jpg');
      expect(find.text('Productor: Juan Pérez'), findsOneWidget);
      expect(find.textContaining('Ipiales'), findsNothing);
    });

    testWidgets('sin perfil no sustituye el nombre por el municipio', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          DealsScreen(role: 'comprador', initialNegotiations: [negotiation()]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Productor'), findsOneWidget);
      expect(find.textContaining('Ipiales'), findsNothing);
      expect(
        tester
            .widget<UserAvatar>(
              find.byKey(const ValueKey('deal_farmer_avatar_neg-1')),
            )
            .imageUrl,
        isNull,
      );
    });
  });

  group('Miniatura del lote en tratos', () {
    test('toma la imagen principal de crop_images incrustada', () {
      final model = NegotiationModel.fromJson({
        'id': 'neg-1',
        'crop_id': 'crop-1',
        'buyer_id': 'buyer-1',
        'status': 'propuesta',
        'crops': {
          'id': 'crop-1',
          'farmer_id': 'farmer-1',
          'title': 'Papa Pastusa',
          'description': 'Lote',
          'crop_type': 'Papa',
          'price_per_kg': 2000,
          'stock_total': 100,
          'stock_committed': 0,
          'stock_sold': 0,
          'min_order_kg': 1,
          'department': 'Nariño',
          'municipality': 'Ipiales',
          'status': 'activa',
          'created_at': '2026-10-01T00:00:00Z',
          'updated_at': '2026-10-01T00:00:00Z',
          'crop_images': [
            {'image_path': 'crop-1/secundaria.jpg', 'is_primary': false},
            {'image_path': 'crop-1/principal.jpg', 'is_primary': true},
          ],
        },
      });

      expect(model.crop?.imageUrls.first, 'crop-1/principal.jpg');
    });
  });

  group('Rentabilidad en tres vistas', () {
    CropCostPerKgResult cost() => const CropCostPerKgResult(
      status: CropCostPerKgStatus.calculated,
      costPerKg: 8000,
      denominator: 1,
      denominatorSource: CropCostDenominatorSource.stockTotal,
      message: 'Costo estimado por kg',
    );

    testWidgets(
      'el selector lleva a cada vista y solo la activa recibe toques',
      (tester) async {
        await tester.pumpWidget(
          app(CropProfitabilityScreen(crop: crop(), costPerKgResult: cost())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tu precio'), findsOneWidget);
        expect(find.text('Sugerido'), findsOneWidget);
        expect(find.text('Índice Nariño'), findsOneWidget);

        // Vista inicial: evaluar el precio de venta.
        expect(
          find.byKey(const Key('profit_selling_price_field')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('profit_target_margin_field')).hitTestable(),
          findsNothing,
        );

        await tester.tap(find.text('Sugerido'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('profit_target_margin_field')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('profit_selling_price_field')).hitTestable(),
          findsNothing,
        );
        expect(find.text('Costo base por kg'), findsOneWidget);

        await tester.tap(find.text('Índice Nariño'));
        await tester.pumpAndSettle();

        expect(
          find.text('Índice de referencia regional (Nariño)').hitTestable(),
          findsOneWidget,
        );
      },
    );

    testWidgets('el precio escrito se conserva al cambiar de vista', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(CropProfitabilityScreen(crop: crop(), costPerKgResult: cost())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('profit_selling_price_field')),
        '9000',
      );
      await tester.pump();

      await tester.tap(find.text('Sugerido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tu precio'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('profit_selling_price_field')),
      );
      expect(field.controller?.text, '9000');
    });
  });
}
