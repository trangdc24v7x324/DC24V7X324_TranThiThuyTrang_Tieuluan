// FILE HỌC TẬP: lib/models/product_review_model.dart
// Vai trò: Mô hình dữ liệu đánh giá sản phẩm.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp ProductReviewModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
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

  // Khởi tạo ProductReviewModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu đánh giá sản phẩm.
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

  // Khởi tạo ProductReviewModel.fromJson: tạo đối tượng ProductReviewModel bằng constructor fromJson từ dữ liệu đầu vào.
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

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
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

  // Xử lý _toInt: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu đánh giá sản phẩm.
  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// Lớp ProductRatingStats: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class ProductRatingStats {
  final double average;
  final int count;

  // Khởi tạo ProductRatingStats: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu đánh giá sản phẩm.
  const ProductRatingStats({this.average = 0, this.count = 0});
}
