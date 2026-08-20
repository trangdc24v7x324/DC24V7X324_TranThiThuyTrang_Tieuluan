// FILE HỌC TẬP: lib/models/order_item_model.dart
// Vai trò: Mô hình dữ liệu đơn hàng mục.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp OrderItemModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;

  final String productName;
  final String productImage;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final String note;

  final String categoryId;
  final String categoryTitle;
  final String categorySlug;

  final DateTime? created;
  final DateTime? updated;

  // Khởi tạo OrderItemModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu đơn hàng mục.
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage = '',
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.note = '',
    this.categoryId = '',
    this.categoryTitle = 'Khác',
    this.categorySlug = 'khac',
    this.created,
    this.updated,
  });

  // Khởi tạo OrderItemModel.fromJson: tạo đối tượng OrderItemModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order']?.toString() ?? '',
      productId: json['product']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
      unitPrice: _toDouble(json['unit_price']),
      quantity: _toInt(json['quantity'], defaultValue: 1),
      subtotal: _toDouble(json['subtotal']),
      note: json['note']?.toString() ?? '',
      categoryId: json['category']?.toString() ?? '',
      categoryTitle: json['category_title']?.toString() ?? 'Khác',
      categorySlug: json['category_slug']?.toString() ?? 'khac',
      created: DateTime.tryParse(json['created']?.toString() ?? ''),
      updated: DateTime.tryParse(json['updated']?.toString() ?? ''),
    );
  }

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
  Map<String, dynamic> toJson() {
    return {
      'order': orderId,
      'product': productId,
      'product_name': productName,
      'product_image': productImage,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'note': note,
      'category': categoryId,
      'category_title': categoryTitle,
      'category_slug': categorySlug,
    };
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    String? productImage,
    double? unitPrice,
    int? quantity,
    double? subtotal,
    String? note,
    String? categoryId,
    String? categoryTitle,
    String? categorySlug,
    DateTime? created,
    DateTime? updated,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      categorySlug: categorySlug ?? this.categorySlug,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu đơn hàng mục.
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // Xử lý _toInt: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu đơn hàng mục.
  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }
}
