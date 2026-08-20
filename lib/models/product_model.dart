
class ProductModel {
  final String id;

  final String title;
  final String subtitle;

  final double rating;
  final int reviewCount;

  final String image;
  final String description;
  final String deliveryTime;

  final double price;

  final double salePrice;

  final bool isOnSale;

  final DateTime? saleStartAt;

  final DateTime? saleEndAt;

  final String categoryId;

  final String categoryTitle;
  final String categorySlug;

  final bool isAvailable;

  final DateTime? created;
  final DateTime? updated;

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

    if (saleStartAt != null &&
        now.isBefore(saleStartAt!)) {
      return false;
    }

    if (saleEndAt != null &&
        now.isAfter(saleEndAt!)) {
      return false;
    }

    return true;
  }

  double get effectivePrice {
    if (hasActiveSale) {
      return salePrice;
    }

    return price;
  }

  double get discountAmount {
    if (!hasActiveSale) {
      return 0;
    }

    return price - salePrice;
  }

  int get discountPercent {
    if (!hasActiveSale || price <= 0) {
      return 0;
    }

    return (((price - salePrice) / price) * 100)
        .round();
  }

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

      categoryId:
          json['category']?.toString() ??
          '',

      categoryTitle:
          json['categoryTitle']?.toString() ??
          'Khác',

      categorySlug:
          json['categorySlug']?.toString() ??
          'khac',

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

      'category':
          categoryId,

      'isAvailable':
          isAvailable,
    };
  }

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

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
