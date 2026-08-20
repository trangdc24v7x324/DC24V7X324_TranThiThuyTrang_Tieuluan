// FILE HỌC TẬP: lib/providers/profile_provider.dart
// Vai trò: Provider quản lý trạng thái hồ sơ.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'dart:io';

import 'package:project_trangdc24v7x324/models/address_model.dart';
import 'package:project_trangdc24v7x324/models/payment_method_model.dart';
import 'package:project_trangdc24v7x324/models/user_profile_model.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/services/auth_service.dart';
import 'package:project_trangdc24v7x324/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/notification_provider.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';

// Lớp ProfileProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  final AuthService _authService = AuthService();

  final ImagePicker _picker = ImagePicker();

  UserProfileModel? _profile;

  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _isSavingGeneralInfo = false;
  bool _isSavingAddresses = false;
  bool _isSavingPaymentMethods = false;
  bool _isUploadingAvatar = false;
  Future<bool>? _profileLoadFuture;

  bool _isEditingGeneralInfo = false;

  bool _isEditingAddress = false;

  bool _isEditingPaymentMethods = false;

  String? _errorMessage;

  // Đọc hồ sơ (profile): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  UserProfileModel? get profile => _profile;

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;

  // Đọc trạng thái đang đổi mật khẩu (isChangingPassword): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isChangingPassword => _isChangingPassword;
  // Đọc trạng thái đang lưu thông tin cá nhân (isSavingGeneralInfo): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi
  // state.
  bool get isSavingGeneralInfo => _isSavingGeneralInfo;
  // Đọc trạng thái đang lưu địa chỉ (isSavingAddresses): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isSavingAddresses => _isSavingAddresses;
  // Đọc trạng thái đang lưu phương thức thanh toán (isSavingPaymentMethods): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay
  // đổi state.
  bool get isSavingPaymentMethods => _isSavingPaymentMethods;
  // Đọc trạng thái đang tải ảnh đại diện lên (isUploadingAvatar): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isUploadingAvatar => _isUploadingAvatar;
  // Đọc trạng thái đang xử lý (isBusy): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isBusy =>
      _isLoading ||
      _isChangingPassword ||
      _isSavingGeneralInfo ||
      _isSavingAddresses ||
      _isSavingPaymentMethods ||
      _isUploadingAvatar;

  // Đọc trạng thái đang chỉnh sửa thông tin cá nhân (isEditingGeneralInfo): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay
  // đổi state.
  bool get isEditingGeneralInfo => _isEditingGeneralInfo;

  // Đọc trạng thái đang chỉnh sửa địa chỉ (isEditingAddress): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isEditingAddress => _isEditingAddress;

  // Đọc trạng thái đang chỉnh sửa phương thức thanh toán (isEditingPaymentMethods): trả giá trị hiện tại cho UI/nghiệp vụ mà
  // không thay đổi state.
  bool get isEditingPaymentMethods => _isEditingPaymentMethods;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc trạng thái đã có hồ sơ (hasProfile): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasProfile => _profile != null;

  // Đọc địa chỉ (addresses): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<AddressModel> get addresses =>
      _profile?.addresses ?? const <AddressModel>[];

  // Đọc phương thức thanh toán (paymentMethods): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<PaymentMethodModel> get paymentMethods {
    return _profile?.paymentMethods ?? const <PaymentMethodModel>[];
  }

  // Đọc địa chỉ mặc định (defaultAddress): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  AddressModel? get defaultAddress {
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  // Đọc phương thức thanh toán mặc định (defaultPaymentMethod): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  PaymentMethodModel? get defaultPaymentMethod {
    try {
      return paymentMethods.firstWhere((method) => method.isDefault);
    } catch (_) {
      return paymentMethods.isNotEmpty ? paymentMethods.first : null;
    }
  }

  // =========================================================
  // EDIT STATE
  // =========================================================

  // Bật/tắt địa chỉ chỉnh sửa (toggleAddressEdit): đảo trạng thái hiện tại theo thao tác người dùng.
  void toggleAddressEdit() {
    _isEditingAddress = !_isEditingAddress;

    notifyListeners();
  }

  // Bật/tắt chung thông tin chỉnh sửa (toggleGeneralInfoEdit): đảo trạng thái hiện tại theo thao tác người dùng.
  void toggleGeneralInfoEdit() {
    _isEditingGeneralInfo = !_isEditingGeneralInfo;

    notifyListeners();
  }

  // Bật/tắt thanh toán phương thức chỉnh sửa (togglePaymentMethodsEdit): đảo trạng thái hiện tại theo thao tác người dùng.
  void togglePaymentMethodsEdit() {
    _isEditingPaymentMethods = !_isEditingPaymentMethods;

    notifyListeners();
  }

  // =========================================================
  // LOAD
  // =========================================================

  // Tải hồ sơ (loadProfile): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<bool> loadProfile({bool forceReload = false}) {
    if (_profile != null && !forceReload) {
      return Future<bool>.value(true);
    }

    final running = _profileLoadFuture;
    if (running != null) {
      return running;
    }

    final future = _loadProfileInternal();
    _profileLoadFuture = future;

    return future.whenComplete(() {
      if (identical(_profileLoadFuture, future)) {
        _profileLoadFuture = null;
      }
    });
  }

  // Tải hồ sơ: chống gọi chồng nhiều request cùng thời điểm.
  // Tải hồ sơ internal (_loadProfileInternal): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<bool> _loadProfileInternal() async {
    if (!_authService.isLoggedIn) {
      _profile = null;
      _isLoading = false;
      _errorMessage = 'Chưa đăng nhập';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _profile = await _profileService.fetchProfile();
      return true;
    } catch (error) {
      _setError('Không thể tải thông tin tài khoản');
      debugPrint('PROFILE ERROR: $error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Làm mới hồ sơ (refreshProfile): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<bool> refreshProfile() {
    return loadProfile(forceReload: true);
  }

  // =========================================================
  // GENERAL INFO
  // =========================================================

  // Cập nhật thông tin cá nhân (updateGeneralInfo): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<bool> updateGeneralInfo({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required DateTime? dateOfBirth,
  }) async {
    final current = _profile;
    if (current == null || _isSavingGeneralInfo) return false;

    _isSavingGeneralInfo = true;
    _clearError();
    notifyListeners();

    try {
      await _profileService.updateGeneralInfo(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );

      // Cập nhật local state trực tiếp, không fetch lại avatar/address/payment.
      _profile = current.copyWith(
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        gender: gender.trim(),
        dateOfBirth: dateOfBirth,
        clearDateOfBirth: dateOfBirth == null,
      );
      _isEditingGeneralInfo = false;
      notifyListeners();
      return true;
    } catch (error) {
      _setError('Cập nhật thông tin thất bại');
      debugPrint('updateGeneralInfo error: $error');
      return false;
    } finally {
      _isSavingGeneralInfo = false;
      notifyListeners();
    }
  }

  // Cập nhật địa chỉ (updateAddresses): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<bool> updateAddresses(List<AddressModel> newAddresses) async {
    if (_profile == null || _isSavingAddresses) return false;

    _isSavingAddresses = true;
    _clearError();
    notifyListeners();

    try {
      final freshAddresses = await _profileService.updateAddresses(newAddresses);
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(addresses: freshAddresses);
      }
      _isEditingAddress = false;
      return true;
    } catch (error) {
      _setError('Cập nhật địa chỉ thất bại');
      debugPrint('updateAddresses error: $error');
      return false;
    } finally {
      _isSavingAddresses = false;
      notifyListeners();
    }
  }

  // Cập nhật phương thức thanh toán (updatePaymentMethods): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<bool> updatePaymentMethods(
    List<PaymentMethodModel> updatedMethods,
  ) async {
    if (_profile == null || _isSavingPaymentMethods) return false;

    _isSavingPaymentMethods = true;
    _clearError();
    notifyListeners();

    try {
      final freshMethods = await _profileService.updatePaymentMethods(
        updatedMethods,
      );
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(paymentMethods: freshMethods);
      }
      _isEditingPaymentMethods = false;
      return true;
    } catch (error) {
      _setError('Cập nhật phương thức thanh toán thất bại');
      debugPrint('updatePaymentMethods error: $error');
      return false;
    } finally {
      _isSavingPaymentMethods = false;
      notifyListeners();
    }
  }

  // Cập nhật ảnh đại diện (updateAvatar): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<bool> updateAvatar(File file) async {
    if (_isUploadingAvatar) return false;

    _isUploadingAvatar = true;
    _clearError();
    notifyListeners();

    try {
      final avatarUrl = await _profileService.updateAvatar(file);
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(avatarUrl: avatarUrl);
      }
      return true;
    } catch (error) {
      _setError('Cập nhật ảnh đại diện thất bại');
      debugPrint('updateAvatar error: $error');
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  // Chọn and update ảnh đại diện (pickAndUpdateAvatar): mở công cụ chọn phù hợp và ghi kết quả vào state.
  Future<bool> pickAndUpdateAvatar() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return false;
      }

      return updateAvatar(File(pickedFile.path));
    } catch (e) {
      _setError('Không thể chọn ảnh');

      debugPrint('pickAndUpdateAvatar error: $e');

      return false;
    }
  }

  // =========================================================
  // PASSWORD
  // =========================================================

  // Xử lý changePassword: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái hồ sơ.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final oldPass = oldPassword.trim();

    final newPass = newPassword.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ mật khẩu');
    }

    if (newPass.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự');
    }

    if (oldPass == newPass) {
      throw Exception('Mật khẩu mới không được trùng mật khẩu cũ');
    }

    _isChangingPassword = true;

    _clearError();
    notifyListeners();

    try {
      await _authService.changePassword(
        oldPassword: oldPass,
        newPassword: newPass,
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isChangingPassword = false;

      notifyListeners();
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  // Xử lý logout: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái hồ sơ.
  Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;

    // Lấy reference trước khi await để không truy cập context sau khi route đổi.
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final chatProvider = context.read<ChatProvider>();

    _setLoading(true);
    _clearError();

    try {
      // Chờ các thao tác giỏ hàng đang ghi PocketBase hoàn tất.
      // Sau đó mới xóa phiên đăng nhập để tránh request cũ thất bại giữa chừng.
      await cartProvider.waitForPendingOperations();

      // Hủy realtime trước khi xóa authStore.
      try {
        await chatProvider.unsubscribe();
      } catch (e) {
        debugPrint('Chat unsubscribe khi logout lỗi: $e');
      }

      await _authService.logout();

      // Chỉ xóa state/cache local, không xóa dữ liệu thật trên server.
      cartProvider.resetCart();
      orderProvider.clearOrders();
      notificationProvider.clearNotifications();
      chatProvider.clearAll();

      _resetProfileState();
      notifyListeners();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));

      debugPrint('logout error: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Đăng xuất thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật state (_resetProfileState): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  void _resetProfileState() {
    _profile = null;
    _isLoading = false;
    _isChangingPassword = false;
    _isSavingGeneralInfo = false;
    _isSavingAddresses = false;
    _isSavingPaymentMethods = false;
    _isUploadingAvatar = false;
    _profileLoadFuture = null;
    _isEditingGeneralInfo = false;
    _isEditingAddress = false;
    _isEditingPaymentMethods = false;
    _errorMessage = null;
  }

  // Xóa hồ sơ (clearProfile): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearProfile() {
    _resetProfileState();
    notifyListeners();
  }

  // =========================================================
  // INTERNAL
  // =========================================================

  // Cập nhật đang tải (_setLoading): gán state nội bộ và thông báo lại cho UI khi cần.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Cập nhật error (_setError): gán state nội bộ và thông báo lại cho UI khi cần.
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Xóa error (_clearError): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void _clearError() {
    _errorMessage = null;
  }
}
