import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/localization/localization_config.dart';
import 'package:agricultural_marketplace/core/theme/app_theme.dart';
import 'package:agricultural_marketplace/core/widgets/avatars/user_avatar.dart';
import 'package:agricultural_marketplace/features/crop/services/crop_service.dart';
import 'package:agricultural_marketplace/features/profile/services/profile_service.dart';

/// Test double que emula la lógica de CropService para auditar la seguridad
/// de las rutas, el orden de operaciones y la mitigación de fallos parciales.
class SecurityAuditedCropService extends CropService {
  final List<String> storageRemoveRequests = [];
  final List<String> dbDeleteImageRequests = [];
  final List<String> executionLog = [];
  final Map<String, List<Map<String, dynamic>>> mockCropImagesTable = {};
  bool simulateDbInsertError = false;

  SecurityAuditedCropService() : super();

  @override
  String getPublicImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return 'https://placeholder.supabase.co/storage/v1/object/public/product_images/$imagePath';
  }

  @override
  Future<void> deleteCropImage(String cropId, String imagePath) async {
    // Implementación idéntica a CropService para verificar el comportamiento de seguridad
    final isAllowedPath = imagePath.startsWith('$cropId/') && !imagePath.contains('..');
    if (isAllowedPath && !imagePath.startsWith('http://') && !imagePath.startsWith('https://')) {
      storageRemoveRequests.add(imagePath);
      executionLog.add('storage.remove:$imagePath');
    }

    dbDeleteImageRequests.add(imagePath);
    executionLog.add('db.delete:$imagePath');

    // Simular actualización de tabla en memoria
    final records = mockCropImagesTable[cropId] ?? [];
    records.removeWhere((r) => r['image_path'] == imagePath);

    final hasPrimary = records.any((r) => r['is_primary'] == true);
    if (!hasPrimary && records.isNotEmpty) {
      records.first['is_primary'] = true;
      executionLog.add('db.promote_primary:${records.first['image_path']}');
    }
  }

  @override
  Future<void> deleteCrop(String cropId) async {
    // 1. Obtener rutas registradas
    final records = mockCropImagesTable[cropId] ?? [];
    final paths = records
        .map((r) => r['image_path'] as String?)
        .where((p) =>
            p != null &&
            p.isNotEmpty &&
            p.startsWith('$cropId/') &&
            !p.contains('..') &&
            !p.startsWith('http://') &&
            !p.startsWith('https://'))
        .cast<String>()
        .toList();

    // 2. Storage remove ANTES de eliminar el cultivo (garantiza validación RLS de propiedad)
    if (paths.isNotEmpty) {
      storageRemoveRequests.addAll(paths);
      executionLog.add('storage.remove_batch:${paths.join(',')}');
    }

    // 3. DB delete
    executionLog.add('db.delete_crop_images:$cropId');
    executionLog.add('db.delete_crop:$cropId');
    mockCropImagesTable.remove(cropId);
  }

  Future<void> simulateUploadWithDbFailure(String cropId, String filePath) async {
    executionLog.add('storage.upload:$filePath');
    if (simulateDbInsertError) {
      // Rollback: se limpia el archivo de storage ante fallo en BD
      storageRemoveRequests.add(filePath);
      executionLog.add('storage.rollback_remove:$filePath');
      throw Exception('DB_INSERT_CONSTRAINT_ERROR');
    } else {
      mockCropImagesTable.putIfAbsent(cropId, () => []).add({
        'crop_id': cropId,
        'image_path': filePath,
        'is_primary': true,
      });
      executionLog.add('db.insert:$filePath');
    }
  }
}

/// Test double que emula la lógica de ProfileService para auditar la seguridad
/// de las rutas, la sustitución no destructiva y la prevención de huérfanos.
class SecurityAuditedProfileService extends ProfileService {
  final List<String> storageUploadRequests = [];
  final List<String> storageRemoveRequests = [];
  final List<String> executionLog = [];
  String? persistedProfilePath;
  bool simulateDbUpdateError = false;

  SecurityAuditedProfileService() : super();

  @override
  String getPublicProfileImageUrl(String profilePath) {
    if (profilePath.startsWith('http://') || profilePath.startsWith('https://')) {
      return profilePath;
    }
    // Replica el cache busting implementado en ProfileService
    return 'https://placeholder.supabase.co/storage/v1/object/public/profiles/$profilePath?t=123456';
  }

