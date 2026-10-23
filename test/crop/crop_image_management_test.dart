import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/theme/app_icons.dart';
import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/publish_crop_screen.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';

class MockCropServiceForManagement extends CropService {
  CropModel? lastSavedCrop;
  List<File>? lastNewImages;
  List<String>? lastRemovedImages;
  final List<String> deletedCropIds = [];
  final List<String> deletedImagePaths = [];

  @override
  Future<CropModel> saveCrop(
    CropModel crop, {
    List<File>? newImages,
    List<String>? removedImages,
  }) async {
    lastSavedCrop = crop;
    lastNewImages = newImages;
    lastRemovedImages = removedImages;
    return crop;
  }

  @override
  Future<void> deleteCrop(String cropId) async {
    deletedCropIds.add(cropId);
  }

  @override
  Future<void> deleteCropImage(String cropId, String imagePath) async {
    deletedImagePaths.add(imagePath);
  }

  @override
  String getPublicImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return 'https://placeholder.supabase.co/storage/v1/object/public/product_images/$imagePath';
  }
}

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
    id: 'crop-manage-100',
    farmerId: 'farmer-test-1',
    title: 'Tomate Chonto',
    description: 'Tomate de primera calidad',
    cropType: 'Tomate',
    pricePerKg: 3500.0,
    stockTotal: 400.0,
    stockCommitted: 0.0,
    stockSold: 0.0,
    minOrderKg: 10.0,
    department: 'Cundinamarca',
    municipality: 'Fusagasugá',
    status: CropStatus.activa,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    imageUrls: const [
      'crop-manage-100/img_1.jpg',
      'crop-manage-100/img_2.jpg',
      'crop-manage-100/img_3.jpg',
    ],
  );

  final sampleFarmerProfile = FarmerProfileData(
    id: 'farmer-test-1',
    fullName: 'Agricultor Dueño',
    role: 'agricultor',
    email: 'farmer@test.com',
    phone: '+57 300 000 0000',
    profilePath: null,
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: true,
      shareLocation: true,
      shareWhatsapp: true,
    ),
    stats: FarmerStatsData(
      published: 3,
      negotiating: 0,
      closed: 2,
    ),
  );

  group('Fase 2 — Gestión de imágenes al editar y eliminar publicaciones', () {
    testWidgets('1. Quitar una imagen existente al editar un cultivo la retira de la UI y envía removedImages', (tester) async {
      final mockService = MockCropServiceForManagement();

      await tester.pumpWidget(
        createTestWidget(
          child: PublishCropScreen(
            cropToEdit: baseCrop,
            cropService: mockService,
            currentUserIdForTesting: 'farmer-test-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Desplazarse hasta el listado de imágenes existentes
      await tester.ensureVisible(find.byKey(const Key('existing_images_list')));
      await tester.pumpAndSettle();

      // Debe mostrar el listado de imágenes existentes con 3 elementos
      expect(find.byKey(const Key('existing_images_list')), findsOneWidget);
      expect(find.byKey(const Key('remove_existing_image_0')), findsOneWidget);
      expect(find.byKey(const Key('remove_existing_image_1')), findsOneWidget);
      expect(find.byKey(const Key('remove_existing_image_2')), findsOneWidget);

      // Quitar la segunda imagen (índice 1 -> img_2.jpg)
      await tester.tap(find.byKey(const Key('remove_existing_image_1')));
      await tester.pumpAndSettle();

      // Ahora solo deben quedar 2 botones de quitar imagen existente
      expect(find.byKey(const Key('remove_existing_image_0')), findsOneWidget);
      expect(find.byKey(const Key('remove_existing_image_1')), findsOneWidget);
      expect(find.byKey(const Key('remove_existing_image_2')), findsNothing);

      // Desplazarse hasta el botón de Guardar Borrador
      await tester.ensureVisible(find.text('Guardar Borrador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar Borrador'));
      await tester.pumpAndSettle();

      // Verificar que el servicio recibió removedImages con la imagen eliminada
      expect(mockService.lastRemovedImages, isNotNull);
      expect(mockService.lastRemovedImages, equals(['crop-manage-100/img_2.jpg']));

      // Verificar que el cultivo conserva intactas las otras dos imágenes
      expect(mockService.lastSavedCrop, isNotNull);
      expect(
        mockService.lastSavedCrop!.imageUrls,
        equals(['crop-manage-100/img_1.jpg', 'crop-manage-100/img_3.jpg']),
      );
    });

    testWidgets('2. Mantener intactas todas las imágenes existentes no genera removedImages', (tester) async {
      final mockService = MockCropServiceForManagement();

      await tester.pumpWidget(
        createTestWidget(
          child: PublishCropScreen(
            cropToEdit: baseCrop,
            cropService: mockService,
            currentUserIdForTesting: 'farmer-test-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Guardar sin quitar ninguna imagen
      await tester.ensureVisible(find.text('Guardar Borrador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar Borrador'));
      await tester.pumpAndSettle();

      // removedImages debe ser null (ninguna eliminada)
      expect(mockService.lastRemovedImages, isNull);

      // imageUrls debe conservar exactamente las 3 imágenes originales
      expect(mockService.lastSavedCrop!.imageUrls, equals(baseCrop.imageUrls));
    });

    testWidgets('3. Quitar todas las imágenes oculta la sección y envía todas las rutas en removedImages', (tester) async {
      final mockService = MockCropServiceForManagement();
      final cropSingleImage = baseCrop.copyWith(imageUrls: ['crop-manage-100/only_img.jpg']);

      await tester.pumpWidget(
        createTestWidget(
          child: PublishCropScreen(
            cropToEdit: cropSingleImage,
            cropService: mockService,
            currentUserIdForTesting: 'farmer-test-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('existing_images_list')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('existing_images_list')), findsOneWidget);

      // Quitar la única imagen
      await tester.tap(find.byKey(const Key('remove_existing_image_0')));
      await tester.pumpAndSettle();

      // La sección de imágenes existentes debe desaparecer
      expect(find.byKey(const Key('existing_images_list')), findsNothing);

      // Guardar borrador
      await tester.ensureVisible(find.text('Guardar Borrador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar Borrador'));
      await tester.pumpAndSettle();

      // removedImages debe contener la ruta eliminada
      expect(mockService.lastRemovedImages, equals(['crop-manage-100/only_img.jpg']));
      expect(mockService.lastSavedCrop!.imageUrls, isEmpty);
    });

    testWidgets('4. Eliminar un cultivo desde CropDetailScreen dispara confirmación y ejecuta deleteCrop', (tester) async {
      final mockService = MockCropServiceForManagement();

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: baseCrop,
            role: 'agricultor',
            isOwner: true,
            cropService: mockService,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // El agricultor dueño tiene el botón de borrar en el AppBar (icono LucideIcons.trash2)
      final deleteIcon = find.byIcon(LucideIcons.trash2);
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Debe aparecer el diálogo modal de confirmación
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('¿Estás seguro de que deseas borrar esta publicación? Esta acción no se puede deshacer.'), findsOneWidget);

      // Confirmar en el diálogo
      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Borrar'),
      );
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verificar que deleteCrop fue llamado con el id del cultivo
      expect(mockService.deletedCropIds, contains(baseCrop.id));
    });

    testWidgets('5. Cancelar el diálogo de borrado no ejecuta deleteCrop', (tester) async {
      final mockService = MockCropServiceForManagement();

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: baseCrop,
            role: 'agricultor',
            isOwner: true,
            cropService: mockService,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteIcon = find.byIcon(LucideIcons.trash2);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // deleteCrop no debe haber sido llamado
      expect(mockService.deletedCropIds, isEmpty);
    });

    testWidgets('6. Navegación a edición desde CropDetailScreen abre PublishCropScreen con datos e imágenes', (tester) async {
      final mockService = MockCropServiceForManagement();

      await tester.pumpWidget(
        createTestWidget(
          child: CropDetailScreen(
            crop: baseCrop,
            role: 'agricultor',
            isOwner: true,
            cropService: mockService,
            initialFarmerProfile: sampleFarmerProfile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tocar el botón de editar en el AppBar
      final editIcon = find.byIcon(LucideIcons.pencil);
      expect(editIcon, findsOneWidget);

      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Debe abrir PublishCropScreen en modo edición
      expect(find.byType(PublishCropScreen), findsOneWidget);
      expect(find.text('Tomate Chonto'), findsOneWidget);
    });

    test('7. CropService deleteCropImage registra la ruta a eliminar', () async {
      final mockService = MockCropServiceForManagement();

      await mockService.deleteCropImage('crop-123', 'crop-123/foto.jpg');

      expect(mockService.deletedImagePaths, contains('crop-123/foto.jpg'));
    });
  });
}
