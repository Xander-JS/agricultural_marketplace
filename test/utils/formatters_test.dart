import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/utils/app_formatters.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/widgets/crop_card.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    DateFormatters.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        publishableKey: 'placeholder-anon-key',
      );
    } catch (_) {}
  });

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  group('CurrencyFormatters (COP bajo convención colombiana es_CO)', () {
    test('1. Formatea enteros con separador de miles por punto', () {
      expect(CurrencyFormatters.formatCop(0), equals(r'$ 0'));
      expect(CurrencyFormatters.formatCop(500), equals(r'$ 500'));
      expect(CurrencyFormatters.formatCop(2500), equals(r'$ 2.500'));
      expect(CurrencyFormatters.formatCop(200000), equals(r'$ 200.000'));
      expect(CurrencyFormatters.formatCop(2960000), equals(r'$ 2.960.000'));
      expect(CurrencyFormatters.formatCop(15000000), equals(r'$ 15.000.000'));
    });

    test('2. Opciones includeSymbol e includeCode', () {
      expect(
        CurrencyFormatters.formatCop(200000, includeSymbol: false),
        equals('200.000'),
      );
      expect(
        CurrencyFormatters.formatCop(200000, includeCode: true),
        equals(r'$ 200.000 COP'),
      );
      expect(
        CurrencyFormatters.formatCop(200000, includeSymbol: false, includeCode: true),
        equals('200.000 COP'),
      );
    });

    test('3. Formatea decimales cuando corresponde', () {
      expect(
        CurrencyFormatters.formatCop(2500.50),
        equals(r'$ 2.500,50'),
      );
      expect(
        CurrencyFormatters.formatCop(200000, decimalDigits: 2),
        equals(r'$ 200.000,00'),
      );
    });

    test('4. formatPricePerKg formatea correctamente con sufijo / kg', () {
      expect(
        CurrencyFormatters.formatPricePerKg(4500),
        equals(r'$ 4.500 / kg'),
      );
      expect(
        CurrencyFormatters.formatPricePerKg(14800),
        equals(r'$ 14.800 / kg'),
      );
    });

    test('5. Manejo seguro de valores nulos y no mutación de valor numérico', () {
      expect(CurrencyFormatters.formatCop(null), equals(r'$ 0'));
      expect(CurrencyFormatters.formatCop(null, fallback: '--'), equals('--'));

      const originalNumber = 4500.75;
      final formatted = CurrencyFormatters.formatCop(originalNumber);
      expect(formatted, contains('4.500,75'));
      // El número original permanece intacto
      expect(originalNumber, equals(4500.75));
    });
  });

  group('UnitFormatters (Base kg y equivalencias tradicionales)', () {
    test('6. Formatea enteros limpios en kg sin decimales flotantes .00', () {
      expect(UnitFormatters.formatKg(50), equals('50 kg'));
      expect(UnitFormatters.formatKg(100), equals('100 kg'));
      expect(UnitFormatters.formatKg(1250), equals('1.250 kg'));
      expect(UnitFormatters.formatKg(10000), equals('10.000 kg'));
    });

    test('7. Formatea cantidades fraccionarias con coma decimal colombiana', () {
      expect(UnitFormatters.formatKg(12.5), equals('12,5 kg'));
      expect(UnitFormatters.formatKg(12.75), equals('12,75 kg'));
      expect(UnitFormatters.formatKg(0.5), equals('0,5 kg'));
    });

    test('8. formatCleanValue permite formato sin unidad y sin separadores para inputs', () {
      expect(UnitFormatters.formatCleanValue(50), equals('50'));
      expect(UnitFormatters.formatCleanValue(1250), equals('1.250'));
      expect(
        UnitFormatters.formatCleanValue(1250, useLocaleSeparators: false),
        equals('1250'),
      );
      expect(
        UnitFormatters.formatCleanValue(12.5, useLocaleSeparators: false),
        equals('12.5'),
      );
    });

    test('9. Conversiones visuales aproximadas a unidades tradicionales', () {
      // 1 bulto = 50 kg
      expect(
        UnitFormatters.formatEquivalence(50, TraditionalUnit.bulto),
        equals('≈ 1 bulto'),
      );
      expect(
        UnitFormatters.formatEquivalence(100, TraditionalUnit.bulto),
        equals('≈ 2 bultos'),
      );

      // 1 arroba = 12.5 kg
      expect(
        UnitFormatters.formatEquivalence(12.5, TraditionalUnit.arroba),
        equals('≈ 1 arroba'),
      );
      expect(
        UnitFormatters.formatEquivalence(25, TraditionalUnit.arroba),
        equals('≈ 2 arrobas'),
      );

      // 1 tonelada = 1000 kg
      expect(
        UnitFormatters.formatEquivalence(1000, TraditionalUnit.tonelada),
        equals('≈ 1 tonelada'),
      );
      expect(
        UnitFormatters.formatEquivalence(2500, TraditionalUnit.tonelada),
        equals('≈ 2,5 toneladas'),
      );

      // Canastillas y cajas
      expect(
        UnitFormatters.formatEquivalence(50, TraditionalUnit.canastilla),
        equals('≈ 2 canastillas'),
      );
      expect(
        UnitFormatters.formatEquivalence(60, TraditionalUnit.caja),
        equals('≈ 3 cajas'),
      );
    });

    test('10. formatKgWithEquivalence combina kg con equivalencia tradicional', () {
      expect(
        UnitFormatters.formatKgWithEquivalence(1000),
        equals('1.000 kg (≈ 1 tonelada)'),
      );
      expect(
        UnitFormatters.formatKgWithEquivalence(100),
        equals('100 kg (≈ 2 bultos)'),
      );
    });

    test('11. No mutación de inventario numérico subyacente', () {
      const double stockTotal = 1500.0;
      const double committed = 300.0;
      const double sold = 200.0;
      final available = stockTotal - committed - sold;

      final formattedStock = UnitFormatters.formatKg(available);
      expect(formattedStock, equals('1.000 kg'));
      // El cálculo matemático y los valores permanecen inalterados
      expect(available, equals(1000.0));
    });
  });

  group('DateFormatters (Español sin desfases de zona horaria)', () {
    test('12. parseCalendarDate y formatHarvestDate conservan el día exacto de cosecha', () {
      // Fecha en formato texto estándar ISO o fecha de Supabase
      const dateStr = '2026-10-25';
      expect(DateFormatters.formatHarvestDate(dateStr), equals('25/10/2026'));

      // Fecha en formato UTC con hora 00:00 (evitar que UTC-5 lo convierta al 24 de octubre)
      final utcMidnight = DateTime.utc(2026, 10, 25, 0, 0, 0);
      expect(DateFormatters.formatHarvestDate(utcMidnight), equals('25/10/2026'));

      // Formato largo en español
      expect(
        DateFormatters.formatHarvestDateLong('2026-10-25'),
        equals('25 de octubre, 2026'),
      );
    });

    test('13. formatDate y formatMediumDate en español', () {
      final date = DateTime(2026, 5, 4);
      expect(DateFormatters.formatDate(date), equals('04/05/2026'));
      expect(DateFormatters.formatMediumDate(date), contains('may'));
    });

    test('14. formatOfferDateTime y formatFullDateTime', () {
      final dateTime = DateTime(2026, 10, 25, 14, 30);
      final offerStr = DateFormatters.formatOfferDateTime(dateTime);
      expect(offerStr, contains('25/10'));

      final fullStr = DateFormatters.formatFullDateTime(dateTime);
      expect(fullStr, contains('25'));
      expect(fullStr, contains('2026'));
    });

    test('15. Manejo de fechas nulas', () {
      expect(DateFormatters.formatHarvestDate(null), equals('--'));
      expect(DateFormatters.formatDate(null), equals('--'));
      expect(DateFormatters.formatMediumDate(null), equals('--'));
      expect(DateFormatters.formatOfferDateTime(null), equals('--'));
    });
  });

  group('Integración en Widgets (CropCard y CropDetailScreen)', () {
    final sampleCrop = CropModel(
      id: 'test-crop-format-01',
      farmerId: 'farmer-uuid-01',
      title: 'Papa Pastusa Seleccionada',
      description: 'Papa de primera calidad para distribución mayorista.',
      cropType: 'Papa',
      pricePerKg: 2500.0,
      stockTotal: 1000.0,
      minOrderKg: 50.0,
      estimatedYieldKg: 2000.0,
      department: 'Nariño',
      municipality: 'Ipiales',
      isEarlySale: true,
      estimatedHarvestDate: DateTime(2026, 11, 28),
      status: CropStatus.activa,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 2),
    );

    testWidgets('16. CropCard muestra precio en COP (\$ 2.500) y stock en kg (1.000 kg)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropCard(
            crop: sampleCrop,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$ 2.500'), findsOneWidget);
      expect(find.text('1.000 kg'), findsOneWidget);
    });

    testWidgets('17. CropDetailScreen despliega precio COP, stock con equivalencia tradicional y fecha en español', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: sampleCrop,
            role: 'agricultor',
            isOwner: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Precio por kg: $ 2.500
      expect(find.text(r'$ 2.500'), findsOneWidget);

      // Stock con equivalencia tradicional: 1.000 kg (≈ 1 tonelada)
      expect(find.text('1.000 kg (≈ 1 tonelada)'), findsOneWidget);

      // Pedido mínimo: 50 kg
      expect(find.text('50 kg'), findsOneWidget);

      // Fecha estimada de cosecha en español sin desfase
      expect(find.text('28 de noviembre, 2026'), findsOneWidget);

      // Rendimiento estimado con equivalencia: 2.000 kg (≈ 2 toneladas)
      expect(find.text('2.000 kg (≈ 2 toneladas)'), findsOneWidget);
    });
  });
}