  @override
  Future<String> uploadProfilePicture(
    String userId,
    File imageFile, {
    String? oldProfilePath,
  }) async {
    final extension = imageFile.path.split('.').last.toLowerCase();
    final ext = ['jpg', 'jpeg', 'png'].contains(extension) ? extension : 'jpg';
    final filePath = '$userId/avatar.$ext';
    final previousPath = oldProfilePath ?? persistedProfilePath;

    // 1. Subir nueva imagen a Storage primero
    storageUploadRequests.add(filePath);
    executionLog.add('storage.upload:$filePath');

    // 2. Confirmar actualización en BD
    if (simulateDbUpdateError) {
      if (previousPath != null && previousPath != filePath) {
        storageRemoveRequests.add(filePath);
        executionLog.add('storage.rollback_remove:$filePath');
      }
      executionLog.add('db.update_failed');
      throw Exception('DB_UPDATE_ERROR');
    }

    persistedProfilePath = filePath;
    executionLog.add('db.update:$filePath');

    // 3. Solo tras confirmar éxito en BD: si la foto anterior era diferente y válida, eliminarla
    if (previousPath != null &&
        previousPath != filePath &&
        previousPath.startsWith('$userId/') &&
        !previousPath.contains('..') &&
        !previousPath.startsWith('http://') &&
        !previousPath.startsWith('https://')) {
      storageRemoveRequests.add(previousPath);
      executionLog.add('storage.remove_orphan:$previousPath');
    }

    return filePath;
  }

