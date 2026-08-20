// FILE HỌC TẬP: lib/models/user_profile_model.dart
// Vai trò: Mô hình dữ liệu hồ sơ người dùng.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

import 'address_model.dart';
import 'payment_method_model.dart';

// Lớp UserProfileModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
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

  // Khởi tạo UserProfileModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu hồ sơ người dùng.
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

  // Đọc trạng thái khách hàng (isCustomer): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isCustomer => role == 'customer';
  // Đọc trạng thái quản lý (isManager): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isManager => role == 'manager';

  // Đọc username (username): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get username => fullName;
  // Đọc mật khẩu masked (passwordMasked): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get passwordMasked => '******';

  // Khởi tạo UserProfileModel.fromJson: tạo đối tượng UserProfileModel bằng constructor fromJson từ dữ liệu đầu vào.
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

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
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

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
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
