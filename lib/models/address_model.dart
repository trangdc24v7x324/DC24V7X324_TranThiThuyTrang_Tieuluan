// FILE HỌC TẬP: lib/models/address_model.dart
// Vai trò: Mô hình dữ liệu địa chỉ.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp AddressModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class AddressModel {
  final String id;
  final String userId;

  final String label;
  final String receiverName;
  final String phoneNumber;
  final String addressLine;
  final String note;

  final double latitude;
  final double longitude;

  final bool isDefault;

  // Khởi tạo AddressModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu địa chỉ.
  const AddressModel({
    this.id = '',
    this.userId = '',
    this.label = 'Nhà',
    required this.receiverName,
    required this.phoneNumber,
    required this.addressLine,
    this.note = '',
    this.latitude = 0,
    this.longitude = 0,
    this.isDefault = false,
  });

  // Đọc trạng thái có tọa độ (hasCoordinates): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  // Khởi tạo AddressModel.fromJson: tạo đối tượng AddressModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user'] ?? json['userId'] ?? '').toString(),
      label: (json['label'] ?? 'Nhà').toString().trim(),
      receiverName:
          (json['receiverName'] ?? json['receiver_name'] ?? '').toString(),
      phoneNumber:
          (json['phoneNumber'] ?? json['phone_number'] ?? '').toString(),
      addressLine:
          (json['addressLine'] ??
                  json['address_line'] ??
                  json['formattedAddress'] ??
                  '')
              .toString(),
      note: (json['note'] ?? '').toString(),
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
      isDefault: _toBool(json['isDefault'] ?? json['is_default']),
    );
  }

  // Khởi tạo AddressModel.fromRecord: tạo đối tượng AddressModel bằng constructor fromRecord từ dữ liệu đầu vào.
  factory AddressModel.fromRecord(dynamic record) {
    return AddressModel.fromJson({
      'id': record.id,
      ...record.data,
      'created': record.created,
      'updated': record.updated,
    });
  }

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'label': label.trim(),
      'receiverName': receiverName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'addressLine': addressLine.trim(),
      'note': note.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  // Xử lý toPocketBaseBody: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu địa chỉ.
  Map<String, dynamic> toPocketBaseBody({String? userIdOverride}) {
    final body = <String, dynamic>{
      // Giữ đúng schema camelCase đang dùng trong project.
      'label': label.trim(),
      'receiverName': receiverName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'addressLine': addressLine.trim(),
      'note': note.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };

    final resolvedUserId = (userIdOverride ?? userId).trim();

    if (resolvedUserId.isNotEmpty) {
      body['user'] = resolvedUserId;
    }

    return body;
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? receiverName,
    String? phoneNumber,
    String? addressLine,
    String? note,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine: addressLine ?? this.addressLine,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Xóa tọa độ (clearCoordinates): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  AddressModel clearCoordinates() {
    return copyWith(latitude: 0, longitude: 0);
  }

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu địa chỉ.
  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Xử lý _toBool: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu địa chỉ.
  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1' || text == 'yes';
  }
}
