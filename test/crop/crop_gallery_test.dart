import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/publish_crop_screen.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';

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

  final baseCrop = CropModel(
    id: 'crop-100',
    farmerId: 'farmer-200',
    title: 'Café Castillo Lavado',
    description: 'Café de origen de alta montaña en Fredonia.',
    cropType: 'Café',
    pricePerKg: 18000.0,
    stockTotal: 500.0,
    stockCommitted: 0.0,
    stockSold: 0.0,
    minOrderKg: 10.0,
    department: 'Antioquia',
    municipality: 'Fredonia',
    status: CropStatus.activa,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    imageUrls: const [],
  );

  final sampleFarmerProfile = FarmerProfileData(
    id: 'farmer-200',
    fullName: 'Don Hernando',
    role: 'agricultor',
    email: 'hernando@finca.co',
    phone: '+57 311 000 1122',
    profilePath: 'farmer-200/avatar.jpg',
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: true,
      shareLocation: true,
      shareWhatsapp: true,
    ),
    stats: FarmerStatsData(
      published: 4,
      negotiating: 1,
      closed: 6,
    ),
  );

  group('Fase 2.1 — Galería de Imágenes en CropDetailScreen', () {
    testWidgets('1. Cultivo sin imágenes muestra fallback y no genera PageView ni contador', (tester) async {
      final cropNoImages = baseCrop.copyWith(imageUrls: []);

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: cropNoImages,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el icono de fallback
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);

      // No debe existir PageView
      expect(find.byType(PageView), findsNothing);

      // No debe existir badge contador ni miniaturas
      expect(find.byKey(const Key('crop_gallery_indicator')), findsNothing);
      expect(find.byKey(const Key('crop_gallery_thumbnails')), findsNothing);
    });

    testWidgets('2. Cultivo con una sola imagen la despliega directamente sin controles de galería múltiple', (tester) async {
      final cropSingleImage = baseCrop.copyWith(
        imageUrls: ['https://images.example.com/single_crop.jpg'],
      );

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: cropSingleImage,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar Image sin PageView
      expect(find.byType(Image), findsWidgets);
      expect(find.byType(PageView), findsNothing);

      // No debe mostrar el contador de páginas
      expect(find.byKey(const Key('crop_gallery_indicator')), findsNothing);

      // No debe mostrar lista horizontal de miniaturas
      expect(find.byKey(const Key('crop_gallery_thumbnails')), findsNothing);
    });

    testWidgets('3. Cultivo con varias imágenes despliega PageView, contador de posición y miniaturas', (tester) async {
      final cropMultipleImages = baseCrop.copyWith(
        imageUrls: [
          'https://images.example.com/crop_1.jpg',
          'https://images.example.com/crop_2.jpg',
          'https://images.example.com/crop_3.jpg',
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: cropMultipleImages,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe existir PageView
      expect(find.byType(PageView), findsOneWidget);

      // Debe mostrar el indicador inicial "1 / 3"
      expect(find.text('1 / 3'), findsOneWidget);

      // Debe existir una fila horizontal de miniaturas
      expect(find.byKey(const Key('crop_gallery_thumbnails')), findsOneWidget);

      // Navegar a la segunda imagen mediante deslizamiento horizontal (fling)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // El contador debe actualizarse a "2 / 3"
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('4. Tocar una miniatura navega a la imagen correspondiente', (tester) async {
      final cropMultipleImages = baseCrop.copyWith(
        imageUrls: [
          'https://images.example.com/crop_1.jpg',
          'https://images.example.com/crop_2.jpg',
          'https://images.example.com/crop_3.jpg',
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: cropMultipleImages,
            role: 'comprador',
            isOwner: false,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 / 3'), findsOneWidget);

      // Buscar todos los GestureDetector en la barra de miniaturas
      final thumbnailFinders = find.descendant(
        of: find.byKey(const Key('crop_gallery_thumbnails')),
        matching: find.byType(GestureDetector),
      );
      expect(thumbnailFinders, findsNWidgets(3));

      // Tocar la tercera miniatura (índice 2)
      await tester.tap(thumbnailFinders.at(2));
      await tester.pumpAndSettle();

      // El contador debe marcar "3 / 3"
      expect(find.text('3 / 3'), findsOneWidget);
    });
  });

  group('Fase 2.1 — Modelo y Servicios de Galería', () {
    test('5. CropModel.fromJson ordena la imagen is_primary al principio de imageUrls', () {
      final json = {
        'id': 'crop-123',
        'farmer_id': 'farmer-abc',
        'title': 'Papa Pastusa',
        'description': 'Papa fresca seleccionada',
        'crop_type': 'Papa',
        'price_per_kg': 2500,
        'stock_total': 1000,
        'stock_committed': 0,
        'stock_sold': 0,
        'min_order_kg': 50,
        'department': 'Boyacá',
        'municipality': 'Tunja',
        'status': 'activa',
        'created_at': '2026-10-18T10:00:00Z',
        'updated_at': '2026-10-18T10:00:00Z',
        'crop_images': [
          {'image_path': 'crop-123/secundaria.jpg', 'is_primary': false},
          {'image_path': 'crop-123/principal.jpg', 'is_primary': true},
          {'image_path': 'crop-123/otra.jpg', 'is_primary': false},
        ],
      };

      final crop = CropModel.fromJson(json);

      expect(crop.imageUrls.length, equals(3));
      // La imagen principal debe ser la primera
      expect(crop.imageUrls.first, equals('crop-123/principal.jpg'));
    });

    test('6. CropModel.copyWith preserva y actualiza imageUrls adecuadamente', () {
      final crop = baseCrop.copyWith(imageUrls: ['img_a.jpg']);
      expect(crop.imageUrls, equals(['img_a.jpg']));

      final updatedCrop = crop.copyWith(imageUrls: ['img_b.jpg', 'img_c.jpg']);
      expect(updatedCrop.imageUrls, equals(['img_b.jpg', 'img_c.jpg']));
      expect(updatedCrop.title, equals(baseCrop.title));
    });

    test('7. CropService.getPublicImageUrl resuelve URLs absolutas y relativas', () {
      final service = CropService();

      // URLs absolutas se devuelven sin alteración
      const httpUrl = 'https://s3.amazonaws.com/bucket/image.jpg';
      expect(service.getPublicImageUrl(httpUrl), equals(httpUrl));

      // Rutas relativas usan el bucket de product_images
      const relativePath = 'crop-999/image_1.jpg';
      final resolvedUrl = service.getPublicImageUrl(relativePath);
      expect(resolvedUrl, contains('product_images'));
      expect(resolvedUrl, contains('crop-999/image_1.jpg'));
    });
  });

  group('Fase 2.1 — Compatibilidad con PublishCropScreen', () {
    testWidgets('8. PublishCropScreen en edición despliega sección de imágenes existentes', (tester) async {
      final cropToEdit = baseCrop.copyWith(
        imageUrls: [
          'https://images.example.com/crop_prev_1.jpg',
          'https://images.example.com/crop_prev_2.jpg',
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          child: PublishCropScreen(cropToEdit: cropToEdit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imágenes actuales de la publicación:'), findsOneWidget);
      expect(find.text('Añadir Imágenes'), findsOneWidget);
    });
  });
}
