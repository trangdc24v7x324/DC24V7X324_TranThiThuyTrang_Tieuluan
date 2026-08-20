// FILE HỌC TẬP: lib/models/product_model.dart
// Vai trò: Mô hình dữ liệu sản phẩm.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp ProductModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class ProductModel {
  final String id;

  final String title;
  final String subtitle;

  final double rating;
  final int reviewCount;

  final String image;
  final String description;
  final String deliveryTime;

  // =========================================================
  // PRICE
  // =========================================================

  /// Giá bán thông thường.
  final double price;

  /// Giá khuyến mãi.
  ///
  /// Giá trị 0 nghĩa là chưa thiết lập giá sale.
  final double salePrice;

  /// Manager bật/tắt chương trình khuyến mãi.
  final bool isOnSale;

  /// Thời gian bắt đầu khuyến mãi.
  ///
  /// null = không giới hạn thời gian bắt đầu.
  final DateTime? saleStartAt;

  /// Thời gian kết thúc khuyến mãi.
  ///
  /// null = không giới hạn thời gian kết thúc.
  final DateTime? saleEndAt;

  // =========================================================
  // CATEGORY
  // =========================================================

  final String categoryId;

  final String categoryTitle;
  final String categorySlug;

  // =========================================================
  // STATUS
  // =========================================================

  final bool isAvailable;

  final DateTime? created;
  final DateTime? updated;

  // Khởi tạo ProductModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu sản phẩm.
  const ProductModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.image = '',
    this.description = '',
    this.deliveryTime = '',
    this.price = 0,

    // Sale
    this.salePrice = 0,
    this.isOnSale = false,
    this.saleStartAt,
    this.saleEndAt,

    this.categoryId = '',
    this.categoryTitle = 'Khác',
    this.categorySlug = 'khac',
    this.isAvailable = true,
    this.created,
    this.updated,
  });

  // =========================================================
  // SALE STATUS
  // =========================================================

  /// Kiểm tra sản phẩm có đang trong thời gian khuyến mãi
  /// và giá sale có hợp lệ hay không.
  // Đọc trạng thái có đang hoạt động khuyến mãi (hasActiveSale): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasActiveSale {
    if (!isOnSale) {
      return false;
    }

    if (price <= 0) {
      return false;
    }

    if (salePrice <= 0) {
      return false;
    }

    if (salePrice >= price) {
      return false;
    }

    final DateTime now = DateTime.now();

    // Chưa đến thời gian sale.
    if (saleStartAt != null &&
        now.isBefore(saleStartAt!)) {
      return false;
    }

    // Đã hết thời gian sale.
    if (saleEndAt != null &&
        now.isAfter(saleEndAt!)) {
      return false;
    }

    return true;
  }

  // =========================================================
  // EFFECTIVE PRICE
  // =========================================================

  /// Giá thực tế mà khách hàng phải trả.
  ///
  /// Có sale hợp lệ → salePrice.
  /// Không sale       → price.
  // Đọc hiệu lực price (effectivePrice): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get effectivePrice {
    if (hasActiveSale) {
      return salePrice;
    }

    return price;
  }

  // =========================================================
  // DISCOUNT AMOUNT
  // =========================================================

  /// Số tiền được giảm.
  // Đọc giảm giá số tiền (discountAmount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get discountAmount {
    if (!hasActiveSale) {
      return 0;
    }

    return price - salePrice;
  }

  // =========================================================
  // DISCOUNT PERCENT
  // =========================================================

  /// Phần trăm giảm giá dùng để hiển thị UI.
  ///
  /// Ví dụ:
  /// price     = 50.000
  /// salePrice = 40.000
  ///
  /// discountPercent = 20
  // Đọc giảm giá phần trăm (discountPercent): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get discountPercent {
    if (!hasActiveSale || price <= 0) {
      return 0;
    }

    return (((price - salePrice) / price) * 100)
        .round();
  }

  // =========================================================
  // FROM JSON
  // =========================================================

  // Khởi tạo ProductModel.fromJson: tạo đối tượng ProductModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory ProductModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductModel(
      id:
          json['id']?.toString() ??
          '',

      title:
          json['title']?.toString() ??
          '',

      subtitle:
          json['subtitle']?.toString() ??
          '',

      rating: _toDouble(json['rating']),

      reviewCount: _toInt(json['reviewCount']),

      image:
          json['image']?.toString() ??
          '',

      description:
          json['description']?.toString() ??
          '',

      deliveryTime:
          json['deliveryTime']?.toString() ??
          '',

      // ==============================
      // PRICE
      // ==============================

      price:
          _toDouble(
            json['price'],
          ),

      salePrice:
          _toDouble(
            json['salePrice'],
          ),

      isOnSale:
          json['isOnSale'] == true,

      saleStartAt:
          _toDateTime(
            json['saleStartAt'],
          ),

      saleEndAt:
          _toDateTime(
            json['saleEndAt'],
          ),

      // ==============================
      // CATEGORY
      // ==============================

      categoryId:
          json['category']?.toString() ??
          '',

      categoryTitle:
          json['categoryTitle']?.toString() ??
          'Khác',

      categorySlug:
          json['categorySlug']?.toString() ??
          'khac',

      // ==============================
      // STATUS
      // ==============================

      isAvailable:
          json['isAvailable'] != false,

      created:
          _toDateTime(
            json['created'],
          ),

      updated:
          _toDateTime(
            json['updated'],
          ),
    );
  }

  // =========================================================
  // TO JSON
  // =========================================================

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
  Map<String, dynamic> toJson() {
    return {
      'title':
          title,

      'subtitle':
          subtitle,

      'rating':
          rating,

      'image':
          image,

      'description':
          description,

      'deliveryTime':
          deliveryTime,

      // ==============================
      // PRICE
      // ==============================

      'price':
          price,

      'salePrice':
          salePrice,

      'isOnSale':
          isOnSale,

      'saleStartAt':
          saleStartAt?.toIso8601String(),

      'saleEndAt':
          saleEndAt?.toIso8601String(),

      // ==============================
      // CATEGORY
      // ==============================

      'category':
          categoryId,

      // ==============================
      // STATUS
      // ==============================

      'isAvailable':
          isAvailable,
    };
  }

  // =========================================================
  // COPY WITH
  // =========================================================

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  ProductModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? rating,
    int? reviewCount,
    String? image,
    String? description,
    String? deliveryTime,

    double? price,
    double? salePrice,
    bool? isOnSale,
    DateTime? saleStartAt,
    DateTime? saleEndAt,

    String? categoryId,
    String? categoryTitle,
    String? categorySlug,

    bool? isAvailable,

    DateTime? created,
    DateTime? updated,
  }) {
    return ProductModel(
      id:
          id ??
          this.id,

      title:
          title ??
          this.title,

      subtitle:
          subtitle ??
          this.subtitle,

      rating:
          rating ??
          this.rating,
      
      reviewCount: 
          reviewCount ?? 
          this.reviewCount,

      image:
          image ??
          this.image,

      description:
          description ??
          this.description,

      deliveryTime:
          deliveryTime ??
          this.deliveryTime,

      price:
          price ??
          this.price,

      salePrice:
          salePrice ??
          this.salePrice,

      isOnSale:
          isOnSale ??
          this.isOnSale,

      saleStartAt:
          saleStartAt ??
          this.saleStartAt,

      saleEndAt:
          saleEndAt ??
          this.saleEndAt,

      categoryId:
          categoryId ??
          this.categoryId,

      categoryTitle:
          categoryTitle ??
          this.categoryTitle,

      categorySlug:
          categorySlug ??
          this.categorySlug,

      isAvailable:
          isAvailable ??
          this.isAvailable,

      created:
          created ??
          this.created,

      updated:
          updated ??
          this.updated,
    );
  }

  // =========================================================
  // PARSE DOUBLE
  // =========================================================

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu sản phẩm.
  static double _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // =========================================================
  // PARSE DATETIME
  // =========================================================

  // Xử lý _toDateTime: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu sản phẩm.
  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
  // Xử lý _toInt: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu sản phẩm.
  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
