// FILE HỌC TẬP: lib/models/delivery_quote_model.dart
// Vai trò: Mô hình dữ liệu giao hàng báo giá.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp DeliveryQuote: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class DeliveryQuote {
  final String storeId;
  final String storeName;

  final double storeLatitude;
  final double storeLongitude;

  final double customerLatitude;
  final double customerLongitude;

  final double distanceKm;
  final double deliveryFee;
  final double deliveryRadiusKm;

  final bool isDeliverable;
  final String message;

  // Khởi tạo DeliveryQuote: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu giao hàng báo giá.
  const DeliveryQuote({
    required this.storeId,
    required this.storeName,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.distanceKm,
    required this.deliveryFee,
    required this.deliveryRadiusKm,
    required this.isDeliverable,
    required this.message,
  });

  // Xử lý totalWith: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu giao hàng báo giá.
  double totalWith(double subtotal) {
    return subtotal + deliveryFee;
  }
}
