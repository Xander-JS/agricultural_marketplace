/// Excepciones tipadas y estructuradas para el ciclo comercial de Agricultural Marketplace.
///
/// Todas las excepciones implementan [Exception] y sobreescriben [toString] devolviendo
/// únicamente [message] para garantizar mensajes legibles en la interfaz de usuario (SnackBar),
/// protegiendo tokens, credenciales y datos sensibles contra exposiciones en logs o pantallas.
library;

abstract class CommercialException implements Exception {
  final String message;
  final String? code;
  final String? details;

  const CommercialException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() => message;
}

/// Excepción para usuarios no autenticados, tokens expirados o sesiones ausentes (Código SQL 28000).
///
/// Debe utilizarse EXCLUSIVAMENTE cuando no existe identidad comprobada del usuario (sesión nula o expirada).
/// En estos casos, la aplicación puede redirigir al flujo de login.
class CommercialAuthException extends CommercialException {
  const CommercialAuthException(
    super.message, {
    super.code,
    super.details,
  });
}

/// Excepción para operaciones denegadas por políticas de seguridad RLS o privilegios insuficientes (Código SQL 42501).
///
/// A diferencia de [CommercialAuthException], el usuario SÍ cuenta con una sesión autenticada válida,
/// pero no posee autorización para consultar o mutar la fila o columna requerida.
/// NO debe cerrar la sesión ni redirigir al login.
class CommercialAuthorizationException extends CommercialException {
  const CommercialAuthorizationException(
    super.message, {
    super.code,
    super.details,
  });
}

/// Excepción para violaciones de reglas comerciales: perfil no aprobado, auto-negociación,
/// rol no autorizado, cultivo inactivo o pedido mínimo no satisfecho (Código 42501 / 22000 / P0002).
class CommercialValidationException extends CommercialException {
  const CommercialValidationException(
    super.message, {
    super.code,
    super.details,
  });
}

/// Excepción específica para cantidad solicitada superior al stock disponible (Código 22000).
class InsufficientStockException extends CommercialException {
  const InsufficientStockException(
    super.message, {
    super.code,
    super.details,
  });
}

/// Excepción para colisión concurrente o intento de crear una segunda negociación activa
/// sobre la misma cosecha para el mismo comprador (Código 23505 - Unique Violation).
class DuplicateNegotiationException extends CommercialException {
  const DuplicateNegotiationException(
    super.message, {
    super.code,
    super.details,
  });
}

/// Excepción para errores inesperados de comunicación o base de datos.
class CommercialDatabaseException extends CommercialException {
  final Object? originalError;

  const CommercialDatabaseException(
    super.message, {
    super.code,
    super.details,
    this.originalError,
  });

  @override
  String toString() => message;
}
