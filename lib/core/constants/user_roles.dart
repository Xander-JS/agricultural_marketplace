/// Representación centralizada de roles de usuario según el enum PostgreSQL `user_role`:
/// - `agricultor`
/// - `comprador`
/// - `moderador`
///
/// Permite mapear y normalizar identificadores internos de Flutter (`farmer`, `buyer`, `comerciante`)
/// hacia los valores persistibles admitidos por Supabase.
enum UserRole {
  agricultor,
  comprador,
  moderador;

  /// Valor exacto esperado por el enum PostgreSQL `user_role`
  String toDbValue() {
    switch (this) {
      case UserRole.agricultor:
        return 'agricultor';
      case UserRole.comprador:
        return 'comprador';
      case UserRole.moderador:
        return 'moderador';
    }
  }

  /// Analiza cualquier variante de cadena (`farmer`, `buyer`, `comerciante`, etc.)
  /// y retorna el rol tipado correspondiente.
  static UserRole fromString(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'farmer':
      case 'agricultor':
      case 'productor':
        return UserRole.agricultor;
      case 'buyer':
      case 'comprador':
      case 'comerciante':
        return UserRole.comprador;
      case 'moderator':
      case 'moderador':
        return UserRole.moderador;
      default:
        return UserRole.agricultor;
    }
  }

  /// Convierte cualquier cadena de rol a su valor seguro para Supabase
  static String toDb(String? role) {
    return fromString(role).toDbValue();
  }

  /// Verifica si una cadena representa el rol Comprador / Comerciante
  static bool isBuyerRole(String? role) {
    return fromString(role) == UserRole.comprador;
  }

  /// Verifica si una cadena representa el rol Agricultor / Productor
  static bool isFarmerRole(String? role) {
    return fromString(role) == UserRole.agricultor;
  }

  /// Verifica si una cadena representa el rol Moderador
  static bool isModeratorRole(String? role) {
    return fromString(role) == UserRole.moderador;
  }

  bool get isModerator => this == UserRole.moderador;
  bool get isBuyer => this == UserRole.comprador;
  bool get isFarmer => this == UserRole.agricultor;

  /// Nombre amigable por defecto en español
  String get displayName {
    switch (this) {
      case UserRole.agricultor:
        return 'Agricultor';
      case UserRole.comprador:
        return 'Comprador';
      case UserRole.moderador:
        return 'Moderador';
    }
  }
}

/// Estados de verificación de usuario según el enum PostgreSQL `user_verification_status`
enum UserVerificationStatus {
  pendiente,
  enRevisionIa,
  aprobado,
  rechazado,
  suspendido,
  desconocido;

  String toDbValue() {
    switch (this) {
      case UserVerificationStatus.pendiente:
        return 'pendiente';
      case UserVerificationStatus.enRevisionIa:
        return 'en_revision_ia';
      case UserVerificationStatus.aprobado:
        return 'aprobado';
      case UserVerificationStatus.rechazado:
        return 'rechazado';
      case UserVerificationStatus.suspendido:
        return 'suspendido';
      case UserVerificationStatus.desconocido:
        return 'desconocido';
    }
  }

  static UserVerificationStatus fromString(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'en_revision_ia':
      case 'enrevisionia':
      case 'revision':
        return UserVerificationStatus.enRevisionIa;
      case 'aprobado':
      case 'approved':
        return UserVerificationStatus.aprobado;
      case 'rechazado':
      case 'rejected':
        return UserVerificationStatus.rechazado;
      case 'suspendido':
      case 'suspended':
        return UserVerificationStatus.suspendido;
      case 'pendiente':
      case 'pending':
        return UserVerificationStatus.pendiente;
      default:
        return UserVerificationStatus.desconocido;
    }
  }

  bool get isApproved => this == UserVerificationStatus.aprobado;
}
