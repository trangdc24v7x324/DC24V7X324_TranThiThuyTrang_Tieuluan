
import 'order_item_model.dart';
import '../utils/delivery_location_helper.dart';

class OrderModel {
  final String id;
  final String userId;

  final String receiverName;
  final String receiverPhone;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;

  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;

  final double subtotal;
  final double deliveryFee;
  final double distanceKm;
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
    this.deliveryLatitude = 0,
    this.deliveryLongitude = 0,
    required this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.orderStatus = 'placed',
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.distanceKm = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.note = '',
    this.cancelReason = '',
    this.items = const [],
    this.created,
    this.updated,
  });

  String get status => orderStatus;

  String get address => deliveryAddress;

  DateTime get orderDate => created ?? updated ?? DateTime.now();

  bool get isPlaced => orderStatus == 'placed';

  bool get isConfirmed => orderStatus == 'confirmed';

  bool get isPreparing => orderStatus == 'preparing';

  bool get isDelivering => orderStatus == 'delivering';

  bool get isCompleted => orderStatus == 'completed';

  bool get isCancelled => orderStatus == 'cancelled';

  bool get hasDeliveryCoordinates {
    return deliveryLatitude >= -90 &&
        deliveryLatitude <= 90 &&
        deliveryLongitude >= -180 &&
        deliveryLongitude <= 180 &&
        !(deliveryLatitude == 0 && deliveryLongitude == 0);
  }

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
    final rawAddress = json['delivery_address']?.toString() ?? '';
    final location = DeliveryLocationHelper.decode(rawAddress);

    final explicitLatitude = _toDouble(
      json['delivery_latitude'] ?? json['deliveryLatitude'],
    );
    final explicitLongitude = _toDouble(
      json['delivery_longitude'] ?? json['deliveryLongitude'],
    );

    final hasExplicitCoordinateFields =
        (json.containsKey('delivery_latitude') ||
            json.containsKey('deliveryLatitude')) &&
        (json.containsKey('delivery_longitude') ||
            json.containsKey('deliveryLongitude'));

    final hasExplicitCoordinates =
        hasExplicitCoordinateFields &&
        _validCoordinates(explicitLatitude, explicitLongitude);

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      receiverName: json['receiver_name']?.toString() ?? '',
      receiverPhone: json['receiver_phone']?.toString() ?? '',
      deliveryAddress: location.address,
      deliveryLatitude:
          hasExplicitCoordinates ? explicitLatitude : location.latitude,
      deliveryLongitude:
          hasExplicitCoordinates ? explicitLongitude : location.longitude,
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      orderStatus: json['order_status']?.toString() ?? 'placed',
      subtotal: _toDouble(json['subtotal']),
      deliveryFee: _toDouble(json['delivery_fee']),
      distanceKm: _toDouble(json['distance_km']),
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
      'delivery_address': DeliveryLocationHelper.encode(
        address: deliveryAddress,
        latitude: deliveryLatitude,
        longitude: deliveryLongitude,
      ),
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'distance_km': distanceKm,
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
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    double? subtotal,
    double? deliveryFee,
    double? distanceKm,
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
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      distanceKm: distanceKm ?? this.distanceKm,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      cancelReason: cancelReason ?? this.cancelReason,
      items: items ?? this.items,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  static bool _validCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
