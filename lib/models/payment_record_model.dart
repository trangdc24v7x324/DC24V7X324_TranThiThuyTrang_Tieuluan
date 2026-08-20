// FILE HỌC TẬP: lib/models/payment_record_model.dart
// Vai trò: Mô hình dữ liệu thanh toán bản ghi.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp PaymentRecordModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class PaymentRecordModel {
  final String id;
  final String orderId;

  final String method;
  final double amount;

  final String status;
  final String transactionCode;

  final Map<String, dynamic> rawResponse;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Khởi tạo PaymentRecordModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu thanh toán bản ghi.
  const PaymentRecordModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    required this.transactionCode,
    this.rawResponse = const {},
    this.createdAt,
    this.updatedAt,
  });

  // Đọc trạng thái đã thanh toán (isPaid): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isPaid => status == 'paid';

  // Đọc trạng thái pending (isPending): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isPending => status == 'pending';

  // Đọc trạng thái chưa thanh toán (isUnpaid): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isUnpaid => status == 'unpaid';

  // Đọc trạng thái failed (isFailed): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isFailed => status == 'failed';

  // Đọc trạng thái văn bản (statusText): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get statusText {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Đang chờ thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'failed':
        return 'Thanh toán thất bại';
      default:
        return status;
    }
  }

  // Khởi tạo PaymentRecordModel.fromJson: tạo đối tượng PaymentRecordModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order'] ?? json['orderId'] ?? '').toString(),
      method: (json['method'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      status: (json['status'] ?? 'pending').toString(),
      transactionCode:
          (json['transactionCode'] ?? json['transaction_code'] ?? '')
              .toString(),
      rawResponse:
          json['rawResponse'] is Map
              ? Map<String, dynamic>.from(json['rawResponse'] as Map)
              : const {},
      createdAt: _toDateTime(json['created']),
      updatedAt: _toDateTime(json['updated']),
    );
  }

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu thanh toán bản ghi.
  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Xử lý _toDateTime: thực hiện phần nghiệp vụ tương ứng trong mô hình dữ liệu thanh toán bản ghi.
  static DateTime? _toDateTime(dynamic value) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }
}
