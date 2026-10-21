// ignore_for_file: prefer_initializing_formals
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado estructurado para operaciones de recuperación y cambio de contraseña.
class RecoveryResult {
  final bool success;
  final String message;
  final bool isNetworkError;
  final bool isValidationError;

  const RecoveryResult({
    required this.success,
    required this.message,
    this.isNetworkError = false,
    this.isValidationError = false,
  });

  factory RecoveryResult.success({required String message}) =>
      RecoveryResult(success: true, message: message);

  factory RecoveryResult.failure({
    required String message,
    bool isNetwork = false,
    bool isValidation = false,
  }) =>
      RecoveryResult(
        success: false,
        message: message,
        isNetworkError: isNetwork,
        isValidationError: isValidation,
      );
}

typedef PasswordResetInvoker = Future<void> Function(
  String email, {
  String? redirectTo,
});

typedef PasswordUpdateInvoker = Future<UserResponse> Function(
  UserAttributes attributes,
);

typedef SessionChecker = Session? Function();

/// Servicio para la recuperación y actualización de contraseña mediante Supabase Auth.
///
/// Diseñado con inyección de dependencias para permitir pruebas deterministas sin
/// llamadas de red ni cuentas reales.
class RecoveryService {
  final SupabaseClient? _clientOverride;
  final PasswordResetInvoker? _resetInvoker;
  final PasswordUpdateInvoker? _updateInvoker;
  final SessionChecker? _sessionChecker;

