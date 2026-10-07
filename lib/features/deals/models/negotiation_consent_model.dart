class NegotiationConsentModel {
  final String id;
  final String negotiationId;
  final String farmerId;
  final bool sharePhone;
  final bool shareLocation;
  final DateTime createdAt;

  NegotiationConsentModel({
    required this.id,
    required this.negotiationId,
    required this.farmerId,
    required this.sharePhone,
    required this.shareLocation,
    required this.createdAt,
  });

  factory NegotiationConsentModel.fromJson(Map<String, dynamic> json) {
    return NegotiationConsentModel(
      id: json['id'] as String? ?? '',
      negotiationId: json['negotiation_id'] as String,
      farmerId: json['farmer_id'] as String,
      sharePhone: json['share_phone'] as bool? ?? false,
      shareLocation: json['share_location'] as bool? ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'].toString())
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'negotiation_id': negotiationId,
      'farmer_id': farmerId,
      'share_phone': sharePhone,
      'share_location': shareLocation,
    };
  }
}
