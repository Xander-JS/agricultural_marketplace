import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crop_model.dart';
import '../../../core/constants/user_roles.dart';
import '../../deals/exceptions/commercial_exception.dart';

class CropService {
  final SupabaseClient _supabase;
  final Future<String?> Function()? currentUserRoleFetcher;
  final String? Function()? currentUserIdFetcher;

  CropService({
    SupabaseClient? client,
    this.currentUserRoleFetcher,
    this.currentUserIdFetcher,
  }) : _supabase = client ?? Supabase.instance.client;

  String? get currentUserId =>
      currentUserIdFetcher?.call() ?? _supabase.auth.currentUser?.id;

  Future<String?> getCurrentUserRole() async {
    final fetcher = currentUserRoleFetcher;
    if (fetcher != null) {
      return await fetcher();
    }
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final res = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return res?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _validateFarmerAccess({String? ownerFarmerId}) async {
    final role = await getCurrentUserRole();
    if (role != null) {
      if (UserRole.isBuyerRole(role)) {
        throw const CommercialAuthorizationException(
          'Acceso denegado: los compradores no pueden publicar, modificar ni eliminar cosechas.',
          code: '42501',
        );
      }
      if (UserRole.isModeratorRole(role)) {
        throw const CommercialAuthorizationException(
          'Acceso denegado: los moderadores no pueden gestionar publicaciones comerciales.',
          code: '42501',
        );
      }
    }

    final uid = currentUserId;
    if (ownerFarmerId != null &&
        ownerFarmerId.isNotEmpty &&
        uid != null &&
        uid.isNotEmpty &&
        ownerFarmerId != uid) {
      throw const CommercialAuthorizationException(
        'Acceso denegado: no puedes modificar o eliminar cosechas pertenecientes a otros productores.',
        code: '42501',
      );
    }
  }

  /// Obtiene todas las cosechas de un agricultor
  Future<List<CropModel>> getCropsByFarmerId(String farmerId) async {
    final response = await _supabase
        .from('crops')
        .select('*, crop_images(image_path, is_primary)')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => CropModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene todas las cosechas activas para compradores en el mercado
  Future<List<CropModel>> getActiveMarketplaceCrops({
    String? excludeFarmerId,
  }) async {
    var filterBuilder = _supabase
        .from('crops')
        .select('*, crop_images(image_path, is_primary)')
        .eq('status', 'activa');

    if (excludeFarmerId != null && excludeFarmerId.isNotEmpty) {
      filterBuilder = filterBuilder.neq('farmer_id', excludeFarmerId);
    }

    final response = await filterBuilder.order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((json) => CropModel.fromJson(json as Map<String, dynamic>))
        .where((crop) => crop.availableStock > 0)
        .toList();
  }

  /// Crea o actualiza una cosecha
  Future<CropModel> saveCrop(
    CropModel crop, {
    List<File>? newImages,
    List<String>? removedImages,
  }) async {
    await _validateFarmerAccess(
      ownerFarmerId: crop.id.isNotEmpty ? crop.farmerId : null,
    );
    final cropData = crop.toJson();

    // Si no tiene id (es nuevo)
    if (crop.id.isEmpty) {
      final response = await _supabase
          .from('crops')
          .insert(cropData)
          .select()
          .single();

      final newCrop = CropModel.fromJson(response);

      // Subir imágenes si existen
      if (newImages != null && newImages.isNotEmpty) {
        try {
          await _uploadImagesForCrop(newCrop.id, newImages, isInitial: true);
        } catch (uploadError) {
          // Si falla la subida de imágenes durante la publicación de un nuevo cultivo,
          // limpiar el cultivo huérfano en BD para evitar estados inconsistentes
          try {
            await _supabase.from('crops').delete().eq('id', newCrop.id);
          } catch (_) {}
          rethrow;
        }
        try {
          final fullResponse = await _supabase
              .from('crops')
              .select('*, crop_images(image_path, is_primary)')
              .eq('id', newCrop.id)
              .single();
          return CropModel.fromJson(fullResponse);
        } catch (_) {
          return newCrop;
        }
      }
      return newCrop;
    } else {
      // Es una actualización
      cropData['updated_at'] = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('crops')
          .update(cropData)
          .eq('id', crop.id)
          .select()
          .single();

      final updatedCrop = CropModel.fromJson(response);

      // 1. Eliminar imágenes quitadas por el usuario (de Storage y de crop_images)
      if (removedImages != null && removedImages.isNotEmpty) {
        for (final path in removedImages) {
          await deleteCropImage(crop.id, path);
        }
      }

      // 2. Verificar estado de imágenes existentes y promover a principal si la anterior fue eliminada
      final currentRecords = await _supabase
          .from('crop_images')
          .select('id, image_path, is_primary')
          .eq('crop_id', crop.id);

      final recordsList = (currentRecords as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final hasPrimary = recordsList.any((r) => r['is_primary'] == true);

      if (!hasPrimary && recordsList.isNotEmpty) {
        final firstRecordId = recordsList.first['id'];
        await _supabase
            .from('crop_images')
            .update({'is_primary': true})
            .eq('id', firstRecordId);
      }

      // 3. Subir nuevas imágenes sin duplicar las existentes
      if (newImages != null && newImages.isNotEmpty) {
        final needsPrimary = !hasPrimary && recordsList.isEmpty;
        await _uploadImagesForCrop(
          updatedCrop.id,
          newImages,
          isInitial: needsPrimary,
        );
      }

      // 4. Retornar el cultivo con la lista completa y actualizada de crop_images
      try {
        final fullResponse = await _supabase
            .from('crops')
            .select('*, crop_images(image_path, is_primary)')
            .eq('id', updatedCrop.id)
            .single();

        return CropModel.fromJson(fullResponse);
      } catch (_) {
        return updatedCrop;
      }
    }
  }

  /// Actualiza solo el estado de la cosecha
  Future<void> updateCropStatus(String cropId, CropStatus status) async {
    await _validateFarmerAccess();
    await _supabase
        .from('crops')
        .update({
          'status': status.toShortString(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', cropId);
  }

  /// Elimina una imagen específica de un cultivo de Storage y de la BD
  Future<void> deleteCropImage(String cropId, String imagePath) async {
    final isAllowedPath =
        imagePath.startsWith('$cropId/') && !imagePath.contains('..');
    if (isAllowedPath &&
        !imagePath.startsWith('http://') &&
        !imagePath.startsWith('https://')) {
      try {
        await _supabase.storage.from('product_images').remove([imagePath]);
      } catch (_) {}
    }

    await _supabase
        .from('crop_images')
        .delete()
        .eq('crop_id', cropId)
        .eq('image_path', imagePath);

    // Si la imagen eliminada era la principal y quedan otras imágenes válidas, promover una
    try {
      final remainingRecords = await _supabase
          .from('crop_images')
          .select('id, is_primary')
          .eq('crop_id', cropId);

      final recordsList = (remainingRecords as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final hasPrimary = recordsList.any((r) => r['is_primary'] == true);

      if (!hasPrimary && recordsList.isNotEmpty) {
        final firstRecordId = recordsList.first['id'];
        await _supabase
            .from('crop_images')
            .update({'is_primary': true})
            .eq('id', firstRecordId);
      }
    } catch (_) {}
  }

  /// Elimina una cosecha junto con sus registros e imágenes almacenadas
  Future<void> deleteCrop(String cropId) async {
    await _validateFarmerAccess();
    // 1. Obtener las rutas de imágenes asociadas en crop_images
    final imagesResponse = await _supabase
        .from('crop_images')
        .select('image_path')
        .eq('crop_id', cropId);

    final paths = (imagesResponse as List<dynamic>)
        .map((r) => r['image_path'] as String?)
        .where(
          (p) =>
              p != null &&
              p.isNotEmpty &&
              p.startsWith('$cropId/') &&
              !p.contains('..') &&
              !p.startsWith('http://') &&
              !p.startsWith('https://'),
        )
        .cast<String>()
        .toList();

    // 2. Intentar listar archivos adicionales en la carpeta del cultivo en storage
    try {
      final listedFiles = await _supabase.storage
          .from('product_images')
          .list(path: cropId);
      for (final f in listedFiles) {
        if (f.name.isNotEmpty && !f.name.startsWith('.')) {
          final fullPath = '$cropId/${f.name}';
          if (!paths.contains(fullPath)) {
            paths.add(fullPath);
          }
        }
      }
    } catch (_) {}

    // 3. Limpiar las imágenes almacenadas en Supabase Storage
    // (Importante hacerlo antes de eliminar de crops para que la política RLS valide propiedad)
    if (paths.isNotEmpty) {
      try {
        await _supabase.storage.from('product_images').remove(paths);
      } catch (_) {}
    }

    // 4. Borrar registros en crop_images
    await _supabase.from('crop_images').delete().eq('crop_id', cropId);

    // 5. Borrar la cosecha en crops
    await _supabase.from('crops').delete().eq('id', cropId);
  }

  /// Sube las imágenes al bucket y guarda los registros en crop_images
  Future<void> _uploadImagesForCrop(
    String cropId,
    List<File> images, {
    bool isInitial = true,
  }) async {
    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final extension = file.path.split('.').last.toLowerCase();
      final ext = ['jpg', 'jpeg', 'png'].contains(extension)
          ? extension
          : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final filePath = '$cropId/$fileName';

      // Asumimos que el bucket se llama 'product_images'
      await _supabase.storage
          .from('product_images')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      // Guardar el registro en la tabla crop_images con rollback si falla la BD
      try {
        await _supabase.from('crop_images').insert({
          'crop_id': cropId,
          'image_path': filePath,
          'is_primary': isInitial && i == 0,
        });
      } catch (dbError) {
        // En caso de fallo parcial en BD, eliminar de Storage para no dejar archivos huérfanos
        try {
          await _supabase.storage.from('product_images').remove([filePath]);
        } catch (_) {}
        rethrow;
      }
    }
  }

  /// Obtiene la URL pública de una imagen
  String getPublicImageUrl(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return _supabase.storage.from('product_images').getPublicUrl(imagePath);
  }
}
