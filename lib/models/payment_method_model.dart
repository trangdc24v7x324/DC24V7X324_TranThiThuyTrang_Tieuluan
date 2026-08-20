
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

  String get title => displayName;

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
