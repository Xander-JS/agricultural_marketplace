// ignore_for_file: prefer_initializing_formals
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/user_roles.dart';
import '../../../../core/utils/diagnostic_utils.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../geo/services/geo_simulation_service.dart';
import '../../verificacion/services/document_submission_service.dart';

/// Fallos controlados al completar el registro de una cuenta de Auth que aún
/// no tiene perfil. La UI los traduce a mensajes sin exponer detalles internos.
enum AccountCompletionFailure {
  unauthenticated,
  invalidData,
  profile,
  documents,
  inProgress,
  unknown,
}

class AccountCompletionResult {
  final bool isSuccess;
  final bool documentsUploaded;
  final AccountCompletionFailure? failure;

  /// Detalle sanitizado para depuración. Nunca debe mostrarse al usuario.
  final String? debugReason;

  const AccountCompletionResult._({
    required this.isSuccess,
    this.documentsUploaded = false,
    this.failure,
    this.debugReason,
  });

  factory AccountCompletionResult.success({bool documentsUploaded = true}) =>
      AccountCompletionResult._(
        isSuccess: true,
        documentsUploaded: documentsUploaded,
      );

  factory AccountCompletionResult.failure(
    AccountCompletionFailure failure, {
    String? debugReason,
  }) => AccountCompletionResult._(
    isSuccess: false,
    failure: failure,
    debugReason: debugReason,
  );
}

typedef CompletionUserIdProvider = String? Function();
typedef CompletionProfileLookup = Future<Map<String, dynamic>?> Function(
  String userId,
);
typedef CompletionProfileInserter = Future<void> Function(
  Map<String, dynamic> profileData,
);

/// Completa el registro de una cuenta que ya existe en Supabase Auth pero no
/// tiene fila en `public.profiles`.
///
/// Seguridad:
/// - Usa exclusivamente el `auth.uid()` de la sesión activa; nunca acepta un id
///   de perfil arbitrario.
/// - Inserta el perfil con `verification_status = 'pendiente'` y un rol válido.
///   Los triggers y RLS existentes siguen siendo la última línea de defensa.
/// - Nunca reutiliza datos o documentos que no estén disponibles. El usuario
///   debe proporcionar y confirmar su información y sus tres documentos.
/// - La aprobación sigue siendo exclusivamente manual por un moderador.
class AccountCompletionService {
  final SupabaseClient? _clientOverride;
  final DocumentSubmissionService? _documentSubmissionService;
  final CompletionUserIdProvider? _userIdFetcher;
  final CompletionProfileLookup? _profileFetcher;
  final CompletionProfileInserter? _profileInserter;

  AccountCompletionService({
    SupabaseClient? client,
    DocumentSubmissionService? documentSubmissionService,
    CompletionUserIdProvider? userIdFetcher,
    CompletionProfileLookup? profileFetcher,
    CompletionProfileInserter? profileInserter,
  }) : _clientOverride = client,
       _documentSubmissionService = documentSubmissionService,
       _userIdFetcher = userIdFetcher,
       _profileFetcher = profileFetcher,
       _profileInserter = profileInserter;

  SupabaseClient? get _client {
    final override = _clientOverride;
    if (override != null) return override;
    try {
      return Supabase.instance.isInitialized ? Supabase.instance.client : null;
    } catch (_) {
      return null;
    }
  }

  String? get _userId {
    final fetcher = _userIdFetcher;
    if (fetcher != null) return fetcher();
    return _client?.auth.currentUser?.id;
  }

  DocumentSubmissionService get _documents =>
      _documentSubmissionService ?? DocumentSubmissionService(client: _client);

  Future<AccountCompletionResult> completeRegistration({
    required String contact,
    required String fullName,
    required String role,
    required File? documentFront,
    required File? documentBack,
    required File? selfie,
    String? department,
    String? municipality,
    double? latitude,
    double? longitude,
  }) async {
    final cleanContact = contact.trim().replaceAll(RegExp(r'[\s\-()]+'), '');
    final cleanName = fullName.trim();
    final normalizedRole = role.trim().toLowerCase();

    if (cleanContact.isEmpty || cleanName.isEmpty) {
      return AccountCompletionResult.failure(
        AccountCompletionFailure.invalidData,
      );
    }

    final isEmail = cleanContact.contains('@');
    if (!isEmail && cleanContact.length < 7) {
      return AccountCompletionResult.failure(
        AccountCompletionFailure.invalidData,
      );
    }

    if (normalizedRole != 'agricultor' && normalizedRole != 'comprador') {
      return AccountCompletionResult.failure(
        AccountCompletionFailure.invalidData,
      );
    }

    if (documentFront == null || documentBack == null || selfie == null) {
      return AccountCompletionResult.failure(
        AccountCompletionFailure.invalidData,
      );
    }

    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      return AccountCompletionResult.failure(
        AccountCompletionFailure.unauthenticated,
      );
    }