  RecoveryService({
    SupabaseClient? client,
    PasswordResetInvoker? resetInvoker,
    PasswordUpdateInvoker? updateInvoker,
    SessionChecker? sessionChecker,
  })  : _clientOverride = client,
        _resetInvoker = resetInvoker,
        _updateInvoker = updateInvoker,
        _sessionChecker = sessionChecker;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    if (Supabase.instance.isInitialized) return Supabase.instance.client;
    return null;
  }

  Session? get currentSession {
    final checker = _sessionChecker;
    if (checker != null) return checker();
    return _client?.auth.currentSession;
  }

  /// Solicita el restablecimiento de contraseña para un identificador dado.
  ///
  /// - Rechaza identificadores vacíos.
  /// - Si se suministra un número telefónico (sin correo real), advierte que los enlaces
  ///   de recuperación se envían exclusivamente por correo electrónico y no a buzones sintéticos.
  /// - Envía la solicitud oficial a Supabase Auth (`resetPasswordForEmail`).
  /// - Devuelve un mensaje genérico seguro para evitar la enumeración de cuentas.
  Future<RecoveryResult> requestPasswordReset({
    required String contact,
    String? redirectTo,
  }) async {
    final trimmed = contact.trim();

    if (trimmed.isEmpty) {
      return RecoveryResult.failure(
        message: 'Ingresa tu correo electrónico.',
        isValidation: true,
      );
    }

    // Comprobar si el usuario ingresó un teléfono puro
    final isPhone = !trimmed.contains('@') &&
        RegExp(r'^[+0-9\s\-()]+$').hasMatch(trimmed);

    if (isPhone) {
      return RecoveryResult.failure(
        message:
            'La recuperación por enlace requiere un correo electrónico. Si te registraste únicamente con un número de teléfono, por favor contacta al administrador.',
        isValidation: true,
      );
    }

    // Validación básica de formato de correo
    final emailRegex = RegExp(r'^[\w\.\+_\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return RecoveryResult.failure(
        message: 'Ingresa un correo electrónico válido.',
        isValidation: true,
      );
    }

    // Si es un correo sintético interno generado para teléfonos, tampoco es un destino de correo real
    if (trimmed.toLowerCase().endsWith('@agromarket.com')) {
      return RecoveryResult.failure(
        message:
            'La dirección indicada corresponde a un identificador interno de teléfono sin buzón de correo. La recuperación por enlace requiere un correo electrónico real.',
        isValidation: true,
      );
    }

    try {
      final invoker = _resetInvoker;
      if (invoker != null) {
        await invoker(trimmed, redirectTo: redirectTo);
      } else {
        final client = _client;
        if (client == null) {
          return RecoveryResult.failure(
            message: 'El servicio de autenticación no está inicializado.',
          );
        }
        await client.auth.resetPasswordForEmail(
          trimmed,
          redirectTo: redirectTo,
        );
      }

      // Mensaje genérico para evitar enumeración de cuentas
      return RecoveryResult.success(
        message:
            'Si los datos corresponden a una cuenta registrada, se enviarán las instrucciones para restablecer tu contraseña.',
      );
    } on SocketException catch (_) {
      return RecoveryResult.failure(
        message:
            'Error de conexión. Verifica tu acceso a internet e inténtalo nuevamente.',
        isNetwork: true,
      );
    } on AuthException catch (e) {
      debugPrint(
        '[RecoveryService.requestPasswordReset] AuthException: '
        'type=${e.runtimeType}, statusCode=${e.statusCode}, code=${e.code}, message=${e.message}',
      );
      // Manejar posibles errores del proveedor (rate limit, etc.)
      if (e.statusCode == '429' || e.message.toLowerCase().contains('rate limit')) {
        return RecoveryResult.failure(
          message:
              'Demasiadas solicitudes en poco tiempo. Por favor, espera unos minutos antes de intentar de nuevo.',
        );
      }
      return RecoveryResult.failure(
        message: e.message.isNotEmpty
            ? e.message
            : 'No se pudo procesar la solicitud. Por favor intenta más tarde.',
      );
    } catch (e) {
      debugPrint(
        '[RecoveryService.requestPasswordReset] Error inesperado: '
        'type=${e.runtimeType}, description=$e',
      );
      final errStr = e.toString();
      if (_isNetworkErrorString(errStr)) {
        return RecoveryResult.failure(
          message:
              'Error de conexión. Verifica tu acceso a internet e inténtalo nuevamente.',
          isNetwork: true,
        );
      }
      return RecoveryResult.failure(
        message: 'No se pudo procesar la solicitud. Por favor intenta más tarde.',
      );
    }
  }

  /// Actualiza la contraseña del usuario en el contexto de una sesión de recuperación válida.
  ///
  /// - Exige longitud mínima de 6 caracteres.
  /// - Exige que la confirmación coincida.
  /// - Verifica la existencia de una sesión de recuperación activa.
  /// - Invoca `updateUser(UserAttributes(password: newPassword))`.
  Future<RecoveryResult> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty) {
      return RecoveryResult.failure(
        message: 'Este campo es requerido.',
        isValidation: true,
      );
    }

    if (newPassword.length < 6) {
      return RecoveryResult.failure(
        message: 'La contraseña debe tener al menos 6 caracteres.',
        isValidation: true,
      );
    }

    if (newPassword != confirmPassword) {
      return RecoveryResult.failure(
        message: 'Las contraseñas no coinciden.',
        isValidation: true,
      );
    }

    // Verificar si hay una sesión activa de recuperación
    final session = currentSession;
    if (session == null && _updateInvoker == null) {
      return RecoveryResult.failure(
        message:
            'El enlace de recuperación es inválido o ha caducado. Por favor, solicita uno nuevo.',
      );
    }

    try {
      final updater = _updateInvoker;
      if (updater != null) {
        await updater(UserAttributes(password: newPassword));
      } else {
        final client = _client;
        if (client == null) {
          return RecoveryResult.failure(
            message: 'El servicio de autenticación no está inicializado.',
          );
        }
        await client.auth.updateUser(UserAttributes(password: newPassword));
      }

      return RecoveryResult.success(
        message:
            'Contraseña actualizada exitosamente. Por favor, inicia sesión con tu nueva contraseña.',
      );
    } on SocketException catch (_) {
      return RecoveryResult.failure(
        message:
            'Error de conexión. Verifica tu acceso a internet e inténtalo nuevamente.',
        isNetwork: true,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('session') ||
          msg.contains('expired') ||
          msg.contains('jwt') ||
          msg.contains('token')) {
        return RecoveryResult.failure(
          message:
              'El enlace de recuperación es inválido o ha caducado. Por favor, solicita uno nuevo.',
        );
      }
      return RecoveryResult.failure(
        message: e.message.isNotEmpty
            ? e.message
            : 'No se pudo actualizar la contraseña. Por favor intenta más tarde.',
      );
    } catch (e) {
      final errStr = e.toString();
      if (_isNetworkErrorString(errStr)) {
        return RecoveryResult.failure(
          message:
              'Error de conexión. Verifica tu acceso a internet e inténtalo nuevamente.',
          isNetwork: true,
        );
      }
      return RecoveryResult.failure(
        message: 'No se pudo actualizar la contraseña. Por favor intenta más tarde.',
      );
    }
  }

  bool _isNetworkErrorString(String err) {
    return err.contains('SocketException') ||
        err.contains('ClientException') ||
        err.contains('Network') ||
        err.contains('TimeoutException') ||
        err.contains('Failed host lookup');
  }
}
