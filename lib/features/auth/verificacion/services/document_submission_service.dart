// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/diagnostic_utils.dart';
import '../../../../core/utils/document_upload_utils.dart';

/// Fallos controlados del envío documental. La UI traduce cada valor a un
/// mensaje localizado sin exponer rutas, archivos ni detalles sensibles.
enum DocumentSubmissionFailure {
  missingDocuments,
  fileUnavailable,
  unauthorized,
  storage,
  attempt,
  pendingExists,
  inProgress,
  unknown,
}

class DocumentSubmissionResult {
  final bool isSuccess;
  final DocumentSubmissionFailure? failure;

  /// Detalle sanitizado para depuración. Nunca debe mostrarse al usuario.
  final String? debugReason;

  const DocumentSubmissionResult._({
    required this.isSuccess,
    this.failure,
    this.debugReason,
  });

  factory DocumentSubmissionResult.success() =>
      const DocumentSubmissionResult._(isSuccess: true);

  factory DocumentSubmissionResult.failure(
    DocumentSubmissionFailure failure, {
    String? debugReason,
  }) => DocumentSubmissionResult._(
    isSuccess: false,
    failure: failure,
    debugReason: debugReason,
  );
}

typedef DocumentStorageUploader = Future<void> Function(
  String bucket,
  String path,
  File file,
);

typedef DocumentStorageRemover = Future<void> Function(
  String bucket,
  List<String> paths,
);

typedef VerificationAttemptInserter = Future<void> Function(
  Map<String, dynamic> attemptData,
);

typedef PendingVerificationAttemptFetcher =
    Future<Map<String, dynamic>?> Function(String userId);

/// Guarda las tres imágenes de verificación en el bucket privado existente
/// `user_documents` y registra una nueva solicitud en `verification_attempts`.
///
/// No modifica el estado del perfil ni aprueba automáticamente al usuario. La
/// decisión sigue siendo exclusivamente manual por parte de un moderador.
class DocumentSubmissionService {
  static const String bucket = 'user_documents';

  final SupabaseClient? _clientOverride;
  final DocumentStorageUploader? _uploader;
  final DocumentStorageRemover? _remover;
  final VerificationAttemptInserter? _attemptInserter;
  final PendingVerificationAttemptFetcher? _pendingAttemptFetcher;
  final String? Function()? _userIdFetcher;
  final DateTime Function()? _now;
  final UploadRetryPolicy _retryPolicy;

  bool _isSubmitting = false;

  DocumentSubmissionService({
    SupabaseClient? client,
    DocumentStorageUploader? uploader,
    DocumentStorageRemover? remover,
    VerificationAttemptInserter? attemptInserter,
    PendingVerificationAttemptFetcher? pendingAttemptFetcher,
    String? Function()? userIdFetcher,
    DateTime Function()? now,
    UploadRetryPolicy uploadRetryPolicy = UploadRetryPolicy.standard,
  }) : _clientOverride = client,
       _uploader = uploader,
       _remover = remover,
       _attemptInserter = attemptInserter,
       _pendingAttemptFetcher = pendingAttemptFetcher,
       _userIdFetcher = userIdFetcher,
       _now = now,
       _retryPolicy = uploadRetryPolicy;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
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

  /// Envía las tres imágenes. Si una carga falla, no se inserta la solicitud y
  /// solo se intenta limpiar como máximo los archivos recién subidos en este
  /// intento; nunca se eliminan documentos previos del usuario.
  Future<DocumentSubmissionResult> submitDocuments({
    required File? documentFront,
    required File? documentBack,
    required File? selfie,
  }) async {
    if (_isSubmitting) {
      return _failure(
        DocumentSubmissionFailure.inProgress,
        'stage=submit; reason=already_in_progress',
      );
    }

    if (documentFront == null || documentBack == null || selfie == null) {
      return _failure(
        DocumentSubmissionFailure.missingDocuments,
        'stage=validation; reason=missing_documents',
      );
    }

    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      return _failure(
        DocumentSubmissionFailure.unauthorized,
        'stage=session; reason=no_authenticated_user',
      );
    }

    final client = _client;
    if (client == null && _uploader == null) {
      return _failure(
        DocumentSubmissionFailure.storage,
        'stage=client; reason=no_supabase_client',
      );
    }

    // Cuando se usa la sesión real (no dependencias inyectadas), se verifica
    // que exista una sesión activa y que su identidad coincida con la carpeta
    // donde se escribirán los documentos. Un `currentUser` sin sesión o una
    // identidad distinta provoca 403/400 en Storage y es la causa habitual de
    // fallos de carga posteriores a un registro.
    if (_userIdFetcher == null && client != null) {
      final sessionUserId = client.auth.currentSession?.user.id;
      if (sessionUserId == null) {
        return _failure(
          DocumentSubmissionFailure.unauthorized,
          'stage=session; reason=no_active_session',
        );
      }
      if (sessionUserId != userId) {
        return _failure(
          DocumentSubmissionFailure.unauthorized,
          'stage=session; reason=session_user_mismatch',
        );
      }
    }

    _isSubmitting = true;
    final uploadedPaths = <String>[];

