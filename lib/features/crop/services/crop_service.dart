import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_model.dart';
import '../models/crop_image_model.dart';

class CropService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Crea o actualiza una cosecha
  Future<CropModel> saveCrop(CropModel crop, {List<File>? newImages}) async {
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
        await _uploadImagesForCrop(newCrop.id, newImages);
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
      
      // Subir nuevas imágenes (en una implementación completa habría que manejar borrado y edición)
      if (newImages != null && newImages.isNotEmpty) {
        await _uploadImagesForCrop(updatedCrop.id, newImages);
      }
      return updatedCrop;
    }
  }

  /// Actualiza solo el estado de la cosecha
  Future<void> updateCropStatus(String cropId, CropStatus status) async {
    await _supabase.from('crops').update({
      'status': status.toShortString(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', cropId);
  }

  /// Elimina una cosecha
  Future<void> deleteCrop(String cropId) async {
    // Primero borramos las referencias a las imágenes en la BD
    await _supabase.from('crop_images').delete().eq('crop_id', cropId);
    // Luego borramos la cosecha
    await _supabase.from('crops').delete().eq('id', cropId);
  }

  /// Sube las imágenes al bucket y guarda los registros en crop_images
  Future<void> _uploadImagesForCrop(String cropId, List<File> images) async {
    for (int i = 0; i < images.length; i++) {
      final file = images[i];
      final extension = file.path.split('.').last.toLowerCase();
      final ext = ['jpg', 'jpeg', 'png'].contains(extension) ? extension : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
      final filePath = '$cropId/$fileName';

      // Asumimos que el bucket se llama 'product_images'
      await _supabase.storage.from('product_images').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Guardar el registro en la tabla crop_images
      await _supabase.from('crop_images').insert({
        'crop_id': cropId,
        'image_path': filePath,
        'is_primary': i == 0, // La primera imagen es la principal
      });
    }
  }

  /// Obtiene la URL pública de una imagen
  String getPublicImageUrl(String imagePath) {
    return _supabase.storage.from('product_images').getPublicUrl(imagePath);
  }
}