    final Map<String, dynamic>? existingProfile;
    try {
      existingProfile = await _loadProfile(userId);
    } catch (error) {
      final reason = describeException(
        error,
        stage: 'profile_lookup',
        redact: [userId],
      );
      logAuthDiagnostic('account_completion', reason);
      return AccountCompletionResult.failure(
        AccountCompletionFailure.profile,
        debugReason: reason,
      );
    }

    if (existingProfile == null) {
      final simLocation = GeoSimulationService.assignSimulatedLocation(
        seed: userId,
        municipality: municipality,
        department: department,
      );

      final finalDepartment = department?.trim().isNotEmpty == true
          ? department!.trim()
          : simLocation.department;
      final finalMunicipality = municipality?.trim().isNotEmpty == true
          ? municipality!.trim()
          : simLocation.municipality;
      final finalLatitude = GeoUtils.isValidCoordinate(latitude, longitude)
          ? latitude!
          : simLocation.latitude;
      final finalLongitude = GeoUtils.isValidCoordinate(latitude, longitude)
          ? longitude!
          : simLocation.longitude;

      final profileData = <String, dynamic>{
        'id': userId,
        'phone': cleanContact,
        'full_name': cleanName,
        'role': UserRole.toDb(normalizedRole),
        'verification_status': 'pendiente',
        if (isEmail) 'email': cleanContact,
        'department': finalDepartment,
        'municipality': finalMunicipality,
        'latitude': finalLatitude,
        'longitude': finalLongitude,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        final inserter = _profileInserter;
        if (inserter != null) {
          await inserter(profileData);
        } else {
          final client = _client;
          if (client == null) {
            return AccountCompletionResult.failure(
              AccountCompletionFailure.profile,
              debugReason: 'stage=profile_insert; reason=no_supabase_client',
            );
          }
          await client.from('profiles').insert(profileData);
        }
      } catch (error) {
        // Carrera con otro intento: la PK de profiles impide duplicados. Si la
        // fila ya existe, continuamos con los documentos.
        if (!_isDuplicateProfileError(error)) {
          final reason = describeException(
            error,
            stage: 'profile_insert',
            redact: [userId, cleanContact],
          );
          logAuthDiagnostic('account_completion', reason);
          return AccountCompletionResult.failure(
            AccountCompletionFailure.profile,
            debugReason: reason,
          );
        }
      }
    } else {
      final status = existingProfile['verification_status'] as String?;
      if (status == 'aprobado' || status == 'suspendido') {
        return AccountCompletionResult.success(documentsUploaded: false);
      }
    }

    final documentsResult = await _documents.submitDocuments(
      documentFront: documentFront,
      documentBack: documentBack,
      selfie: selfie,
    );

    if (documentsResult.isSuccess) {
      return AccountCompletionResult.success();
    }

    switch (documentsResult.failure) {
      case DocumentSubmissionFailure.unauthorized:
        return AccountCompletionResult.failure(
          AccountCompletionFailure.unauthenticated,
          debugReason: documentsResult.debugReason,
        );
      case DocumentSubmissionFailure.inProgress:
        return AccountCompletionResult.failure(
          AccountCompletionFailure.inProgress,
          debugReason: documentsResult.debugReason,
        );
      case DocumentSubmissionFailure.storage:
      case DocumentSubmissionFailure.attempt:
        return AccountCompletionResult.failure(
          AccountCompletionFailure.documents,
          debugReason: documentsResult.debugReason,
        );
      case DocumentSubmissionFailure.pendingExists:
        // Ya existe una solicitud pendiente: el objetivo idempotente se cumplió.
        return AccountCompletionResult.success(documentsUploaded: false);
      case DocumentSubmissionFailure.missingDocuments:
      case DocumentSubmissionFailure.fileUnavailable:
        return AccountCompletionResult.failure(
          AccountCompletionFailure.invalidData,
          debugReason: documentsResult.debugReason,
        );
      case DocumentSubmissionFailure.unknown:
      case null:
        return AccountCompletionResult.failure(
          AccountCompletionFailure.unknown,
          debugReason: documentsResult.debugReason,
        );
    }
  }

  Future<Map<String, dynamic>?> _loadProfile(String userId) async {
    final fetcher = _profileFetcher;
    if (fetcher != null) return fetcher(userId);

    final client = _client;
    if (client == null) {
      throw StateError('No hay cliente de Supabase disponible.');
    }

    return client
        .from('profiles')
        .select('id, role, verification_status')
        .eq('id', userId)
        .maybeSingle();
  }

  bool _isDuplicateProfileError(Object error) {
    if (error is PostgrestException && error.code == '23505') return true;
    final description = error.toString().toLowerCase();
    return description.contains('23505') ||
        description.contains('duplicate key');
  }
}
