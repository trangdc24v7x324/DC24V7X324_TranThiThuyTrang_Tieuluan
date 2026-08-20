// FILE HỌC TẬP: lib/models/order_model.dart
// Vai trò: Mô hình dữ liệu đơn hàng.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

import 'order_item_model.dart';
import '../utils/delivery_location_helper.dart';

// Lớp OrderModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
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

  // Khởi tạo OrderModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu đơn hàng.
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

  // Trạng thái đơn: cung cấp alias để tương thích giao diện cũ.
  // Đọc trạng thái (status): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get status => orderStatus;

  // Địa chỉ giao hàng: cung cấp alias để tương thích giao diện cũ.
  // Đọc địa chỉ (address): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get address => deliveryAddress;

  // Ngày đặt hàng: dùng created hoặc thời điểm hiện tại nếu dữ liệu cũ bị thiếu.
  // Đọc đơn hàng ngày (orderDate): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  DateTime get orderDate => created ?? updated ?? DateTime.now();

  // Đọc trạng thái placed (isPlaced): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isPlaced => orderStatus == 'placed';
  // Đọc trạng thái confirmed (isConfirmed): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isConfirmed => orderStatus == 'confirmed';
  // Đọc trạng thái preparing (isPreparing): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isPreparing => orderStatus == 'preparing';
  // Đọc trạng thái delivering (isDelivering): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isDelivering => orderStatus == 'delivering';
  // Đọc trạng thái hoàn thành (isCompleted): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isCompleted => orderStatus == 'completed';
  // Đọc trạng thái cancelled (isCancelled): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isCancelled => orderStatus == 'cancelled';

  // Đọc trạng thái có giao hàng tọa độ (hasDeliveryCoordinates): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasDeliveryCoordinates {
    return deliveryLatitude >= -90 &&
        deliveryLatitude <= 90 &&
        deliveryLongitude >= -180 &&
        deliveryLongitude <= 180 &&
        !(deliveryLatitude == 0 && deliveryLongitude == 0);
  }

  // Đọc trạng thái đang hoạt động (isActive): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isActive {
    return orderStatus == 'placed' ||
        orderStatus == 'confirmed' ||
        orderStatus == 'preparing' ||
        orderStatus == 'delivering';
  }

  // Đọc đơn hàng: tách địa chỉ hiển thị khỏi metadata GPS dùng để chỉ đường.
  // Khởi tạo OrderModel.fromJson: tạo đối tượng OrderModel bằng constructor fromJson từ dữ liệu đầu vào.
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

  // Xuất đơn hàng: giữ metadata GPS trong delivery_address để tương thích PocketBase hiện tại.
  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
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

  // Sao chép đơn hàng: cập nhật cục bộ mà không làm mất dữ liệu hiện có.
  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
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

  // Xử lý _validCoordinates: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu đơn hàng.
  static bool _validCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu đơn hàng.
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
