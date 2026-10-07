import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/farmer_profile_data.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<FarmerProfileData> getFarmerProfileData(String userId) async {
    // 1. Obtener datos del perfil
    final profileResponse = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    // 2. Obtener configuraciones del granjero
    Map<String, dynamic> settingsMap = {};
    try {
      final settingsResponse = await _supabase
          .from('farmer_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (settingsResponse != null) {
        settingsMap = settingsResponse;
      } else {
        // Si no existen, se crean por defecto
        final newSettings = {
          'user_id': userId,
          'enable_early_sale': false,
          'share_phone': false,
          'share_location': false,
          'share_whatsapp': false,
        };
        await _supabase.from('farmer_settings').insert(newSettings);
        settingsMap = newSettings;
      }
    } catch (e) {
      // Ignorar error y usar valores por defecto si falla
      settingsMap = {
        'user_id': userId,
        'enable_early_sale': false,
        'share_phone': false,
        'share_location': false,
        'share_whatsapp': false,
      };
    }

    // 3. Obtener estadísticas
    // a. Publicados (Cultivos creados por este agricultor que no estén en borrador)
    final cropsResponse = await _supabase
        .from('crops')
        .select('id, status')
        .eq('farmer_id', userId)
        .neq('status', 'borrador');
    
    final publishedCount = cropsResponse.length;

    // b. Negociando y Cerradas
    // Buscamos negociaciones que estén vinculadas a los cultivos de este granjero
    final negotiationsResponse = await _supabase
        .from('negotiations')
        .select('id, status, crops!inner(farmer_id)')
        .eq('crops.farmer_id', userId);

    int negotiatingCount = 0;
    int closedCount = 0;

    for (var neg in negotiationsResponse) {
      final status = neg['status'] as String?;
      if (status == 'completada' || status == 'cancelada' || status == 'rechazada') {
        closedCount++;
      } else {
        // Asumimos que cualquier otro estado (propuesta, aceptada, etc.) es 'negociando'
        negotiatingCount++;
      }
    }

    final stats = FarmerStatsData(
      published: publishedCount,
      negotiating: negotiatingCount,
      closed: closedCount,
    );

    return FarmerProfileData.fromMap(
      profileMap: profileResponse,
      settingsMap: settingsMap,
      stats: stats,
    );
  }

  Future<void> updateProfileData(String userId, {String? email, String? phone}) async {
    final Map<String, dynamic> updates = {};
    if (email != null && email.isNotEmpty) updates['email'] = email;
    if (phone != null && phone.isNotEmpty) updates['phone'] = phone;

    if (updates.isNotEmpty) {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<void> updateFarmerSettings(String userId, FarmerSettingsData settings) async {
    final data = settings.toMap();
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('farmer_settings').upsert(data);
  }

  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    final extension = imageFile.path.split('.').last.toLowerCase();
    // Validar extensión simple para evitar problemas
    final ext = ['jpg', 'jpeg', 'png'].contains(extension) ? extension : 'jpg';
    final filePath = '$userId/avatar.$ext';

    // Subir imagen. Usamos upsert para sobreescribir la anterior y no dejar basura
    await _supabase.storage.from('profiles').upload(
      filePath,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    // Obtener ruta (en Supabase suele guardarse el path o la URL pública, el requerimiento dice guardar el profile_path)
    // El requerimiento dice: "Guardar en profiles.profile_path la ruta correspondiente de la imagen."
    // Generalmente guardamos solo el nombre del path o la URL completa.
    // Usaremos el path para poder obtener la url pública luego.
    await _supabase.from('profiles').update({'profile_path': filePath}).eq('id', userId);

    return filePath;
  }

  String getPublicProfileImageUrl(String profilePath) {
    // Agregamos un timestamp para el cache busting
    final url = _supabase.storage.from('profiles').getPublicUrl(profilePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$url?t=$timestamp';
  }
}
