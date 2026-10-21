class NegotiationConsentModel {
  final String id;
  final String negotiationId;
  final String userId;
  final bool sharePhone;
  final bool shareLocation;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Alias de compatibilidad hacia atrás para código que referencie `farmerId`
  String get farmerId => userId;

  NegotiationConsentModel({
    required this.id,
    required this.negotiationId,
    required this.userId,
    required this.sharePhone,
    required this.shareLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NegotiationConsentModel.fromJson(Map<String, dynamic> json) {
    final uid = (json['user_id'] ?? json['farmer_id']) as String? ?? '';
    return NegotiationConsentModel(
      id: json['id'] as String? ?? '',
      negotiationId: json['negotiation_id'] as String? ?? '',
      userId: uid,
      sharePhone: json['share_phone'] as bool? ?? false,
      shareLocation: json['share_location'] as bool? ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'].toString())
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'].toString())
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'negotiation_id': negotiationId,
      'user_id': userId,
      'share_phone': sharePhone,
      'share_location': shareLocation,
    };
  }
}

/// Representa el paquete de información de contacto y estado de consentimientos
/// bidireccionales retornado de forma segura por la RPC `get_negotiation_counterpart_contact`.
class NegotiationContactInfo {
  final String negotiationId;
  final String status;
  final bool mySharePhone;
  final bool myShareLocation;
  final DateTime? myConsentUpdatedAt;
  final bool counterpartSharePhone;
  final bool counterpartShareLocation;
  final DateTime? counterpartConsentUpdatedAt;
  final String counterpartId;
  final String counterpartName;
  final String counterpartRole;
  final String? counterpartProfilePath;
  final String? counterpartPhone;
  final String? counterpartDepartment;
  final String? counterpartMunicipality;
  final double? counterpartLatitude;
  final double? counterpartLongitude;

  NegotiationContactInfo({
    required this.negotiationId,
    required this.status,
    required this.mySharePhone,
    required this.myShareLocation,
    this.myConsentUpdatedAt,
    required this.counterpartSharePhone,
    required this.counterpartShareLocation,
    this.counterpartConsentUpdatedAt,
    required this.counterpartId,
    required this.counterpartName,
    required this.counterpartRole,
    this.counterpartProfilePath,
    this.counterpartPhone,
    this.counterpartDepartment,
    this.counterpartMunicipality,
    this.counterpartLatitude,
    this.counterpartLongitude,
  });

  bool get isDealAgreedOrCompleted =>
      status == 'acordada' || status == 'completada';

  bool get hasCounterpartPhone =>
      counterpartPhone != null && counterpartPhone!.trim().isNotEmpty;

  bool get hasCounterpartLocation =>
      (counterpartDepartment != null && counterpartDepartment!.trim().isNotEmpty) ||
      (counterpartMunicipality != null && counterpartMunicipality!.trim().isNotEmpty) ||
      (counterpartLatitude != null && counterpartLongitude != null);

  factory NegotiationContactInfo.fromJson(Map<String, dynamic> json) {
    final myConsent = json['my_consent'] as Map<String, dynamic>? ?? {};
    final counterpartConsent =
        json['counterpart_consent'] as Map<String, dynamic>? ?? {};
    final profile =
        json['counterpart_profile'] as Map<String, dynamic>? ?? {};

    return NegotiationContactInfo(
      negotiationId: json['negotiation_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      mySharePhone: myConsent['share_phone'] as bool? ?? false,
      myShareLocation: myConsent['share_location'] as bool? ?? false,
      myConsentUpdatedAt: myConsent['updated_at'] != null
          ? DateTime.tryParse(myConsent['updated_at'].toString())
          : null,
      counterpartSharePhone:
          counterpartConsent['share_phone'] as bool? ?? false,
      counterpartShareLocation:
          counterpartConsent['share_location'] as bool? ?? false,
      counterpartConsentUpdatedAt: counterpartConsent['updated_at'] != null
          ? DateTime.tryParse(counterpartConsent['updated_at'].toString())
          : null,
      counterpartId: profile['id'] as String? ?? '',
      counterpartName: profile['full_name'] as String? ?? '',
      counterpartRole: profile['role'] as String? ?? '',
      counterpartProfilePath: profile['profile_path'] as String?,
      counterpartPhone: profile['phone'] as String?,
      counterpartDepartment: profile['department'] as String?,
      counterpartMunicipality: profile['municipality'] as String?,
      counterpartLatitude: profile['latitude'] != null
          ? (profile['latitude'] as num).toDouble()
          : null,
      counterpartLongitude: profile['longitude'] != null
          ? (profile['longitude'] as num).toDouble()
          : null,
    );
  }
}
