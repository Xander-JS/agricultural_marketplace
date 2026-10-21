// ignore_for_file: prefer_initializing_formals
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  const DocumentSubmissionResult._({required this.isSuccess, this.failure});

  factory DocumentSubmissionResult.success() =>
      const DocumentSubmissionResult._(isSuccess: true);

  factory DocumentSubmissionResult.failure(DocumentSubmissionFailure failure) =>
      DocumentSubmissionResult._(isSuccess: false, failure: failure);
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
  final String? Function()? _userIdFetcher;
  final DateTime Function()? _now;

  bool _isSubmitting = false;

  DocumentSubmissionService({
    SupabaseClient? client,
    DocumentStorageUploader? uploader,
    DocumentStorageRemover? remover,
    VerificationAttemptInserter? attemptInserter,
    String? Function()? userIdFetcher,
    DateTime Function()? now,
  }) : _clientOverride = client,
       _uploader = uploader,
       _remover = remover,
       _attemptInserter = attemptInserter,
       _userIdFetcher = userIdFetcher,
       _now = now;

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
      return DocumentSubmissionResult.failure(
        DocumentSubmissionFailure.inProgress,
      );
    }

    if (documentFront == null || documentBack == null || selfie == null) {
      return DocumentSubmissionResult.failure(
        DocumentSubmissionFailure.missingDocuments,
      );
    }

    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      return DocumentSubmissionResult.failure(
        DocumentSubmissionFailure.unauthorized,
      );
    }

    final client = _client;
    if (client == null && _uploader == null) {
      return DocumentSubmissionResult.failure(
        DocumentSubmissionFailure.storage,
      );
    }

    _isSubmitting = true;
    final uploadedPaths = <String>[];

    try {
      for (final file in [documentFront, documentBack, selfie]) {
        if (!file.existsSync()) {
          await _cleanupNewUploads(uploadedPaths);
          return DocumentSubmissionResult.failure(
            DocumentSubmissionFailure.fileUnavailable,
          );
        }
      }

      final milliseconds = (_now ?? DateTime.now)().millisecondsSinceEpoch;
      final paths = <String>[
        '$userId/front_$milliseconds.jpg',
        '$userId/back_$milliseconds.jpg',
        '$userId/selfie_$milliseconds.jpg',
      ];

      final uploader = _uploader;
      try {
        for (var i = 0; i < paths.length; i++) {
          final path = paths[i];
          final file = [documentFront, documentBack, selfie][i];
          if (uploader != null) {
            await uploader(bucket, path, file);
          } else {
            await client!.storage.from(bucket).upload(path, file);
          }
          uploadedPaths.add(path);
        }
      } catch (_) {
        await _cleanupNewUploads(uploadedPaths);
        return DocumentSubmissionResult.failure(
          DocumentSubmissionFailure.storage,
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
      } on PostgrestException catch (e) {
        await _cleanupNewUploads(uploadedPaths);
        if (e.code == '23505') {
          return DocumentSubmissionResult.failure(
            DocumentSubmissionFailure.pendingExists,
          );
        }
        return DocumentSubmissionResult.failure(
          DocumentSubmissionFailure.attempt,
        );
      } catch (_) {
        await _cleanupNewUploads(uploadedPaths);
        return DocumentSubmissionResult.failure(
          DocumentSubmissionFailure.attempt,
        );
      }

      return DocumentSubmissionResult.success();
    } catch (_) {
      await _cleanupNewUploads(uploadedPaths);
      return DocumentSubmissionResult.failure(
        DocumentSubmissionFailure.unknown,
      );
    } finally {
      _isSubmitting = false;
    }
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
