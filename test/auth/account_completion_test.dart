import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/features/auth/registro/services/account_completion_service.dart';
import 'package:agricultural_marketplace/features/auth/verificacion/services/document_submission_service.dart';

void main() {
  late Directory tempDir;
  late File front;
  late File back;
  late File selfie;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('account_completion_');
    front = File('${tempDir.path}/front.jpg')..writeAsBytesSync([1]);
    back = File('${tempDir.path}/back.jpg')..writeAsBytesSync([2]);
    selfie = File('${tempDir.path}/selfie.jpg')..writeAsBytesSync([3]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DocumentSubmissionService documents({
    required List<String> uploads,
    required List<Map<String, dynamic>> attempts,
    Map<String, dynamic>? pendingAttempt,
    bool returnPendingAttempt = false,
  }) {
    return DocumentSubmissionService(
      userIdFetcher: () => 'existing-auth-user',
      uploader: (bucket, path, file) async => uploads.add(path),
      attemptInserter: (attemptData) async => attempts.add(attemptData),
      pendingAttemptFetcher: (userId) async =>
          returnPendingAttempt ? pendingAttempt : null,
    );
  }

  group('Recuperación de cuentas Auth sin perfil', () {
    test('1. Crea el perfil pendiente y registra la solicitud solo tras subir los tres documentos', () async {
      final uploads = <String>[];
      final attempts = <Map<String, dynamic>>[];
      Map<String, dynamic>? insertedProfile;

      final service = AccountCompletionService(
        userIdFetcher: () => 'existing-auth-user',
        profileFetcher: (userId) async => null,
        profileInserter: (profileData) async => insertedProfile = profileData,
        documentSubmissionService: documents(
          uploads: uploads,
          attempts: attempts,
        ),
      );

      final result = await service.completeRegistration(
        contact: '3151234567',
        fullName: 'Cuenta Recuperada',
        role: 'agricultor',
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isTrue);
      expect(result.documentsUploaded, isTrue);
      expect(insertedProfile, isNotNull);
      expect(insertedProfile!['id'], 'existing-auth-user');
      expect(insertedProfile!['role'], 'agricultor');
      expect(insertedProfile!['verification_status'], 'pendiente');
      expect(insertedProfile!['phone'], '3151234567');
      expect(uploads.length, 3);
      expect(attempts.length, 1);
      expect(attempts.single['user_id'], 'existing-auth-user');
      expect(attempts.single['status'], 'pendiente');
    });

    test('2. Una cuenta existente sin perfil no se vuelve a registrar ni duplica el perfil', () async {
      final uploads = <String>[];
      final attempts = <Map<String, dynamic>>[];
      var insertCalls = 0;

      final service = AccountCompletionService(
        userIdFetcher: () => 'existing-auth-user',
        profileFetcher: (userId) async => {
          'id': userId,
          'role': 'comprador',
          'verification_status': 'pendiente',
        },
        profileInserter: (_) async => insertCalls++,
        documentSubmissionService: documents(
          uploads: uploads,
          attempts: attempts,
        ),
      );

      final result = await service.completeRegistration(
        contact: 'cuenta@ejemplo.com',
        fullName: 'Cuenta Existente',
        role: 'comprador',
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isTrue);
      expect(insertCalls, 0);
      expect(uploads.length, 3);
      expect(attempts.length, 1);
    });

    test('3. El reintento con solicitud pendiente completa no vuelve a subir ni insertar', () async {
      final uploads = <String>[];
      final attempts = <Map<String, dynamic>>[];
      var insertCalls = 0;

      final service = AccountCompletionService(
        userIdFetcher: () => 'existing-auth-user',
        profileFetcher: (userId) async => {
          'id': userId,
          'role': 'agricultor',
          'verification_status': 'pendiente',
        },
        profileInserter: (_) async => insertCalls++,
        documentSubmissionService: documents(
          uploads: uploads,
          attempts: attempts,
          returnPendingAttempt: true,
          pendingAttempt: {
            'status': 'pendiente',
            'document_front_path': 'existing-auth-user/front_1.jpg',
            'document_back_path': 'existing-auth-user/back_1.jpg',
            'selfie_path': 'existing-auth-user/selfie_1.jpg',
          },
        ),
      );

      final result = await service.completeRegistration(
        contact: '3151234567',
        fullName: 'Cuenta Existente',
        role: 'agricultor',
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isTrue);
      expect(insertCalls, 0);
      expect(uploads, isEmpty);
      expect(attempts, isEmpty);
    });

    test('4. Sin los tres documentos no crea perfil ni solicitud', () async {
      final uploads = <String>[];
      final attempts = <Map<String, dynamic>>[];
      var insertCalls = 0;

      final service = AccountCompletionService(
        userIdFetcher: () => 'existing-auth-user',
        profileFetcher: (userId) async => null,
        profileInserter: (_) async => insertCalls++,
        documentSubmissionService: documents(
          uploads: uploads,
          attempts: attempts,
        ),
      );

      final result = await service.completeRegistration(
        contact: '3151234567',
        fullName: 'Cuenta Recuperada',
        role: 'agricultor',
        documentFront: front,
        documentBack: null,
        selfie: selfie,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, AccountCompletionFailure.invalidData);
      expect(insertCalls, 0);
      expect(uploads, isEmpty);
      expect(attempts, isEmpty);
    });

    test('5. Sin sesión activa no intenta escribir el perfil', () async {
      var insertCalls = 0;
      final service = AccountCompletionService(
        userIdFetcher: () => null,
        profileFetcher: (userId) async => null,
        profileInserter: (_) async => insertCalls++,
        documentSubmissionService: documents(uploads: [], attempts: []),
      );

      final result = await service.completeRegistration(
        contact: '3151234567',
        fullName: 'Cuenta Recuperada',
        role: 'agricultor',
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, AccountCompletionFailure.unauthenticated);
      expect(insertCalls, 0);
    });
    test('6. Un fallo de Storage se traduce a fallo de documentos con diagnóstico seguro', () async {
      final service = AccountCompletionService(
        userIdFetcher: () => 'existing-auth-user',
        profileFetcher: (userId) async => {
          'id': userId,
          'role': 'agricultor',
          'verification_status': 'pendiente',
        },
        profileInserter: (_) async {},
        documentSubmissionService: DocumentSubmissionService(
          userIdFetcher: () => 'existing-auth-user',
          uploader: (bucket, path, file) async {
            throw const StorageException(
              'Bucket not found for existing-auth-user/front_1.jpg',
              error: 'NoSuchBucket',
              statusCode: '400',
            );
          },
          attemptInserter: (_) async {},
        ),
      );

      final result = await service.completeRegistration(
        contact: '3151234567',
        fullName: 'Cuenta Existente',
        role: 'agricultor',
        documentFront: front,
        documentBack: back,
        selfie: selfie,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, AccountCompletionFailure.documents);
      expect(result.debugReason, contains('hint=storage_bucket_missing'));
      expect(result.debugReason, isNot(contains('existing-auth-user')));
      expect(result.debugReason, isNot(contains('front_1.jpg')));
    });
  });
}
