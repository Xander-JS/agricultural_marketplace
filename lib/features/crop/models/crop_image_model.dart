class CropImageModel {
  final String id;
  final String cropId;
  final String imagePath;
  final bool isPrimary;
  final DateTime createdAt;

  CropImageModel({
    required this.id,
    required this.cropId,
    required this.imagePath,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory CropImageModel.fromJson(Map<String, dynamic> json) {
    return CropImageModel(
      id: json['id'] as String,
      cropId: json['crop_id'] as String,
      imagePath: json['image_path'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_id': cropId,
      'image_path': imagePath,
      'is_primary': isPrimary,
    };
  }
}
