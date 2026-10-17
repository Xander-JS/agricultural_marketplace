import 'negotiation_status.dart';
import '../../crop/models/crop_model.dart';
import 'negotiation_offer_model.dart';
import '../../../core/constants/user_roles.dart';

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
  final Map<String, dynamic>? farmerProfile;
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
    this.farmerProfile,
    this.offers,
  });

  /// Rol normalizado que debe responder actualmente
  UserRole get responderRole => UserRole.fromString(currentResponder);

  /// Es el turno del agricultor / productor
  bool get isFarmerTurn => responderRole == UserRole.agricultor;

  /// Es el turno del comprador / comerciante
  bool get isBuyerTurn => responderRole == UserRole.comprador;

  /// Determina si es el turno del usuario autenticado según su rol
  bool isMyTurn({required bool isBuyer}) {
    return (isBuyer && isBuyerTurn) || (!isBuyer && isFarmerTurn);
  }

  factory NegotiationModel.fromJson(Map<String, dynamic> json) {
    List<NegotiationOfferModel>? parsedOffers;
    if (json['negotiation_offers'] != null) {
      if (json['negotiation_offers'] is List) {
        parsedOffers = (json['negotiation_offers'] as List)
            .map((o) => NegotiationOfferModel.fromJson(o))
            .toList();
      }
    }

    Map<String, dynamic>? parsedFarmerProfile;
    if (json['crops'] != null && json['crops'] is Map && json['crops']['profiles'] != null) {
      parsedFarmerProfile = json['crops']['profiles'] as Map<String, dynamic>;
    } else if (json['farmer_profile'] != null && json['farmer_profile'] is Map) {
      parsedFarmerProfile = json['farmer_profile'] as Map<String, dynamic>;
    }

    return NegotiationModel(
      id: json['id'] as String? ?? '',
      cropId: json['crop_id'] as String,
      buyerId: json['buyer_id'] as String,
      status: NegotiationStatus.fromString(json['status'] as String),
      currentResponder: json['current_responder'] as String? ?? 'agricultor',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'].toString())
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'].toString())
        : DateTime.now(),
      crop: json['crops'] != null ? CropModel.fromJson(json['crops']) : null,
      buyerProfile: json['profiles'] != null ? json['profiles'] as Map<String, dynamic> : null,
      farmerProfile: parsedFarmerProfile,
      offers: parsedOffers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'crop_id': cropId,
      'buyer_id': buyerId,
      'status': status.toShortString(),
      'current_responder': responderRole.toDbValue(),
    };
  }
}
