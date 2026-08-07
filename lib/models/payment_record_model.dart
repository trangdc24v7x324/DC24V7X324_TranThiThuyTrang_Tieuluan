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

  bool get isPaid => status == 'paid';

  bool get isPending => status == 'pending';

  bool get isUnpaid => status == 'unpaid';

  bool get isFailed => status == 'failed';

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

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }
}