    try {
      // Idempotencia: si ya existe una solicitud pendiente completa (por ejemplo,
      // el usuario reintentó tras perder la respuesta de red), no se vuelven a
      // subir archivos ni se intenta insertar un duplicado.
      final pendingAttempt = await _findPendingAttempt(userId);
      if (pendingAttempt != null) {
        if (_hasAllDocumentPaths(pendingAttempt)) {
          return DocumentSubmissionResult.success();
        }
        return _failure(
          DocumentSubmissionFailure.pendingExists,
          'stage=pending_lookup; reason=pending_attempt_incomplete',
        );
      }

      final files = [documentFront, documentBack, selfie];
      // Con el almacenamiento real los bytes se leen antes de cualquier carga:
      // así se detecta un archivo perdido sin dejar cargas parciales y la
      // subida no depende de que el archivo siga existiendo durante la red.
      final fileBytes = <Uint8List?>[];
      for (final file in files) {
        try {
          if (!file.existsSync() || file.lengthSync() <= 0) {
            await _cleanupNewUploads(uploadedPaths);
            return _failure(
              DocumentSubmissionFailure.fileUnavailable,
              'stage=file_validation; reason=file_missing_or_empty',
            );
          }
          fileBytes.add(_uploader == null ? await file.readAsBytes() : null);
        } on FileSystemException catch (error) {
          await _cleanupNewUploads(uploadedPaths);
          return _failure(
            DocumentSubmissionFailure.fileUnavailable,
            describeException(
              error,
              stage: 'file_validation',
              redact: [userId],
            ),
          );
        }
      }

      final milliseconds = (_now ?? DateTime.now)().millisecondsSinceEpoch;
      final paths = <String>[
        '$userId/front_$milliseconds.${documentFileExtension(documentFront.path)}',
        '$userId/back_$milliseconds.${documentFileExtension(documentBack.path)}',
        '$userId/selfie_$milliseconds.${documentFileExtension(selfie.path)}',
      ];

      final uploader = _uploader;
      const stages = ['upload_front', 'upload_back', 'upload_selfie'];
      try {
        for (var i = 0; i < paths.length; i++) {
          final path = paths[i];
          final file = files[i];
          await uploadWithRetry(() async {
            if (uploader != null) {
              await uploader(bucket, path, file);
            } else {
              await client!.storage
                  .from(bucket)
                  .uploadBinary(
                    path,
                    fileBytes[i]!,
                    fileOptions: documentUploadFileOptions(file.path),
                  );
            }
          }, policy: _retryPolicy);
          uploadedPaths.add(path);
        }
      } catch (error) {
        await _cleanupNewUploads(uploadedPaths);
        final stage = uploadedPaths.length < stages.length
            ? stages[uploadedPaths.length]
            : 'upload';
        return _failure(
          DocumentSubmissionFailure.storage,
          describeException(error, stage: stage, redact: [userId]),
        );
      }

      final attemptData = <String, dynamic>{
        'user_id': userId,
        'status': 'pendiente',
        'document_front_path': paths[0],
        'document_back_path': paths[1],
        'selfie_path': paths[2],
      };

      final attemptInserter = _attemptInserter;
      try {
        if (attemptInserter != null) {
          await attemptInserter(attemptData);
        } else {
          await client!.from('verification_attempts').insert(attemptData);
        }
      } on PostgrestException catch (error) {
        await _cleanupNewUploads(uploadedPaths);
        if (error.code == '23505') {
          return _failure(
            DocumentSubmissionFailure.pendingExists,
            describeException(error, stage: 'attempt_insert', redact: [userId]),
          );
        }
        return _failure(
          DocumentSubmissionFailure.attempt,
          describeException(error, stage: 'attempt_insert', redact: [userId]),
        );
      } catch (error) {
        await _cleanupNewUploads(uploadedPaths);
        return _failure(
          DocumentSubmissionFailure.attempt,
          describeException(error, stage: 'attempt_insert', redact: [userId]),
        );
      }

      return DocumentSubmissionResult.success();
    } catch (error) {
      await _cleanupNewUploads(uploadedPaths);
      return _failure(
        DocumentSubmissionFailure.unknown,
        describeException(error, stage: 'submit', redact: [userId]),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  DocumentSubmissionResult _failure(
    DocumentSubmissionFailure failure,
    String? debugReason,
  ) {
    final reason = debugReason == null ? null : sanitizeDiagnostic(debugReason);
    if (reason != null) {
      logAuthDiagnostic('documents', reason);
    }
    return DocumentSubmissionResult.failure(failure, debugReason: reason);
  }

  /// Consulta de mejor esfuerzo. Si falla, se continúa con la subida y el
  /// índice único de la base de datos sigue evitando solicitudes duplicadas.
  Future<Map<String, dynamic>?> _findPendingAttempt(String userId) async {
    final fetcher = _pendingAttemptFetcher;
    if (fetcher != null) return fetcher(userId);

    // En pruebas con dependencias inyectadas no se debe tocar la red.
    if (_uploader != null || _attemptInserter != null) return null;

    final client = _client;
    if (client == null) return null;

    try {
      return await client
          .from('verification_attempts')
          .select(
            'status, document_front_path, document_back_path, selfie_path',
          )
          .eq('user_id', userId)
          .inFilter('status', ['pendiente', 'en_revision_ia'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (error) {
      logAuthDiagnostic(
        'documents',
        describeException(error, stage: 'pending_lookup', redact: [userId]),
      );
      return null;
    }
  }

  bool _hasAllDocumentPaths(Map<String, dynamic> attempt) {
    return [
      attempt['document_front_path'],
      attempt['document_back_path'],
      attempt['selfie_path'],
    ].every((path) => path is String && path.trim().isNotEmpty);
  }

  Future<void> _cleanupNewUploads(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      final remover = _remover;
      if (remover != null) {
        await remover(bucket, List<String>.unmodifiable(paths));
        return;
      }
      final client = _client;
      if (client != null) {
        await client.storage.from(bucket).remove(paths);
      }
    } catch (_) {
      // Limpieza de mejor esfuerzo. No se debe exponer ni registrar la ruta.
    }
  }
}
