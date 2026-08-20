
import 'address_model.dart';
import 'payment_method_model.dart';

class UserProfileModel {
  final String id;
  final String avatarUrl;
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isActive;

  final List<AddressModel> addresses;
  final List<PaymentMethodModel> paymentMethods;

  const UserProfileModel({
    required this.id,
    this.avatarUrl = '',
    required this.fullName,
    this.dateOfBirth,
    this.gender = '',
    required this.email,
    this.phoneNumber = '',
    this.role = 'customer',
    this.isActive = true,
    this.addresses = const [],
    this.paymentMethods = const [],
  });

  bool get isCustomer => role == 'customer';

  bool get isManager => role == 'manager';

  String get username => fullName;

  String get passwordMasked => '******';

  factory UserProfileModel.fromJson(
    Map<String, dynamic> json, {
    String avatarUrl = '',
    List<AddressModel> addresses = const [],
    List<PaymentMethodModel> paymentMethods = const [],
  }) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      avatarUrl: avatarUrl,
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      gender: json['gender']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      isActive: json['isActive'] == true,
      addresses: addresses,
      paymentMethods: paymentMethods,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isActive': isActive,
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? avatarUrl,
    String? fullName,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? gender,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isActive,
    List<AddressModel>? addresses,
    List<PaymentMethodModel>? paymentMethods,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      dateOfBirth:
          clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}
