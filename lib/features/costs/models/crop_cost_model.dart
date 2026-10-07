enum CostCategory {
  jornales,
  fertilizantes,
  transporte,
  otros;

  static CostCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'jornales':
        return CostCategory.jornales;
      case 'fertilizantes':
        return CostCategory.fertilizantes;
      case 'transporte':
        return CostCategory.transporte;
      case 'otros':
      default:
        return CostCategory.otros;
    }
  }

  String toShortString() {
    return name;
  }
  
  String toDisplayName() {
    switch (this) {
      case CostCategory.jornales:
        return 'Jornales';
      case CostCategory.fertilizantes:
        return 'Fertilizantes';
      case CostCategory.transporte:
        return 'Transporte';
      case CostCategory.otros:
        return 'Otros';
    }
  }
}

class CropCostModel {
  final String id;
  final String cropId;
  final CostCategory category;
  final String description;
  final double amount;
  final DateTime createdAt;

  CropCostModel({
    required this.id,
    required this.cropId,
    required this.category,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory CropCostModel.fromJson(Map<String, dynamic> json) {
    return CropCostModel(
      id: json['id'] as String,
      cropId: json['crop_id'] as String,
      category: CostCategory.fromString(json['category'] as String),
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'crop_id': cropId,
      'category': category.toShortString(),
      'description': description,
      'amount': amount,
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
