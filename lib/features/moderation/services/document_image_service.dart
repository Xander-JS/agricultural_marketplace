// ignore_for_file: prefer_initializing_formals
import 'package:supabase_flutter/supabase_flutter.dart';

import 'document_diagnosis_service.dart';

class DocumentImageUrlResult {
  final String? url;
  final bool isSuccess;

  const DocumentImageUrlResult._({required this.isSuccess, this.url});

  factory DocumentImageUrlResult.success(String url) =>
      DocumentImageUrlResult._(isSuccess: true, url: url);

  factory DocumentImageUrlResult.failure() =>
      const DocumentImageUrlResult._(isSuccess: false);
}

typedef SignedDocumentUrlSigner = Future<String> Function(
  String bucket,
  String path,
  int expiresInSeconds,
);

/// Obtiene URLs firmadas temporales para documentos privados del bucket
/// `user_documents`. No convierte los documentos en públicos ni registra rutas.
class DocumentImageUrlService {
  static const String defaultBucket = 'user_documents';
  static const int defaultExpirationSeconds = 600;

  final SupabaseClient? _clientOverride;
  final SignedDocumentUrlSigner? _signer;
  final String bucket;
  final int expirationSeconds;

  DocumentImageUrlService({
    SupabaseClient? client,
    SignedDocumentUrlSigner? signer,
    this.bucket = defaultBucket,
    this.expirationSeconds = defaultExpirationSeconds,
  }) : _clientOverride = client,
       _signer = signer;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.isInitialized ? Supabase.instance.client : null;
    } catch (_) {
      return null;
    }
  }

  Future<DocumentImageUrlResult> createSignedUrl(String? path) async {
    if (!DocumentPathValidator.isValid(path)) {
      return DocumentImageUrlResult.failure();
    }

    final signer = _signer;
    if (signer != null) {
      try {
        final url = await signer(bucket, path!.trim(), expirationSeconds);
        if (url.trim().isEmpty) return DocumentImageUrlResult.failure();
        return DocumentImageUrlResult.success(url);
      } catch (_) {
        return DocumentImageUrlResult.failure();
      }
    }

    final client = _client;
    if (client == null) return DocumentImageUrlResult.failure();

    try {
      final url = await client.storage
          .from(bucket)
          .createSignedUrl(path!.trim(), expirationSeconds);
      if (url.trim().isEmpty) return DocumentImageUrlResult.failure();
      return DocumentImageUrlResult.success(url);
    } catch (_) {
      return DocumentImageUrlResult.failure();
    }
  }
}
