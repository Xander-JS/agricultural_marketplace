import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../geo/services/geo_simulation_service.dart';
import '../models/farmer_profile_data.dart';

class ProfileService {
  final SupabaseClient _supabase;

  static final ValueNotifier<String?> currentProfilePathNotifier = ValueNotifier<String?>(null);
  ValueNotifier<String?> get profilePathNotifier => currentProfilePathNotifier;

  ProfileService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  Future<String?> getProfilePath(String userId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('profile_path')
          .eq('id', userId)
          .maybeSingle();
      final path = res?['profile_path'] as String?;
      if (_supabase.auth.currentUser?.id == userId) {
        currentProfilePathNotifier.value = path;
      }
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<FarmerProfileData> getFarmerProfileData(String userId) async {
    // 1. Obtener datos del perfil (usando RPC segura get_my_profile para perfil propio)
    final currentUid = _supabase.auth.currentUser?.id;
    Map<String, dynamic> rawProfile;
    if (userId == currentUid) {
      try {
        final myProfileRes = await _supabase.rpc('get_my_profile');
        rawProfile = myProfileRes is Map<String, dynamic>
            ? myProfileRes
            : Map<String, dynamic>.from(myProfileRes as Map);
      } catch (_) {
        final profileResponse = await _supabase
            .from('profiles')
            .select('id, full_name, role, verification_status, profile_path, department, municipality')
            .eq('id', userId)
            .single();
        rawProfile = Map<String, dynamic>.from(profileResponse);
      }
    } else {
      final profileResponse = await _supabase
          .from('profiles')
          .select('id, full_name, role, verification_status, profile_path, department, municipality')
          .eq('id', userId)
          .single();
      rawProfile = Map<String, dynamic>.from(profileResponse);
    }
    final profilePath = rawProfile['profile_path'] as String?;
    if (_supabase.auth.currentUser?.id == userId) {
      currentProfilePathNotifier.value = profilePath;
    }
    final rawLat = (rawProfile['latitude'] as num?)?.toDouble();
    final rawLon = (rawProfile['longitude'] as num?)?.toDouble();

    // Si no existen coordenadas persistidas en la BD, proveer ubicación simulada estable por semilla
    if (rawLat == null || rawLon == null) {
      final fallback = GeoSimulationService.getFallbackUserLocation(
        userId,
        municipality: rawProfile['municipality'] as String?,
        department: rawProfile['department'] as String?,
      );
      rawProfile['department'] = (rawProfile['department'] as String?)?.isNotEmpty == true
          ? rawProfile['department']
          : fallback.department;
      rawProfile['municipality'] = (rawProfile['municipality'] as String?)?.isNotEmpty == true
          ? rawProfile['municipality']
          : fallback.municipality;
      rawProfile['latitude'] = fallback.latitude;
      rawProfile['longitude'] = fallback.longitude;
    }

    final role = (rawProfile['role'] as String? ?? 'agricultor').trim().toLowerCase();
    final isBuyer = role == 'comprador' || role == 'comerciante';

    // 2. Obtener configuraciones: solo consultar o insertar farmer_settings si es agricultor
    Map<String, dynamic> settingsMap = {};
    if (!isBuyer) {
      try {
        final settingsResponse = await _supabase
            .from('farmer_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (settingsResponse != null) {
          settingsMap = settingsResponse;
        } else {
          // Si no existen, se crean por defecto para el agricultor
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
    } else {
      // Para comerciante no se persiste en farmer_settings
      settingsMap = {
        'user_id': userId,
        'enable_early_sale': false,
        'share_phone': false,
        'share_location': false,
        'share_whatsapp': false,
      };
    }

    // 3. Obtener estadísticas según el rol
    int publishedCount = 0;
    int negotiatingCount = 0;
    int closedCount = 0;

    if (!isBuyer) {
      // Estadísticas del Agricultor
      // a. Publicados (Cultivos creados por este agricultor que no estén en borrador)
      final cropsResponse = await _supabase
          .from('crops')
          .select('id, status')
          .eq('farmer_id', userId)
          .neq('status', 'borrador');
      
      publishedCount = cropsResponse.length;

      // b. Negociando y Cerradas
      // Negociaciones vinculadas a los cultivos de este agricultor
      final negotiationsResponse = await _supabase
          .from('negotiations')
          .select('id, status, crops!inner(farmer_id)')
          .eq('crops.farmer_id', userId);

      for (var neg in negotiationsResponse) {
        final status = neg['status'] as String?;
        if (status == 'completada' || status == 'cancelada' || status == 'rechazada') {
          closedCount++;
        } else {
          negotiatingCount++;
        }
      }
    } else {
      // Estadísticas del Comerciante
      // Consultar negociaciones donde el usuario es el comprador (buyer_id)
      final buyerNegotiations = await _supabase
          .from('negotiations')
          .select('id, status')
          .eq('buyer_id', userId);

      for (var neg in buyerNegotiations) {
        final status = (neg['status'] as String? ?? '').toLowerCase();
        if (status == 'completada') {
          closedCount++;
        } else if (status != 'cancelada' && status != 'rechazada') {
          // Negociaciones en curso (propuesta, contraofertada, acordada)
          negotiatingCount++;
        }
      }
    }

    final stats = FarmerStatsData(
      published: publishedCount,
      negotiating: negotiatingCount,
      closed: closedCount,
    );

    return FarmerProfileData.fromMap(
      profileMap: rawProfile,
      settingsMap: settingsMap,
      stats: stats,
    );
  }

  Future<void> updateProfileData(
    String userId, {
    String? email,
    String? phone,
    String? department,
    String? municipality,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> updates = {};
    if (email != null && email.isNotEmpty) updates['email'] = email;
    if (phone != null && phone.isNotEmpty) updates['phone'] = phone;
    if (department != null && department.isNotEmpty) updates['department'] = department;
    if (municipality != null && municipality.isNotEmpty) updates['municipality'] = municipality;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;

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

  Future<String> uploadProfilePicture(
    String userId,
    File imageFile, {
    String? oldProfilePath,
  }) async {
    final extension = imageFile.path.split('.').last.toLowerCase();
    // Validar extensión simple para evitar problemas
    final ext = ['jpg', 'jpeg', 'png'].contains(extension) ? extension : 'jpg';
    final filePath = '$userId/avatar.$ext';

    // Resolver ruta anterior si no fue provista explícitamente
    String? previousPath = oldProfilePath;
    if (previousPath == null) {
      try {
        final currentProfile = await _supabase
            .from('profiles')
            .select('profile_path')
            .eq('id', userId)
            .maybeSingle();
        previousPath = currentProfile?['profile_path'] as String?;
      } catch (_) {}
    }

    // 1. Subir nueva imagen a Storage primero (upsert para sobrescribir si coincide extensión)
    await _supabase.storage.from('profiles').upload(
      filePath,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    // 2. Confirmar actualización en la base de datos
    try {
      final updated = await _supabase
          .from('profiles')
          .update({
            'profile_path': filePath,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select('id, profile_path');

      if (updated.isEmpty) {
        throw Exception(
          'Error al actualizar perfil en base de datos: 0 filas modificadas.',
        );
      }
    } catch (e) {
      // En caso de fallo en BD, limpiar el archivo recién subido si era de distinta ruta para evitar huérfanos
      if (previousPath != filePath) {
        try {
          await _supabase.storage.from('profiles').remove([filePath]);
        } catch (_) {}
      }
      rethrow;
    }

    // 3. Solo tras confirmar éxito en BD, si la foto anterior tenía ruta diferente dentro de su carpeta,
    // eliminarla para no dejar archivos huérfanos
    if (previousPath != null &&
        previousPath != filePath &&
        previousPath.startsWith('$userId/') &&
        !previousPath.contains('..') &&
        !previousPath.startsWith('http://') &&
        !previousPath.startsWith('https://')) {
      try {
        await _supabase.storage.from('profiles').remove([previousPath]);
      } catch (_) {}
    }

    // 4. Actualizar versión en memoria para invalidar caché de forma segura y notificar
    _pathVersions[filePath] = DateTime.now().millisecondsSinceEpoch.toString();
    currentProfilePathNotifier.value = filePath;

    return filePath;
  }

  Future<void> deleteProfilePicture(String userId, String? profilePath) async {
    // Validar que la ruta pertenezca estrictamente a la carpeta del usuario y no contenga traversal
    final isAllowedPath = profilePath != null &&
        profilePath.isNotEmpty &&
        profilePath.startsWith('$userId/') &&
        !profilePath.contains('..') &&
        !profilePath.startsWith('http://') &&
        !profilePath.startsWith('https://');

    if (isAllowedPath) {
      try {
        await _supabase.storage.from('profiles').remove([profilePath]);
      } catch (_) {}
    }
    await _supabase.from('profiles').update({
      'profile_path': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    if (profilePath != null) {
      _pathVersions.remove(profilePath);
    }
    currentProfilePathNotifier.value = null;
  }

  static final Map<String, String> _pathVersions = {};

  void invalidateCache([String? profilePath]) {
    if (profilePath != null && profilePath.isNotEmpty) {
      _pathVersions[profilePath] = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  String getPublicProfileImageUrl(String profilePath) {
    if (profilePath.startsWith('http://') || profilePath.startsWith('https://')) {
      return profilePath;
    }
    // Generar o reutilizar un timestamp estable para cache busting
    final url = _supabase.storage.from('profiles').getPublicUrl(profilePath);
    final v = _pathVersions.putIfAbsent(
      profilePath,
      () => DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return '$url?t=$v';
  }
}
