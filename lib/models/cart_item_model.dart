// FILE HỌC TẬP: lib/models/cart_item_model.dart
// Vai trò: Mô hình dữ liệu giỏ hàng mục.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

import 'product_model.dart';

// Lớp CartItemModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class CartItemModel {
  final String productId;
  final String title;
  final String image;

  // Giá thực tế được chốt tại thời điểm thêm vào giỏ.
  // Sale hợp lệ -> effectivePrice, ngược lại -> price.
  final double price;

  // Giá gốc snapshot để CartPage hiển thị giá gạch ngang/tiết kiệm.
  final double originalPrice;

  final int quantity;

  // Ghi chú riêng cho từng dòng sản phẩm.
  // Ví dụ: "ít đá", "không hành".
  final String note;

  final String categoryId;
  final String categoryTitle;
  final String categorySlug;

  // Khởi tạo CartItemModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu giỏ hàng mục.
  const CartItemModel({
    required this.productId,
    required this.title,
    this.image = '',
    required this.price,
    this.originalPrice = 0,
    this.quantity = 1,
    this.note = '',
    this.categoryId = '',
    this.categoryTitle = 'Khác',
    this.categorySlug = 'khac',
  });

  // Chuẩn hóa note để so sánh các dòng giỏ hàng.
  // Đọc normalized note (normalizedNote): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get normalizedNote => note.trim();

  // Giá gốc thực tế dùng cho UI.
  // Tương thích với item cũ nếu originalPrice chưa được gán.
  // Đọc hiệu lực gốc price (effectiveOriginalPrice): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get effectiveOriginalPrice =>
      originalPrice > 0 ? originalPrice : price;

  // Đọc trạng thái có giảm giá (hasDiscount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasDiscount => effectiveOriginalPrice > price;

  // Đọc giảm giá số tiền (discountAmount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get discountAmount => hasDiscount ? effectiveOriginalPrice - price : 0;

  // Đọc giảm giá phần trăm (discountPercent): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get discountPercent {
    if (!hasDiscount || effectiveOriginalPrice <= 0) {
      return 0;
    }

    return ((discountAmount / effectiveOriginalPrice) * 100).round();
  }

  // Đọc tạm tính (subtotal): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get subtotal => price * quantity;

  // Đọc gốc tạm tính (originalSubtotal): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get originalSubtotal => effectiveOriginalPrice * quantity;

  // Đọc tổng số tiền giảm giá (totalDiscount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get totalDiscount => discountAmount * quantity;

  // Cùng sản phẩm + cùng ghi chú mới được xem là cùng một dòng.
  // Xử lý sameLine: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu giỏ hàng mục.
  bool sameLine(CartItemModel other) {
    return productId == other.productId &&
        normalizedNote == other.normalizedNote;
  }

  // Khởi tạo CartItemModel.fromProduct: tạo đối tượng CartItemModel bằng constructor fromProduct từ dữ liệu đầu vào.
  factory CartItemModel.fromProduct(
    ProductModel product, {
    int quantity = 1,
    String note = '',
  }) {
    return CartItemModel(
      productId: product.id,
      title: product.title,
      image: product.image,

      // Luồng giá mới: luôn dùng giá thực tế.
      price: product.effectivePrice,

      // Lưu giá gốc để CartPage tính phần giảm giá.
      originalPrice: product.price,

      quantity: quantity,
      note: note.trim(),

      categoryId: product.categoryId,
      categoryTitle: product.categoryTitle,
      categorySlug: product.categorySlug,
    );
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  CartItemModel copyWith({
    String? productId,
    String? title,
    String? image,
    double? price,
    double? originalPrice,
    int? quantity,
    String? note,
    String? categoryId,
    String? categoryTitle,
    String? categorySlug,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      image: image ?? this.image,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      categorySlug: categorySlug ?? this.categorySlug,
    );
  }
}
