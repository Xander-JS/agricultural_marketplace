import 'negotiation_status.dart';
import '../../crop/models/crop_model.dart';
import 'negotiation_offer_model.dart';

class NegotiationModel {
  final String id;
  final String cropId;
  final String buyerId;
  final NegotiationStatus status;
  final String currentResponder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final CropModel? crop;
  final Map<String, dynamic>? buyerProfile;
  final List<NegotiationOfferModel>? offers;

  NegotiationModel({
    required this.id,
    required this.cropId,
    required this.buyerId,
    required this.status,
    required this.currentResponder,
    required this.createdAt,
    required this.updatedAt,
    this.crop,
    this.buyerProfile,
    this.offers,
  });

  factory NegotiationModel.fromJson(Map<String, dynamic> json) {
    List<NegotiationOfferModel>? parsedOffers;
    if (json['negotiation_offers'] != null) {
      if (json['negotiation_offers'] is List) {
        parsedOffers = (json['negotiation_offers'] as List)
            .map((o) => NegotiationOfferModel.fromJson(o))
            .toList();
      }
    }

    return NegotiationModel(
      id: json['id'] as String? ?? '',
      cropId: json['crop_id'] as String,
      buyerId: json['buyer_id'] as String,
      status: NegotiationStatus.fromString(json['status'] as String),
      currentResponder: json['current_responder'] as String,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'].toString())
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'].toString())
        : DateTime.now(),
      crop: json['crops'] != null ? CropModel.fromJson(json['crops']) : null,
      buyerProfile: json['profiles'] != null ? json['profiles'] as Map<String, dynamic> : null,
      offers: parsedOffers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'crop_id': cropId,
      'buyer_id': buyerId,
      'status': status.toShortString(),
      'current_responder': currentResponder,
    };
  }
}
