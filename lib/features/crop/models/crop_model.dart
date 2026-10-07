import 'package:flutter/foundation.dart';

enum CropStatus {
  borrador,
  activa,
  pausada,
  agotada;

  static CropStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'activa':
        return CropStatus.activa;
      case 'pausada':
        return CropStatus.pausada;
      case 'agotada':
        return CropStatus.agotada;
      case 'borrador':
      default:
        return CropStatus.borrador;
    }
  }

  String toShortString() {
    return name.toString();
  }
}

class CropModel {
  final String id;
  final String farmerId;
  final String title;
  final String description;
  final String cropType;
  final double pricePerKg;
  final double stockTotal;
  final double stockCommitted;
  final double stockSold;
  final double minOrderKg;
  final double? estimatedYieldKg;
  final String department;
  final String municipality;
  final double? latitude;
  final double? longitude;
  final bool isEarlySale;
  final DateTime? estimatedHarvestDate;
  final CropStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for relationships
  final List<String> imageUrls; // Mapped from crop_images

  CropModel({
    required this.id,
    required this.farmerId,
    required this.title,
    required this.description,
    required this.cropType,
    required this.pricePerKg,
    this.stockTotal = 0.0,
    this.stockCommitted = 0.0,
    this.stockSold = 0.0,
    this.minOrderKg = 1.0,
    this.estimatedYieldKg,
    required this.department,
    required this.municipality,
    this.latitude,
    this.longitude,
    this.isEarlySale = false,
    this.estimatedHarvestDate,
    this.status = CropStatus.borrador,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls = const [],
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    // Handle relationships if fetched together
    List<String> parsedImageUrls = [];
    if (json['crop_images'] != null && json['crop_images'] is List) {
      parsedImageUrls = (json['crop_images'] as List).map((img) {
        return img['image_path'] as String;
      }).toList();
    }

    return CropModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      cropType: json['crop_type'] as String,
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
      stockTotal: (json['stock_total'] as num).toDouble(),
      stockCommitted: (json['stock_committed'] as num).toDouble(),
      stockSold: (json['stock_sold'] as num).toDouble(),
      minOrderKg: (json['min_order_kg'] as num).toDouble(),
      estimatedYieldKg: json['estimated_yield_kg'] != null
          ? (json['estimated_yield_kg'] as num).toDouble()
          : null,
      department: json['department'] as String,
      municipality: json['municipality'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isEarlySale: json['is_early_sale'] as bool? ?? false,
      estimatedHarvestDate: json['estimated_harvest_date'] != null
          ? DateTime.tryParse(json['estimated_harvest_date'].toString())
          : null,
      status: CropStatus.fromString(json['status'] as String? ?? 'borrador'),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      imageUrls: parsedImageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'farmer_id': farmerId,
      'title': title,
      'description': description,
      'crop_type': cropType,
      'price_per_kg': pricePerKg,
      'stock_total': stockTotal,
      'min_order_kg': minOrderKg,
      'department': department,
      'municipality': municipality,
      'is_early_sale': isEarlySale,
      'status': status.toShortString(),
    };

    if (estimatedYieldKg != null) data['estimated_yield_kg'] = estimatedYieldKg;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (estimatedHarvestDate != null) {
      data['estimated_harvest_date'] =
          estimatedHarvestDate!.toIso8601String().split('T')[0];
    }
    // Only send id if it's set (usually not sent on create)
    if (id.isNotEmpty) data['id'] = id;

    return data;
  }
}
