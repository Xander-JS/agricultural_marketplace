import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:agricultural_marketplace/core/utils/document_upload_utils.dart';

void main() {
  final waits = <Duration>[];
  final policy = UploadRetryPolicy(
    maxAttempts: 3,
    initialDelay: const Duration(milliseconds: 100),
    wait: (delay) async => waits.add(delay),
  );

  setUp(waits.clear);

  group('uploadWithRetry', () {
    test('reintenta fallos de red con espera exponencial', () async {
      var calls = 0;
      await uploadWithRetry(() async {
        calls++;
        if (calls < 3) throw const SocketException('Connection reset');
      }, policy: policy);

      expect(calls, 3);
      expect(waits, [
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 200),
      ]);
    });

    test(
      'reintenta 5xx de Storage y se rinde al agotar los intentos',
      () async {
        var calls = 0;
        await expectLater(
          uploadWithRetry(() async {
            calls++;
            throw const StorageException('Bad gateway', statusCode: '502');
          }, policy: policy),
          throwsA(isA<StorageException>()),
        );
        expect(calls, 3);
      },
    );

    test('no reintenta errores definitivos (permisos, bucket)', () async {
      var calls = 0;
      await expectLater(
        uploadWithRetry(() async {
          calls++;
          throw const StorageException(
            'new row violates row-level security policy',
            statusCode: '403',
          );
        }, policy: policy),
        throwsA(isA<StorageException>()),
      );
      expect(calls, 1);
      expect(waits, isEmpty);
    });

    test('un 409 tras un corte de red cuenta como carga completada', () async {
      var calls = 0;
      await uploadWithRetry(() async {
        calls++;
        if (calls == 1) throw const SocketException('Connection closed');
        throw const StorageException(
          'The resource already exists',
          statusCode: '409',
        );
      }, policy: policy);
      expect(calls, 2);
    });

    test('un 409 en el primer intento sí es un error', () async {
      await expectLater(
        uploadWithRetry(() async {
          throw const StorageException(
            'The resource already exists',
            statusCode: '409',
          );
        }, policy: policy),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
