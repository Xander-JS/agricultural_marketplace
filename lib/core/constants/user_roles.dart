import '../localization/app_localizations.dart';

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
  /// y retorna el rol tipado correspondiente, o `null` si el rol es nulo o no reconocido.
  static UserRole? tryParse(String? role) {
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
        return null;
    }
  }

  /// Alias de conveniencia para [tryParse]
  static UserRole? tryFromString(String? role) => tryParse(role);

  /// Analiza cualquier variante de cadena (`farmer`, `buyer`, `comerciante`, etc.)
  /// y retorna el rol tipado correspondiente. Si es nulo o desconocido, recurre al valor por defecto.
  static UserRole fromString(
    String? role, {
    UserRole fallback = UserRole.agricultor,
  }) {
    return tryParse(role) ?? fallback;
  }

  /// Convierte cualquier cadena de rol a su valor seguro para Supabase
  static String toDb(String? role) {
    return fromString(role).toDbValue();
  }

  /// Verifica si una cadena representa el rol Comprador / Comerciante
  static bool isBuyerRole(String? role) {
    return tryParse(role) == UserRole.comprador;
  }

  /// Verifica si una cadena representa el rol Agricultor / Productor
  static bool isFarmerRole(String? role) {
    return tryParse(role) == UserRole.agricultor;
  }

  /// Verifica si una cadena representa el rol Moderador
  static bool isModeratorRole(String? role) {
    return tryParse(role) == UserRole.moderador;
  }

  /// Comprueba si una cadena representa un rol reconocido en el sistema
  static bool isValidRole(String? role) {
    return tryParse(role) != null;
  }

  bool get isModerator => this == UserRole.moderador;
  bool get isBuyer => this == UserRole.comprador;
  bool get isFarmer => this == UserRole.agricultor;

  /// Nombre del rol en el idioma activo.
  String localizedName(AppLocalizations l10n) => switch (this) {
    UserRole.agricultor => l10n.role_label_farmer,
    UserRole.comprador => l10n.role_label_buyer,
    UserRole.moderador => l10n.role_label_moderator,
  };

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

  /// Nombre del estado en el idioma activo.
  String localizedName(AppLocalizations l10n) => switch (this) {
    UserVerificationStatus.pendiente => l10n.moderation_status_pending,
    UserVerificationStatus.enRevisionIa => l10n.moderation_filter_in_review,
    UserVerificationStatus.aprobado => l10n.moderation_status_approved,
    UserVerificationStatus.rechazado => l10n.moderation_status_rejected,
    UserVerificationStatus.suspendido => l10n.moderation_status_suspended,
    UserVerificationStatus.desconocido => l10n.moderation_status_unknown,
  };

  bool get isApproved => this == UserVerificationStatus.aprobado;
  bool get isPending => this == UserVerificationStatus.pendiente;
  bool get isUnderAiReview => this == UserVerificationStatus.enRevisionIa;
  bool get isRejected => this == UserVerificationStatus.rechazado;
  bool get isSuspended => this == UserVerificationStatus.suspendido;
  bool get isUnknown => this == UserVerificationStatus.desconocido;

  /// Nombre amigable por defecto en español
  String get displayName {
    switch (this) {
      case UserVerificationStatus.pendiente:
        return 'Pendiente';
      case UserVerificationStatus.enRevisionIa:
        return 'En revisión';
      case UserVerificationStatus.aprobado:
        return 'Aprobado';
      case UserVerificationStatus.rechazado:
        return 'Rechazado';
      case UserVerificationStatus.suspendido:
        return 'Suspendido';
      case UserVerificationStatus.desconocido:
        return 'Desconocido';
    }
  }
}
