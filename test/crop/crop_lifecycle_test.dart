import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/utils/app_formatters.dart';
import 'package:agricultural_marketplace/features/crop/models/crop_model.dart';
import 'package:agricultural_marketplace/features/crop/screens/crop_detail_screen.dart';
import 'package:agricultural_marketplace/features/crop/screens/publish_crop_screen.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/crop/widgets/crop_card.dart';
import 'package:agricultural_marketplace/features/geo/models/simulated_location.dart';
import 'package:agricultural_marketplace/features/profile/models/farmer_profile_data.dart';

/// Test double que simula el ciclo de vida completo de CropService
/// con registro de operaciones y capacidad de inducir fallos parciales controlados.
class MockCropServiceForLifecycle extends CropService {
  CropModel? lastSavedCrop;
  List<File>? lastNewImages;
  List<String>? lastRemovedImages;
  final List<String> executionLog = [];
  final List<String> deletedCropIds = [];
  final List<String> deletedImagePaths = [];

  bool simulateUploadErrorOnCreate = false;
  bool simulateUpdateError = false;
  bool simulateDeleteError = false;

  final Map<String, List<Map<String, dynamic>>> inMemoryImages = {};

  MockCropServiceForLifecycle() : super();

  @override
  String getPublicImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return 'https://placeholder.supabase.co/storage/v1/object/public/product_images/$imagePath';
  }

  @override
  Future<CropModel> saveCrop(
    CropModel crop, {
    List<File>? newImages,
    List<String>? removedImages,
  }) async {
    lastSavedCrop = crop;
    lastNewImages = newImages;
    lastRemovedImages = removedImages;

    // Caso A: Creación de nuevo cultivo
    if (crop.id.isEmpty) {
      executionLog.add('db.insert_crop:${crop.title}');
      const generatedId = 'new-crop-generated-uuid';
      final createdCrop = crop.copyWith(id: generatedId);

      if (newImages != null && newImages.isNotEmpty) {
        if (simulateUploadErrorOnCreate) {
          // Simular fallo de subida y rollback del cultivo creado
          executionLog.add('storage.upload_failed');
          executionLog.add('db.rollback_delete_crop:$generatedId');
          throw Exception('STORAGE_UPLOAD_ERROR');
        }

        // Subida exitosa: la primera imagen es primaria
        final imagePaths = <String>[];
        for (int i = 0; i < newImages.length; i++) {
          final path = '$generatedId/image_$i.jpg';
          imagePaths.add(path);
          inMemoryImages.putIfAbsent(generatedId, () => []).add({
            'id': 'img-$i',
            'image_path': path,
            'is_primary': i == 0,
          });
          executionLog.add('storage.upload:$path');
          executionLog.add('db.insert_crop_image:$path:primary=${i == 0}');
        }
        return createdCrop.copyWith(imageUrls: imagePaths);
      }
      return createdCrop;
    }

    // Caso B: Actualización de cultivo existente
    if (simulateUpdateError) {
      executionLog.add('db.update_crop_failed:${crop.id}');
      throw Exception('DB_UPDATE_ERROR');
    }

    executionLog.add('db.update_crop:${crop.id}');

    // 1. Eliminar imágenes solicitadas
    if (removedImages != null && removedImages.isNotEmpty) {
      for (final path in removedImages) {
        await deleteCropImage(crop.id, path);
      }
    }

    // 2. Subir nuevas imágenes si existen
    final currentImages = inMemoryImages[crop.id] ?? [];
    final hasPrimary = currentImages.any((r) => r['is_primary'] == true);

    if (newImages != null && newImages.isNotEmpty) {
      for (int i = 0; i < newImages.length; i++) {
        final path = '${crop.id}/new_image_$i.jpg';
        final isPrimary = !hasPrimary && currentImages.isEmpty && i == 0;
        currentImages.add({
          'id': 'new-img-$i',
          'image_path': path,
          'is_primary': isPrimary,
        });
        executionLog.add('storage.upload:$path');
        executionLog.add('db.insert_crop_image:$path:primary=$isPrimary');
      }
    }

    final updatedUrls = currentImages
        .map((e) => e['image_path'] as String)
        .toList();
    return crop.copyWith(imageUrls: updatedUrls);
  }

  @override
  Future<void> deleteCropImage(String cropId, String imagePath) async {
    // Sanitización de seguridad: debe pertenecer a la carpeta del cultivo y sin traversal
    final isAllowed =
        imagePath.startsWith('$cropId/') && !imagePath.contains('..');
    if (isAllowed &&
        !imagePath.startsWith('http://') &&
        !imagePath.startsWith('https://')) {
      deletedImagePaths.add(imagePath);
      executionLog.add('storage.remove:$imagePath');
    }

    executionLog.add('db.delete_crop_image:$imagePath');

    final list = inMemoryImages[cropId] ?? [];
    list.removeWhere((r) => r['image_path'] == imagePath);

    // Promover si quedó sin primaria y aún tiene imágenes
    final hasPrimary = list.any((r) => r['is_primary'] == true);
    if (!hasPrimary && list.isNotEmpty) {
      list.first['is_primary'] = true;
      executionLog.add('db.promote_primary:${list.first['image_path']}');
    }
  }

  @override
  Future<void> deleteCrop(String cropId) async {
    if (simulateDeleteError) {
      executionLog.add('delete_crop_failed:$cropId');
      throw Exception('DB_DELETE_CONSTRAINT_ERROR');
    }

    deletedCropIds.add(cropId);

    // Limpieza de Storage ANTES de eliminar el cultivo en BD
    final list = inMemoryImages[cropId] ?? [];
    for (final item in list) {
      final path = item['image_path'] as String;
      if (path.startsWith('$cropId/') && !path.contains('..')) {
        executionLog.add('storage.remove_on_crop_delete:$path');
      }
    }

    executionLog.add('db.delete_crop_images:$cropId');
    executionLog.add('db.delete_crop:$cropId');
    inMemoryImages.remove(cropId);
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

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: LocalizationConfig.defaultLocale,
      supportedLocales: LocalizationConfig.supportedLocales,
      localizationsDelegates: LocalizationConfig.localizationsDelegates,
      home: child,
    );
  }

  final baseActiveCrop = CropModel(
    id: 'crop-narino-001',
    farmerId: 'farmer-uuid-001',
    title: 'Café Nariño Supremo',
    description: 'Café de altura cultivado en La Unión, Nariño.',
    cropType: 'Café',
    pricePerKg: 19500.0,
    stockTotal: 1200.0,
    stockCommitted: 200.0,
    stockSold: 100.0,
    minOrderKg: 20.0,
    estimatedYieldKg: 1500.0,
    department: 'Nariño',
    municipality: 'La Unión',
    latitude: 1.6033,
    longitude: -77.1315,
    isEarlySale: false,
    estimatedHarvestDate: DateTime(2026, 12, 15),
    status: CropStatus.activa,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 15),
    imageUrls: const [
      'crop-narino-001/primary.jpg',
      'crop-narino-001/second.jpg',
    ],
  );

  final sampleFarmerProfile = FarmerProfileData(
    id: 'farmer-uuid-001',
    fullName: 'Don Laureano Gómez',
    role: 'agricultor',
    email: 'laureano@agro.co',
    phone: '+57 312 345 6789',
    profilePath: 'farmer-uuid-001/avatar.jpg',
    department: 'Nariño',
    municipality: 'La Unión',
    latitude: 1.6033,
    longitude: -77.1315,
    settings: FarmerSettingsData(
      enableEarlySale: false,
      sharePhone: true,
      shareLocation: true,
      shareWhatsapp: true,
    ),
    stats: FarmerStatsData(published: 5, negotiating: 2, closed: 8),
  );

  group('Fase 2 — Subetapa 2.7: Auditoría del Ciclo de Vida de los Cultivos', () {
    // =========================================================================
    // SECCIÓN A: PUBLICACIÓN DE UN CULTIVO
    // =========================================================================
    testWidgets(
      'A1. Publicación válida con campos obligatorios asigna simulación geo si no tiene coordenadas',
      (tester) async {
        final mockService = MockCropServiceForLifecycle();

        await tester.pumpWidget(
          createTestWidget(
            child: PublishCropScreen(
              cropService: mockService,
              currentUserIdForTesting: 'farmer-uuid-001',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Completar campos obligatorios
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Papa Pastusa Selecta',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Papa de primera calidad para mercado mayorista.',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'Papa');
        await tester.enterText(find.byType(TextFormField).at(3), '2200');
        await tester.enterText(find.byType(TextFormField).at(4), '800');
        await tester.enterText(find.byType(TextFormField).at(5), '50');
        await tester.enterText(find.byType(TextFormField).at(7), 'Ipiales');

        // Presionar Guardar Borrador
        await tester.ensureVisible(find.text('Guardar Borrador'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar Borrador'));
        await tester.pumpAndSettle();

        expect(mockService.lastSavedCrop, isNotNull);
        final saved = mockService.lastSavedCrop!;
        expect(saved.title, equals('Papa Pastusa Selecta'));
        expect(saved.pricePerKg, equals(2200.0));
        expect(saved.stockTotal, equals(800.0));
        expect(saved.minOrderKg, equals(50.0));
        expect(saved.department, equals('Nariño'));
        expect(saved.municipality, equals('Ipiales'));
        expect(saved.farmerId, equals('farmer-uuid-001'));
        expect(saved.status, equals(CropStatus.borrador));

        // Verificación de ubicación geográfica simulada determinista
        expect(saved.latitude, isNotNull);
        expect(saved.longitude, isNotNull);
        expect(saved.latitude, inInclusiveRange(-90.0, 90.0));
        expect(saved.longitude, inInclusiveRange(-180.0, 180.0));
      },
    );

    testWidgets(
      'A2. Publicación rechaza formulario incompleto y no envía datos al servicio',
      (tester) async {
        final mockService = MockCropServiceForLifecycle();

        await tester.pumpWidget(
          createTestWidget(
            child: PublishCropScreen(
              cropService: mockService,
              currentUserIdForTesting: 'farmer-uuid-001',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Dejar campos vacíos y presionar Publicar
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Publicar'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Publicar'));
        await tester.pumpAndSettle();

        // No debe haberse invocado el servicio
        expect(mockService.lastSavedCrop, isNull);
        expect(
          find.text(
            'Por favor, completa los campos obligatorios correctamente.',
          ),
          findsOneWidget,
        );
      },
    );

    test('A3. Publicación sin imágenes es válida y crea el cultivo con lista de imágenes vacía', () async {
      final mockService = MockCropServiceForLifecycle();
      final newCrop = CropModel(
        id: '',
        farmerId: 'farmer-uuid-001',
        title: 'Cebolla Junca',
        description: 'Cultivo fresco sin fotos',
        cropType: 'Cebolla',
        pricePerKg: 1500.0,
        stockTotal: 300.0,
        minOrderKg: 10.0,
        department: 'Nariño',
        municipality: 'Pasto',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await mockService.saveCrop(newCrop, newImages: null);
      expect(result.id, equals('new-crop-generated-uuid'));
      expect(result.imageUrls, isEmpty);
      expect(
        mockService.executionLog,
        contains('db.insert_crop:Cebolla Junca'),
      );
      expect(mockService.executionLog, isNot(contains('storage.upload')));
    });

    test('A4. Publicación con imágenes asigna la primera imagen como principal y sube a Storage', () async {
      final mockService = MockCropServiceForLifecycle();
      final newCrop = CropModel(
        id: '',
        farmerId: 'farmer-uuid-001',
        title: 'Fresa Andina',
        description: 'Fresas frescas de altura',
        cropType: 'Fresa',
        pricePerKg: 6500.0,
        stockTotal: 150.0,
        minOrderKg: 5.0,
        department: 'Nariño',
        municipality: 'Túquerres',
        status: CropStatus.activa,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final images = [File('fresa_1.jpg'), File('fresa_2.jpg')];
      final result = await mockService.saveCrop(newCrop, newImages: images);

      expect(result.imageUrls.length, equals(2));
      expect(
        result.imageUrls.first,
        equals('new-crop-generated-uuid/image_0.jpg'),
      );
      expect(
        mockService.executionLog,
        contains(
          'db.insert_crop_image:new-crop-generated-uuid/image_0.jpg:primary=true',
        ),
      );
      expect(
        mockService.executionLog,
        contains(
          'db.insert_crop_image:new-crop-generated-uuid/image_1.jpg:primary=false',
        ),
      );
    });

    test('A5. Fallo de subida de imágenes durante la publicación revierte el cultivo en BD (anti-huérfanos)', () async {
      final mockService = MockCropServiceForLifecycle();
      mockService.simulateUploadErrorOnCreate = true;

      final newCrop = CropModel(
        id: '',
        farmerId: 'farmer-uuid-001',
        title: 'Cacao Fino',
        description: 'Cacao de aroma',
        cropType: 'Cacao',
        pricePerKg: 12000.0,
        department: 'Nariño',
        municipality: 'Tumaco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () async =>
            await mockService.saveCrop(newCrop, newImages: [File('cacao.jpg')]),
        throwsA(isA<Exception>()),
      );

      expect(
        mockService.executionLog,
        contains('db.rollback_delete_crop:new-crop-generated-uuid'),
      );
    });

    // =========================================================================
    // SECCIÓN B: EDICIÓN DE UN CULTIVO
    // =========================================================================
    testWidgets(
      'B1. Edición conserva coordenadas originales cuando no se modifica la ubicación',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockService = MockCropServiceForLifecycle();

        await tester.pumpWidget(
          createTestWidget(
            child: PublishCropScreen(
              cropToEdit: baseActiveCrop,
              cropService: mockService,
              currentUserIdForTesting: 'farmer-uuid-001',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Modificar únicamente el precio (campo en índice 3)
        final priceField = find.byType(TextFormField).at(3);
        await tester.ensureVisible(priceField);
        await tester.pumpAndSettle();
        await tester.enterText(priceField, '21000');

        // Desplazar el formulario para asegurar que los botones inferiores estén visibles
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar Borrador'));
        await tester.pumpAndSettle();

        expect(mockService.lastSavedCrop, isNotNull);
        final edited = mockService.lastSavedCrop!;
        expect(edited.pricePerKg, equals(21000.0));
        // Coordenadas deben conservarse idénticas
        expect(edited.latitude, equals(baseActiveCrop.latitude));
        expect(edited.longitude, equals(baseActiveCrop.longitude));
      },
    );

    test('B2. Invariante de inventario: CropModel.toJson() NUNCA envía stock_committed ni stock_sold', () {
      final cropWithCommitted = baseActiveCrop.copyWith(
        stockTotal: 1200.0,
        stockCommitted: 300.0,
        stockSold: 150.0,
      );

      final jsonPayload = cropWithCommitted.toJson();

      expect(
        jsonPayload.containsKey('stock_committed'),
        isFalse,
        reason: 'stock_committed no debe existir en toJson para proteger las columnas de inventario',
      );
      expect(
        jsonPayload.containsKey('stock_sold'),
        isFalse,
        reason: 'stock_sold no debe existir en toJson para proteger las columnas de inventario',
      );
      expect(jsonPayload['stock_total'], equals(1200.0));
      expect(
        cropWithCommitted.availableStock,
        equals(750.0),
      ); // 1200 - 300 - 150
    });

    test('B3. Edición con eliminación de imagen principal promueve la siguiente imagen a principal', () async {
      final mockService = MockCropServiceForLifecycle();
      const cropId = 'crop-narino-001';

      mockService.inMemoryImages[cropId] = [
        {
          'id': 'img-1',
          'image_path': '$cropId/primary.jpg',
          'is_primary': true,
        },
        {
          'id': 'img-2',
          'image_path': '$cropId/second.jpg',
          'is_primary': false,
        },
      ];

      // Eliminar la imagen primaria a través de deleteCropImage
      await mockService.deleteCropImage(cropId, '$cropId/primary.jpg');

      expect(
        mockService.executionLog,
        contains('storage.remove:$cropId/primary.jpg'),
      );
      expect(
        mockService.executionLog,
        contains('db.promote_primary:$cropId/second.jpg'),
      );
      expect(mockService.inMemoryImages[cropId]!.first['is_primary'], isTrue);
    });

    testWidgets(
      'B4. Error durante la edición en base de datos muestra SnackBar sin corromper la interfaz',
      (tester) async {
        final mockService = MockCropServiceForLifecycle();
        mockService.simulateUpdateError = true;

        await tester.pumpWidget(
          createTestWidget(
            child: PublishCropScreen(
              cropToEdit: baseActiveCrop,
              cropService: mockService,
              currentUserIdForTesting: 'farmer-uuid-001',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Guardar Borrador'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar Borrador'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error al guardar:'), findsOneWidget);
        // La pantalla sigue abierta (no hizo Navigator.pop)
        expect(find.byType(PublishCropScreen), findsOneWidget);
      },
    );

    // =========================================================================
    // SECCIÓN C: VISUALIZACIÓN DEL CULTIVO
    // =========================================================================
    testWidgets(
      'C1. CropCard muestra precios en COP, cantidades en kg y placeholder ante imagen nula',
      (tester) async {
        final cropNoImages = baseActiveCrop.copyWith(imageUrls: []);

        await tester.pumpWidget(
          createTestWidget(
            child: CropCard(crop: cropNoImages, onTap: () {}),
          ),
        );
        await tester.pumpAndSettle();

        // Debe mostrar título y tipo
        expect(find.text('Café Nariño Supremo'), findsOneWidget);
        expect(find.text('Café'), findsOneWidget);

        // Debe mostrar precio formateado COP con punto de miles ($ 19.500)
        expect(find.text(CurrencyFormatters.formatCop(19500)), findsOneWidget);

        // Debe mostrar el stock disponible (total - comprometido - vendido),
        // no el stock total bruto.
        expect(
          find.text(UnitFormatters.formatKg(cropNoImages.availableStock)),
          findsOneWidget,
        );
        expect(
          find.text(UnitFormatters.formatKg(cropNoImages.stockTotal)),
          findsNothing,
        );

        // Debe mostrar placeholder al no tener imágenes
        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'C2. CropCard muestra distancia calculada únicamente cuando distanceEvaluation es provista',
      (tester) async {
        const distanceEval = DistanceEvaluation(
          distanceKm: 42.5,
          category: DistanceRangeCategory.regionalShort,
          formatted: '42.5 km',
        );

        await tester.pumpWidget(
          createTestWidget(
            child: CropCard(
              crop: baseActiveCrop,
              onTap: () {},
              distanceEvaluation: distanceEval,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('42.5 km'), findsOneWidget);
      },
    );

    testWidgets(
      'C3. CropDetailScreen despliega carrusel de imágenes, detalles formateados y perfil del productor',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: CropDetailScreen(
              crop: baseActiveCrop,
              role: 'comprador',
              isOwner: false,
              initialFarmerProfile: sampleFarmerProfile,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Título y datos del productor
        expect(find.text('Café Nariño Supremo'), findsOneWidget);
        expect(find.text('Don Laureano Gómez'), findsOneWidget);

        // Precios y unidades formateadas
        expect(find.text(CurrencyFormatters.formatCop(19500)), findsWidgets);

        // Indicador de galería para 2 imágenes (1 / 2)
        expect(find.byKey(const Key('crop_gallery_indicator')), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);

        // No debe mostrar botón de editar o borrar a un comprador
        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
      },
    );

    // =========================================================================
    // SECCIÓN D: ELIMINACIÓN DEL CULTIVO Y PERMISOS
    // =========================================================================
    testWidgets(
      'D1. CropDetailScreen propietario puede solicitar borrado con diálogo de confirmación',
      (tester) async {
        final mockService = MockCropServiceForLifecycle();

        await tester.pumpWidget(
          createTestWidget(
            child: CropDetailScreen(
              crop: baseActiveCrop,
              role: 'agricultor',
              isOwner: true,
              cropService: mockService,
              initialFarmerProfile: sampleFarmerProfile,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Botón de borrar debe ser visible para el propietario en la barra superior
        final deleteBtn = find.byIcon(Icons.delete);
        expect(deleteBtn, findsOneWidget);

        // Presionar botón de borrar
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Diálogo de confirmación debe desplegarse
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Borrar Publicación'), findsOneWidget);

        // Confirmar borrado
        await tester.tap(find.text('Borrar'));
        await tester.pumpAndSettle();

        // deleteCrop debe haberse ejecutado
        expect(mockService.deletedCropIds, contains(baseActiveCrop.id));
      },
    );

    test('D2. deleteCrop elimina archivos de Storage antes de borrar en BD y filtra rutas ajenas', () async {
      final mockService = MockCropServiceForLifecycle();
      const cropId = 'crop-narino-001';

      mockService.inMemoryImages[cropId] = [
        {'id': 'img-1', 'image_path': '$cropId/img_1.jpg', 'is_primary': true},
        // Ruta manipulada ajena
        {
          'id': 'img-2',
          'image_path': 'other_crop/stolen.jpg',
          'is_primary': false,
        },
      ];

      await mockService.deleteCrop(cropId);

      // Comprobar orden de ejecución
      final storageIndex = mockService.executionLog.indexOf(
        'storage.remove_on_crop_delete:$cropId/img_1.jpg',
      );
      final dbIndex = mockService.executionLog.indexOf(
        'db.delete_crop:$cropId',
      );

      expect(storageIndex, isNot(-1));
      expect(dbIndex, isNot(-1));
      expect(
        storageIndex,
        lessThan(dbIndex),
        reason: 'Storage remove debe ocurrir antes del delete en BD para permitir verificación de permisos',
      );

      // Ruta ajena no debe haber sido enviada a Storage
      expect(
        mockService.executionLog,
        isNot(contains('storage.remove_on_crop_delete:other_crop/stolen.jpg')),
      );
    });

    testWidgets(
      'D3. Error al eliminar cultivo muestra SnackBar de error y no cierra la pantalla',
      (tester) async {
        final mockService = MockCropServiceForLifecycle();
        mockService.simulateDeleteError = true;

        await tester.pumpWidget(
          createTestWidget(
            child: CropDetailScreen(
              crop: baseActiveCrop,
              role: 'agricultor',
              isOwner: true,
              cropService: mockService,
              initialFarmerProfile: sampleFarmerProfile,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Borrar'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('DB_DELETE_CONSTRAINT_ERROR'),
          findsOneWidget,
        );
        expect(find.byType(CropDetailScreen), findsOneWidget);
      },
    );
  });
}
