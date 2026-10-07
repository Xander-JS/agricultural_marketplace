class NegotiationOfferModel {
  final String id;
  final String negotiationId;
  final String senderId;
  final double quantityKg;
  final double proposedPricePerKg;
  final String deliveryMethod;
  final String? message;
  final DateTime createdAt;

  NegotiationOfferModel({
    required this.id,
    required this.negotiationId,
    required this.senderId,
    required this.quantityKg,
    required this.proposedPricePerKg,
    required this.deliveryMethod,
    this.message,
    required this.createdAt,
  });

  factory NegotiationOfferModel.fromJson(Map<String, dynamic> json) {
    return NegotiationOfferModel(
      id: json['id'] as String? ?? '',
      negotiationId: json['negotiation_id'] as String,
      senderId: json['sender_id'] as String,
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      proposedPricePerKg: (json['proposed_price_per_kg'] as num).toDouble(),
      deliveryMethod: json['delivery_method'] as String,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'].toString())
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'negotiation_id': negotiationId,
      'sender_id': senderId,
      'quantity_kg': quantityKg,
      'proposed_price_per_kg': proposedPricePerKg,
      'delivery_method': deliveryMethod,
      if (message != null) 'message': message,
    };
  }
}
