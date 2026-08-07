import 'package:pocketbase/pocketbase.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';

class AuthService {
  PocketBase get _pb => getPocketBase();

  // =========================================================
  // REGISTER
  // =========================================================

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

  Future<void> logout() async {
    _pb.authStore.clear();
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

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

  bool get isLoggedIn => _pb.authStore.isValid;

  String? get currentUserId => _pb.authStore.model?.id;

  // =========================================================
  // CURRENT USER
  // =========================================================

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

  bool get isManager => currentUserRole == 'manager';

  bool get isCustomer => currentUserRole == 'customer';

  // =========================================================
  // ACCOUNT STATUS
  // =========================================================

  bool get isActive {
    final model = _pb.authStore.model;

    if (model == null) {
      return false;
    }

    final Map<String, dynamic> data = model.toJson();

    return data['isActive'] != false;
  }
}
