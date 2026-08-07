class ProductReviewModel {
  final String id;

  final String productId;
  final String userId;

  final String userFullName;

  final int rating;

  final String comment;

  final bool isVisible;

  final DateTime? created;
  final DateTime? updated;

  const ProductReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    this.userFullName = 'Khách hàng',
    required this.rating,
    this.comment = '',
    this.isVisible = true,
    this.created,
    this.updated,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: json['id']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      userFullName: json['userFullName']?.toString() ?? 'Khách hàng',
      rating: _toInt(json['rating']),
      comment: json['comment']?.toString() ?? '',
      isVisible: json['isVisible'] != false,
      created: DateTime.tryParse(json['created']?.toString() ?? ''),
      updated: DateTime.tryParse(json['updated']?.toString() ?? ''),
    );
  }

  ProductReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userFullName,
    int? rating,
    String? comment,
    bool? isVisible,
    DateTime? created,
    DateTime? updated,
  }) {
    return ProductReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isVisible: isVisible ?? this.isVisible,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProductRatingStats {
  final double average;
  final int count;

  const ProductRatingStats({this.average = 0, this.count = 0});
}
