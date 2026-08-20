// FILE HỌC TẬP: lib/models/payment_method_model.dart
// Vai trò: Mô hình dữ liệu phương thức thanh toán.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp PaymentMethodModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class PaymentMethodModel {
  final String id;
  final String userId;
  final String type;
  final String displayName;
  final String accountNumber;
  final String provider;
  final bool isDefault;
  final DateTime? created;
  final DateTime? updated;

  // Khởi tạo PaymentMethodModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu phương thức thanh toán.
  const PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.displayName,
    this.accountNumber = '',
    this.provider = '',
    this.isDefault = false,
    this.created,
    this.updated,
  });

  // Đọc title (title): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get title => displayName;

  // Đọc subtitle (subtitle): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get subtitle {
    if (provider.isNotEmpty && accountNumber.isNotEmpty) {
      return '$provider - $accountNumber';
    }

    if (provider.isNotEmpty) return provider;
    if (accountNumber.isNotEmpty) return accountNumber;

    switch (type) {
      case 'cash':
        return 'Thanh toán khi nhận hàng';
      case 'momo':
        return 'Ví điện tử MoMo';
      case 'visa':
        return 'Thẻ Visa/Mastercard';
      case 'bank':
        return 'Chuyển khoản ngân hàng';
      default:
        return '';
    }
  }

  // Khởi tạo PaymentMethodModel.fromJson: tạo đối tượng PaymentMethodModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      created: DateTime.tryParse(json['created']?.toString() ?? ''),
      updated: DateTime.tryParse(json['updated']?.toString() ?? ''),
    );
  }

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'type': type,
      'displayName': displayName,
      'accountNumber': accountNumber,
      'provider': provider,
      'isDefault': isDefault,
    };
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? displayName,
    String? accountNumber,
    String? provider,
    bool? isDefault,
    DateTime? created,
    DateTime? updated,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      accountNumber: accountNumber ?? this.accountNumber,
      provider: provider ?? this.provider,
      isDefault: isDefault ?? this.isDefault,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
