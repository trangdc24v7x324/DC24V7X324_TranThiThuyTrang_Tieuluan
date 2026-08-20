
import 'product_model.dart';

class CartItemModel {
  final String productId;
  final String title;
  final String image;

  final double price;

  final double originalPrice;

  final int quantity;

  final String note;

  final String categoryId;
  final String categoryTitle;
  final String categorySlug;

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

  String get normalizedNote => note.trim();

  double get effectiveOriginalPrice =>
      originalPrice > 0 ? originalPrice : price;

  bool get hasDiscount => effectiveOriginalPrice > price;

  double get discountAmount => hasDiscount ? effectiveOriginalPrice - price : 0;

  int get discountPercent {
    if (!hasDiscount || effectiveOriginalPrice <= 0) {
      return 0;
    }

    return ((discountAmount / effectiveOriginalPrice) * 100).round();
  }

  double get subtotal => price * quantity;

  double get originalSubtotal => effectiveOriginalPrice * quantity;

  double get totalDiscount => discountAmount * quantity;

  bool sameLine(CartItemModel other) {
    return productId == other.productId &&
        normalizedNote == other.normalizedNote;
  }

  factory CartItemModel.fromProduct(
    ProductModel product, {
    int quantity = 1,
    String note = '',
  }) {
    return CartItemModel(
      productId: product.id,
      title: product.title,
      image: product.image,

      price: product.effectivePrice,

      originalPrice: product.price,

      quantity: quantity,
      note: note.trim(),

      categoryId: product.categoryId,
      categoryTitle: product.categoryTitle,
      categorySlug: product.categorySlug,
    );
  }

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
