import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String userId;

  final String receiverName;
  final String receiverPhone;
  final String deliveryAddress;

  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;

  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double totalAmount;

  final String note;
  final String cancelReason;

  final List<OrderItemModel> items;

  final DateTime? created;
  final DateTime? updated;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.receiverName,
    required this.receiverPhone,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.orderStatus = 'placed',
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.note = '',
    this.cancelReason = '',
    this.items = const [],
    this.created,
    this.updated,
  });

  /// Giữ getter này để UI cũ đang gọi order.status vẫn chạy được.
  String get status => orderStatus;

  /// Giữ getter này để UI cũ đang gọi order.address vẫn chạy được.
  String get address => deliveryAddress;

  /// Giữ getter này để UI cũ đang gọi order.orderDate vẫn chạy được.
  DateTime get orderDate => created ?? DateTime.now();

  bool get isPlaced => orderStatus == 'placed';
  bool get isConfirmed => orderStatus == 'confirmed';
  bool get isPreparing => orderStatus == 'preparing';
  bool get isDelivering => orderStatus == 'delivering';
  bool get isCompleted => orderStatus == 'completed';
  bool get isCancelled => orderStatus == 'cancelled';

  bool get isActive {
    return orderStatus == 'placed' ||
        orderStatus == 'confirmed' ||
        orderStatus == 'preparing' ||
        orderStatus == 'delivering';
  }

  factory OrderModel.fromJson(
    Map<String, dynamic> json, {
    List<OrderItemModel> items = const [],
  }) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      receiverName: json['receiver_name']?.toString() ?? '',
      receiverPhone: json['receiver_phone']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      orderStatus: json['order_status']?.toString() ?? 'placed',
      subtotal: _toDouble(json['subtotal']),
      deliveryFee: _toDouble(json['delivery_fee']),
      discountAmount: _toDouble(json['discount_amount']),
      totalAmount: _toDouble(json['total_amount']),
      note: json['note']?.toString() ?? '',
      cancelReason: json['cancel_reason']?.toString() ?? '',
      items: items,
      created: DateTime.tryParse(json['created']?.toString() ?? ''),
      updated: DateTime.tryParse(json['updated']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'note': note,
      'cancel_reason': cancelReason,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? receiverName,
    String? receiverPhone,
    String? deliveryAddress,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    double? subtotal,
    double? deliveryFee,
    double? discountAmount,
    double? totalAmount,
    String? note,
    String? cancelReason,
    List<OrderItemModel>? items,
    DateTime? created,
    DateTime? updated,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      cancelReason: cancelReason ?? this.cancelReason,
      items: items ?? this.items,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
