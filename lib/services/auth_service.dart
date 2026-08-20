// FILE HỌC TẬP: lib/services/auth_service.dart
// Vai trò: Service nghiệp vụ xác thực.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:pocketbase/pocketbase.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';

// Lớp AuthService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class AuthService {
  // Đọc pb (_pb): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  PocketBase get _pb => getPocketBase();

  // =========================================================
  // REGISTER
  // =========================================================

  // Xử lý register: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ xác thực.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();

    final String normalizedFullName = fullName.trim();

    final String normalizedPhone = phoneNumber.trim();

    // =======================================================
    // VALIDATION
    // =======================================================

    if (normalizedEmail.isEmpty) {
      throw Exception('Email không được để trống.');
    }

    if (password.isEmpty) {
      throw Exception('Mật khẩu không được để trống.');
    }

    if (normalizedFullName.isEmpty) {
      throw Exception('Họ tên không được để trống.');
    }

    try {
      await _pb
          .collection('users')
          .create(
            body: {
              'email': normalizedEmail,

              'password': password,

              'passwordConfirm': password,

              'fullName': normalizedFullName,

              'phoneNumber': normalizedPhone,

              // Mobile chỉ đăng ký tài khoản Customer.
              'role': 'customer',

              'isActive': true,
            },
          );
    } catch (error) {
      rethrow;
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  // Nghiệp vụ login: truy vấn/cập nhật PocketBase và trả dữ liệu cho service nghiệp vụ xác thực.
  Future<void> login({required String email, required String password}) async {
    final String normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw Exception('Vui lòng nhập email.');
    }

    if (password.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu.');
    }

    try {
      // =====================================================
      // AUTHENTICATE
      // =====================================================

      await _pb.collection('users').authWithPassword(normalizedEmail, password);

      // Phiên bản PocketBase hiện tại
      // của dự án sử dụng authStore.model.
      final model = _pb.authStore.model;

      if (model == null) {
        _pb.authStore.clear();

        throw Exception('Không lấy được thông tin tài khoản.');
      }

      final Map<String, dynamic> data = model.toJson();

      // =====================================================
      // CHECK ACTIVE
      // =====================================================

      final bool active = data['isActive'] != false;

      if (!active) {
        _pb.authStore.clear();

        throw Exception('Tài khoản của bạn đã bị khóa.');
      }

      // =====================================================
      // CHECK ROLE
      // =====================================================

      final String role = (data['role'] ?? '').toString().trim().toLowerCase();

      if (role != 'customer' && role != 'manager') {
        _pb.authStore.clear();

        throw Exception('Tài khoản chưa được phân quyền hợp lệ.');
      }
    } catch (error) {
      rethrow;
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  // Xử lý logout: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ xác thực.
  Future<void> logout() async {
    _pb.authStore.clear();
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  // Xử lý changePassword: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ xác thực.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!_pb.authStore.isValid) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (oldPassword.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu hiện tại.');
    }

    if (newPassword.isEmpty) {
      throw Exception('Vui lòng nhập mật khẩu mới.');
    }

    final model = _pb.authStore.model;

    if (model == null || model.id.isEmpty) {
      throw Exception('Không tìm thấy tài khoản hiện tại.');
    }

    try {
      await _pb
          .collection('users')
          .update(
            model.id,
            body: {
              'oldPassword': oldPassword,

              'password': newPassword,

              'passwordConfirm': newPassword,
            },
          );

      // Refresh lại token và thông tin user.
      await _pb.collection('users').authRefresh();
    } catch (error) {
      throw Exception(
        'Đổi mật khẩu thất bại. '
        'Vui lòng kiểm tra mật khẩu hiện tại.',
      );
    }
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  // Nghiệp vụ requestPasswordReset: truy vấn/cập nhật PocketBase và trả dữ liệu cho service nghiệp vụ xác thực.
  Future<void> requestPasswordReset({required String email}) async {
    final String normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw Exception('Vui lòng nhập email.');
    }

    try {
      await _pb.collection('users').requestPasswordReset(normalizedEmail);
    } catch (error) {
      rethrow;
    }
  }

  // =========================================================
  // REFRESH CURRENT USER
  // =========================================================

  // Làm mới hiện tại người dùng (refreshCurrentUser): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<Map<String, dynamic>?> refreshCurrentUser() async {
    if (!_pb.authStore.isValid) {
      return null;
    }

    try {
      await _pb.collection('users').authRefresh();

      final model = _pb.authStore.model;

      if (model == null) {
        return null;
      }

      return {'id': model.id, ...model.toJson()};
    } catch (error) {
      return null;
    }
  }

  // =========================================================
  // AUTH STATUS
  // =========================================================

  // Đọc trạng thái logged in (isLoggedIn): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoggedIn => _pb.authStore.isValid;

  // Đọc hiện tại người dùng mã (currentUserId): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get currentUserId => _pb.authStore.model?.id;

  // =========================================================
  // CURRENT USER
  // =========================================================

  // Đọc hiện tại người dùng (currentUser): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  Map<String, dynamic>? get currentUser {
    final model = _pb.authStore.model;

    if (model == null) {
      return null;
    }

    return {'id': model.id, ...model.toJson()};
  }

  // =========================================================
  // CURRENT USER ROLE
  // =========================================================

  // Đọc hiện tại người dùng role (currentUserRole): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get currentUserRole {
    final model = _pb.authStore.model;

    if (model == null) {
      return '';
    }

    final Map<String, dynamic> data = model.toJson();

    return (data['role'] ?? '').toString().trim().toLowerCase();
  }

  // =========================================================
  // CURRENT USER FULL NAME
  // =========================================================

  // Đọc hiện tại người dùng đầy đủ name (currentUserFullName): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get currentUserFullName {
    final model = _pb.authStore.model;

    if (model == null) {
      return '';
    }

    final Map<String, dynamic> data = model.toJson();

    return (data['fullName'] ?? '').toString().trim();
  }

  // =========================================================
  // CURRENT USER EMAIL
  // =========================================================

  // Đọc hiện tại người dùng email (currentUserEmail): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get currentUserEmail {
    final model = _pb.authStore.model;

    if (model == null) {
      return '';
    }

    final Map<String, dynamic> data = model.toJson();

    return (data['email'] ?? '').toString().trim();
  }

  // =========================================================
  // CURRENT USER PHONE
  // =========================================================

  // Đọc hiện tại người dùng số điện thoại number (currentUserPhoneNumber): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay
  // đổi state.
  String get currentUserPhoneNumber {
    final model = _pb.authStore.model;

    if (model == null) {
      return '';
    }

    final Map<String, dynamic> data = model.toJson();

    return (data['phoneNumber'] ?? '').toString().trim();
  }

  // =========================================================
  // PERMISSION HELPERS
  // =========================================================

  // Đọc trạng thái quản lý (isManager): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isManager => currentUserRole == 'manager';

  // Đọc trạng thái khách hàng (isCustomer): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isCustomer => currentUserRole == 'customer';

  // =========================================================
  // ACCOUNT STATUS
  // =========================================================

  // Đọc trạng thái đang hoạt động (isActive): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isActive {
    final model = _pb.authStore.model;

    if (model == null) {
      return false;
    }

    final Map<String, dynamic> data = model.toJson();

    return data['isActive'] != false;
  }
}
