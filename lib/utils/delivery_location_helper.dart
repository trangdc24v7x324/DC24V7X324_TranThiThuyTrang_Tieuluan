// FILE HỌC TẬP: lib/utils/delivery_location_helper.dart
// Vai trò: Tiện ích hỗ trợ vị trí giao hàng.
// Luồng sử dụng: Cung cấp hàm thuần để chuẩn hóa/biến đổi dữ liệu dùng ở nhiều lớp.

// Lớp DeliveryLocationData: thành phần phục vụ tiện ích hỗ trợ vị trí giao hàng.
class DeliveryLocationData {
  final String address;
  final double latitude;
  final double longitude;

  // Khởi tạo DeliveryLocationData: nhận các tham số cần thiết để tạo đối tượng cho tiện ích hỗ trợ vị trí giao hàng.
  const DeliveryLocationData({
    required this.address,
    this.latitude = 0,
    this.longitude = 0,
  });

  // Đọc trạng thái có tọa độ (hasCoordinates): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}

// Lớp DeliveryLocationHelper: thành phần phục vụ tiện ích hỗ trợ vị trí giao hàng.
class DeliveryLocationHelper {
  static final RegExp _metadataPattern = RegExp(
    r'\[\[GPS:([+-]?(?:\d+\.?\d*|\.\d+)),([+-]?(?:\d+\.?\d*|\.\d+))\]\]',
    caseSensitive: false,
  );

  static final RegExp _legacyGpsPattern = RegExp(
    r'^Vị trí GPS\s+([+-]?(?:\d+\.?\d*|\.\d+))\s*,\s*([+-]?(?:\d+\.?\d*|\.\d+))$',
    caseSensitive: false,
  );

  // Lưu vị trí giao hàng: giữ địa chỉ dễ đọc và gắn tọa độ ẩn để tương thích schema orders hiện tại.
  // Xử lý encode: thực hiện phần nghiệp vụ tương ứng trong tiện ích hỗ trợ vị trí giao hàng.
  static String encode({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final cleanedAddress = displayAddress(address);

    if (!_isValidCoordinate(latitude, longitude)) {
      return cleanedAddress;
    }

    final visibleAddress =
        cleanedAddress.isEmpty ? 'Vị trí giao hàng đã chọn' : cleanedAddress;

    return '$visibleAddress\n'
        '[[GPS:${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}]]';
  }

  // Đọc vị trí giao hàng: hỗ trợ đơn mới có metadata và đơn cũ lưu trực tiếp chuỗi GPS.
  // Xử lý decode: thực hiện phần nghiệp vụ tương ứng trong tiện ích hỗ trợ vị trí giao hàng.
  static DeliveryLocationData decode(String rawValue) {
    final raw = rawValue.trim();

    if (raw.isEmpty) {
      return const DeliveryLocationData(address: '');
    }

    final metadataMatch = _metadataPattern.firstMatch(raw);

    if (metadataMatch != null) {
      final latitude = double.tryParse(metadataMatch.group(1) ?? '') ?? 0;
      final longitude = double.tryParse(metadataMatch.group(2) ?? '') ?? 0;
      final address = raw.replaceAll(_metadataPattern, '').trim();

      return DeliveryLocationData(
        address: address.isEmpty ? 'Vị trí giao hàng đã chọn' : address,
        latitude: latitude,
        longitude: longitude,
      );
    }

    final legacyMatch = _legacyGpsPattern.firstMatch(raw);

    if (legacyMatch != null) {
      return DeliveryLocationData(
        address: 'Vị trí giao hàng đã chọn',
        latitude: double.tryParse(legacyMatch.group(1) ?? '') ?? 0,
        longitude: double.tryParse(legacyMatch.group(2) ?? '') ?? 0,
      );
    }

    return DeliveryLocationData(address: raw);
  }

  // Hiển thị địa chỉ: loại metadata tọa độ khỏi nội dung người dùng nhìn thấy.
  // Xử lý displayAddress: thực hiện phần nghiệp vụ tương ứng trong tiện ích hỗ trợ vị trí giao hàng.
  static String displayAddress(String rawValue) {
    return decode(rawValue).address;
  }

  // Kiểm tra điều kiện (_isValidCoordinate): đánh giá trạng thái hợp lệ coordinate và trả kết quả cho lớp gọi.
  static bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}