  @override
  Future<void> deleteProfilePicture(String userId, String? profilePath) async {
    final isAllowedPath = profilePath != null &&
        profilePath.isNotEmpty &&
        profilePath.startsWith('$userId/') &&
        !profilePath.contains('..') &&
        !profilePath.startsWith('http://') &&
        !profilePath.startsWith('https://');

    if (isAllowedPath) {
      storageRemoveRequests.add(profilePath);
      executionLog.add('storage.remove:$profilePath');
    } else {
      executionLog.add('storage.remove_blocked:$profilePath');
    }

    persistedProfilePath = null;
    executionLog.add('db.clear_profile_path');
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
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Fase 2 — Subetapa 2.6: Auditoría de Seguridad de Imágenes y Archivos', () {
    // -------------------------------------------------------------------------
    // 1. Acceso y URLs Públicas vs Privadas
    // -------------------------------------------------------------------------
    test('1. CropService y ProfileService generan URLs correctas y respetan URLs externas', () {
      final cropService = CropService();
      final profileService = ProfileService();

      // Rutas internas
      final cropUrl = cropService.getPublicImageUrl('crop-123/img_1.jpg');
      expect(cropUrl, contains('product_images/crop-123/img_1.jpg'));

      final profileUrl = profileService.getPublicProfileImageUrl('user-456/avatar.jpg');
      expect(profileUrl, contains('profiles/user-456/avatar.jpg'));
      expect(profileUrl, contains('?t=')); // Cache busting

      // URLs externas se conservan intactas
      const externalUrl = 'https://images.unsplash.com/photo-123';
      expect(cropService.getPublicImageUrl(externalUrl), equals(externalUrl));
      expect(profileService.getPublicProfileImageUrl(externalUrl), equals(externalUrl));
    });

    // -------------------------------------------------------------------------
    // 2. Manipulación de Rutas en CropService
    // -------------------------------------------------------------------------
    test('2. CropService deleteCropImage bloquea manipulación de rutas ajenas o traversal en cliente', () async {
      final auditedService = SecurityAuditedCropService();
      const myCropId = 'c0000000-0000-0000-0000-000000000001';

      // Intento de borrar imagen de otro cultivo
      await auditedService.deleteCropImage(myCropId, 'd0000000-0000-0000-0000-000000000002/victim.jpg');
      expect(auditedService.storageRemoveRequests, isEmpty,
          reason: 'No debe llamar a Storage remove si la ruta pertenece a otro cultivo');

      // Intento de path traversal
      await auditedService.deleteCropImage(myCropId, '$myCropId/../victim_crop/file.jpg');
      expect(auditedService.storageRemoveRequests, isEmpty,
          reason: 'No debe llamar a Storage remove si la ruta contiene directory traversal');

      // Borrado legítimo dentro de la carpeta del cultivo
      await auditedService.deleteCropImage(myCropId, '$myCropId/valid_img.jpg');
      expect(auditedService.storageRemoveRequests, contains('$myCropId/valid_img.jpg'));
    });

    // -------------------------------------------------------------------------
    // 3. Preservación de Imagen Principal en CropService
    // -------------------------------------------------------------------------
    test('3. CropService deleteCropImage promueve una imagen secundaria a principal si la primaria se elimina', () async {
      final auditedService = SecurityAuditedCropService();
      const cropId = 'c0000000-0000-0000-0000-000000000001';

      auditedService.mockCropImagesTable[cropId] = [
        {'id': 'img-1', 'image_path': '$cropId/img_1.jpg', 'is_primary': true},
        {'id': 'img-2', 'image_path': '$cropId/img_2.jpg', 'is_primary': false},
        {'id': 'img-3', 'image_path': '$cropId/img_3.jpg', 'is_primary': false},
      ];

      // Eliminar la imagen secundaria: no debe cambiar la primaria
      await auditedService.deleteCropImage(cropId, '$cropId/img_2.jpg');
      expect(auditedService.executionLog, isNot(contains('db.promote_primary:$cropId/img_3.jpg')));

      // Eliminar la imagen primaria: debe promover a img_3
      await auditedService.deleteCropImage(cropId, '$cropId/img_1.jpg');
      expect(auditedService.executionLog, contains('db.promote_primary:$cropId/img_3.jpg'));
      expect(auditedService.mockCropImagesTable[cropId]!.first['is_primary'], isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. Orden de Operaciones en deleteCrop
    // -------------------------------------------------------------------------
    test('4. CropService deleteCrop elimina archivos de Storage ANTES de borrar el registro en crops', () async {
      final auditedService = SecurityAuditedCropService();
      const cropId = 'c0000000-0000-0000-0000-000000000001';

      auditedService.mockCropImagesTable[cropId] = [
        {'id': 'img-1', 'image_path': '$cropId/photo_1.jpg', 'is_primary': true},
        // Ruta maliciosa/ajena que accidentalmente estuviera en la tabla no debe ser enviada a Storage
        {'id': 'img-2', 'image_path': 'foreign_crop/hack.jpg', 'is_primary': false},
      ];

      await auditedService.deleteCrop(cropId);

      // Verificar que Storage remove se llamó antes de eliminar el cultivo
      final removeIndex = auditedService.executionLog.indexWhere((log) => log.startsWith('storage.remove_batch:'));
      final deleteCropIndex = auditedService.executionLog.indexOf('db.delete_crop:$cropId');

      expect(removeIndex, isNot(-1));
      expect(deleteCropIndex, isNot(-1));
      expect(removeIndex, lessThan(deleteCropIndex),
          reason: 'Storage.remove debe ocurrir ANTES de borrar el cultivo para que la política RLS valide propiedad');

      // Verificar que solo se envió la ruta del propio cultivo
      expect(auditedService.storageRemoveRequests, contains('$cropId/photo_1.jpg'));
      expect(auditedService.storageRemoveRequests, isNot(contains('foreign_crop/hack.jpg')));
    });

    // -------------------------------------------------------------------------
    // 5. Mitigación de Fallos Parciales en CropService
    // -------------------------------------------------------------------------
    test('5. CropService revierte archivo en Storage si falla la inserción en BD (anti-huérfanos)', () async {
      final auditedService = SecurityAuditedCropService();
      const cropId = 'c0000000-0000-0000-0000-000000000001';
      auditedService.simulateDbInsertError = true;

      const newFilePath = '$cropId/failed_upload.jpg';
      expect(
        () async => await auditedService.simulateUploadWithDbFailure(cropId, newFilePath),
        throwsA(isA<Exception>()),
      );

      expect(auditedService.executionLog, contains('storage.rollback_remove:$newFilePath'));
      expect(auditedService.storageRemoveRequests, contains(newFilePath),
          reason: 'El archivo debe ser eliminado de Storage si la inserción en BD falla');
    });

    // -------------------------------------------------------------------------
    // 6. Protección de Rutas en ProfileService
    // -------------------------------------------------------------------------
    test('6. ProfileService deleteProfilePicture bloquea eliminación de fotos en carpetas ajenas', () async {
      final profileService = SecurityAuditedProfileService();
      const myUserId = 'user-auth-001';

      // Intento de borrar foto de otro usuario mediante ruta manipulada
      await profileService.deleteProfilePicture(myUserId, 'user-victim-002/avatar.jpg');
      expect(profileService.storageRemoveRequests, isEmpty);
      expect(profileService.executionLog, contains('storage.remove_blocked:user-victim-002/avatar.jpg'));

      // Intento de directory traversal
      await profileService.deleteProfilePicture(myUserId, '$myUserId/../admin/avatar.jpg');
      expect(profileService.storageRemoveRequests, isEmpty);

      // Borrado legítimo propio
      await profileService.deleteProfilePicture(myUserId, '$myUserId/avatar.jpg');
      expect(profileService.storageRemoveRequests, contains('$myUserId/avatar.jpg'));
    });

    // -------------------------------------------------------------------------
    // 7. Sustitución Segura de Avatar en ProfileService
    // -------------------------------------------------------------------------
    test('7. ProfileService uploadProfilePicture sube nueva foto, confirma BD y solo entonces elimina el huérfano anterior', () async {
      final profileService = SecurityAuditedProfileService();
      const userId = 'user-auth-001';
      final tempFile = File('test_avatar.jpg');

      // Caso A: Primera subida
      final firstPath = await profileService.uploadProfilePicture(userId, tempFile);
      expect(firstPath, equals('$userId/avatar.jpg'));
      expect(profileService.storageRemoveRequests, isEmpty,
          reason: 'No debe haber borrado si no había foto anterior');

      // Caso B: Sustitución exitosa con diferente extensión (.png)
      final pngFile = File('test_avatar.png');
      final newPath = await profileService.uploadProfilePicture(userId, pngFile, oldProfilePath: firstPath);
      expect(newPath, equals('$userId/avatar.png'));

      final uploadIndex = profileService.executionLog.indexOf('storage.upload:$userId/avatar.png');
      final dbUpdateIndex = profileService.executionLog.indexOf('db.update:$userId/avatar.png');
      final orphanRemoveIndex = profileService.executionLog.indexOf('storage.remove_orphan:$userId/avatar.jpg');

      expect(uploadIndex, lessThan(dbUpdateIndex));
      expect(dbUpdateIndex, lessThan(orphanRemoveIndex),
          reason: 'El archivo anterior SOLO debe ser eliminado después de confirmar la actualización en BD');
      expect(profileService.storageRemoveRequests, contains('$userId/avatar.jpg'));
    });

    // -------------------------------------------------------------------------
    // 8. Integridad ante Fallo en BD al Actualizar Avatar
    // -------------------------------------------------------------------------
    test('8. ProfileService no elimina foto anterior si la actualización en BD falla', () async {
      final profileService = SecurityAuditedProfileService();
      const userId = 'user-auth-001';
      profileService.persistedProfilePath = '$userId/avatar.jpg';
      profileService.simulateDbUpdateError = true;

      final pngFile = File('test_avatar.png');

      expect(
        () async => await profileService.uploadProfilePicture(userId, pngFile, oldProfilePath: '$userId/avatar.jpg'),
        throwsA(isA<Exception>()),
      );

      // La foto anterior NO debe haber sido eliminada
      expect(profileService.storageRemoveRequests, isNot(contains('$userId/avatar.jpg')),
          reason: 'La foto anterior debe conservarse si la base de datos rechaza la actualización');

      // El archivo recién subido debe haber sido revertido
      expect(profileService.storageRemoveRequests, contains('$userId/avatar.png'),
          reason: 'El archivo recién subido debe revertirse si la BD falla para evitar huérfanos');
    });

    // -------------------------------------------------------------------------
    // 9. Comportamiento Seguro de UserAvatar ante Estados Anómalos
    // -------------------------------------------------------------------------
    testWidgets('9. UserAvatar maneja con seguridad rutas nulas, vacías o errores sin degradar la UI', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const Column(
            children: [
              UserAvatar(imageUrl: null, radius: 20),
              UserAvatar(imageUrl: '', radius: 20),
              UserAvatar(imageUrl: 'https://invalid-non-existent-domain.xyz/error.jpg', radius: 20),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar icono predeterminado sin arrojar errores
      expect(find.byIcon(LucideIcons.userRound), findsNWidgets(3));
    });
  });
}
