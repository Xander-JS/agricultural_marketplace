import '../../../../core/constants/user_roles.dart';

/// Modelo que representa una solicitud de verificación sujeta a moderación.
///
/// Integra la información del intento (`verification_attempts`) junto con los datos
/// de identidad y contacto del usuario (`profiles`).
class ModerationRequest {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final UserRole userRole;
  final UserVerificationStatus status;
  final String? documentFrontPath;
  final String? documentBackPath;
  final String? selfiePath;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ModerationRequest({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.userRole,
    required this.status,
    this.documentFrontPath,
    this.documentBackPath,
    this.selfiePath,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending =>
      status == UserVerificationStatus.pendiente ||
      status == UserVerificationStatus.enRevisionIa;

  bool get isApproved => status == UserVerificationStatus.aprobado;
  bool get isRejected => status == UserVerificationStatus.rechazado;

  factory ModerationRequest.fromJson(Map<String, dynamic> json) {
    // Si viene anidado desde profiles (join) o plano
    final profileData = json['profiles'] is Map<String, dynamic>
        ? json['profiles'] as Map<String, dynamic>
        : null;

    final rawFullName = profileData?['full_name'] ?? json['full_name'] ?? 'Usuario sin nombre';
    final rawPhone = profileData?['phone'] ?? json['phone'] ?? '';
    final rawEmail = profileData?['email'] ?? json['email'] as String?;
    final rawRole = profileData?['role'] ?? json['user_role'] ?? json['role'];
    final rawStatus = json['status'] ?? profileData?['verification_status'];

    DateTime parseDate(dynamic dateVal) {
      if (dateVal is DateTime) return dateVal;
      if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
      return DateTime.now();
    }

    return ModerationRequest(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? profileData?['id']?.toString() ?? '',
      fullName: rawFullName.toString(),
      phone: rawPhone.toString(),
      email: rawEmail,
      userRole: UserRole.fromString(rawRole?.toString()),
      status: UserVerificationStatus.fromString(rawStatus?.toString()),
      documentFrontPath: json['document_front_path'] as String?,
      documentBackPath: json['document_back_path'] as String?,
      selfiePath: json['selfie_path'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? parseDate(json['reviewed_at']) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': userRole.toDbValue(),
      'status': status.toDbValue(),
      'document_front_path': documentFrontPath,
      'document_back_path': documentBackPath,
      'selfie_path': selfiePath,
      'rejection_reason': rejectionReason,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ModerationRequest copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    UserRole? userRole,
    UserVerificationStatus? status,
    String? documentFrontPath,
    String? documentBackPath,
    String? selfiePath,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModerationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      userRole: userRole ?? this.userRole,
      status: status ?? this.status,
      documentFrontPath: documentFrontPath ?? this.documentFrontPath,
      documentBackPath: documentBackPath ?? this.documentBackPath,
      selfiePath: selfiePath ?? this.selfiePath,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
