/// Modelo que representa una calificación registrada en `public.reviews`.
///
/// Corresponde al esquema real:
/// - `id` uuid (PK, generado por la base de datos)
/// - `negotiation_id` uuid (FK a `negotiations`)
/// - `reviewer_id` uuid (FK a `profiles`)
/// - `reviewed_user_id` uuid (FK a `profiles`)
/// - `rating` smallint (1 a 5)
/// - `comment` text opcional
/// - `created_at` timestamptz
class ReviewModel {
  final String? id;
  final String negotiationId;
  final String reviewerId;
  final String reviewedUserId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  const ReviewModel({
    this.id,
    required this.negotiationId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  /// Rango válido de estrellas aceptado por la aplicación.
  ///
  /// La tabla no declara una restricción CHECK para `rating`, por lo que la
  /// validación debe realizarse antes de enviar la calificación.
  static bool isValidRating(int? rating) =>
      rating != null && rating >= 1 && rating <= 5;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawComment = json['comment'] as String?;

    return ReviewModel(
      id: json['id']?.toString(),
      negotiationId: json['negotiation_id']?.toString() ?? '',
      reviewerId: json['reviewer_id']?.toString() ?? '',
      reviewedUserId: json['reviewed_user_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: rawComment != null && rawComment.trim().isNotEmpty
          ? rawComment.trim()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Payload listo para insertar en `public.reviews`.
  ///
  /// No incluye `id` ni `created_at` porque la base de datos los genera.
  Map<String, dynamic> toInsertJson() {
    return {
      'negotiation_id': negotiationId,
      'reviewer_id': reviewerId,
      'reviewed_user_id': reviewedUserId,
      'rating': rating,
      if (comment != null && comment!.trim().isNotEmpty)
        'comment': comment!.trim(),
    };
  }

  /// Serialización completa de una fila existente.
  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      ...toInsertJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

/// Resumen de reputación calculado en memoria a partir de las reseñas recibidas.
class ReviewSummary {
  /// Promedio aritmético de las calificaciones. Es `0` cuando no hay reseñas.
  final double averageRating;

  /// Cantidad total de calificaciones recibidas.
  final int totalReviews;

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
  });

  static const ReviewSummary empty = ReviewSummary(
    averageRating: 0,
    totalReviews: 0,
  );

  factory ReviewSummary.fromReviews(Iterable<ReviewModel> reviews) {
    var total = 0;
    var sum = 0;

    for (final review in reviews) {
      total++;
      sum += review.rating;
    }

    if (total == 0) return empty;

    return ReviewSummary(averageRating: sum / total, totalReviews: total);
  }

  bool get hasRatings => totalReviews > 0;

  /// Permite representar una reputación sin reseñas como «New» / «Sin calificaciones».
  bool get isNew => !hasRatings;

  /// Etiqueta neutra para el promedio: «New» cuando aún no hay reseñas.
  String get reputationLabel =>
      hasRatings ? averageRating.toStringAsFixed(1) : 'New';

  /// Etiqueta neutra para el contador: «No ratings yet» cuando aún no hay reseñas.
  String get countLabel => hasRatings ? '$totalReviews' : 'No ratings yet';
}
