
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

  UserProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;

  bool get isChangingPassword => _isChangingPassword;

  bool get isSavingGeneralInfo => _isSavingGeneralInfo;

  bool get isSavingAddresses => _isSavingAddresses;

  bool get isSavingPaymentMethods => _isSavingPaymentMethods;

  bool get isUploadingAvatar => _isUploadingAvatar;

  bool get isBusy =>
      _isLoading ||
      _isChangingPassword ||
      _isSavingGeneralInfo ||
      _isSavingAddresses ||
      _isSavingPaymentMethods ||
      _isUploadingAvatar;

  bool get isEditingGeneralInfo => _isEditingGeneralInfo;

  bool get isEditingAddress => _isEditingAddress;

  bool get isEditingPaymentMethods => _isEditingPaymentMethods;

  String? get errorMessage => _errorMessage;

  bool get hasProfile => _profile != null;

  List<AddressModel> get addresses =>
      _profile?.addresses ?? const <AddressModel>[];

  List<PaymentMethodModel> get paymentMethods {
    return _profile?.paymentMethods ?? const <PaymentMethodModel>[];
  }

  AddressModel? get defaultAddress {
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  PaymentMethodModel? get defaultPaymentMethod {
    try {
      return paymentMethods.firstWhere((method) => method.isDefault);
    } catch (_) {
      return paymentMethods.isNotEmpty ? paymentMethods.first : null;
    }
  }

  void toggleAddressEdit() {
    _isEditingAddress = !_isEditingAddress;

    notifyListeners();
  }

  void toggleGeneralInfoEdit() {
    _isEditingGeneralInfo = !_isEditingGeneralInfo;

    notifyListeners();
  }

  void togglePaymentMethodsEdit() {
    _isEditingPaymentMethods = !_isEditingPaymentMethods;

    notifyListeners();
  }

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

  Future<bool> refreshProfile() {
    return loadProfile(forceReload: true);
  }

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

  Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;

    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final chatProvider = context.read<ChatProvider>();

    _setLoading(true);
    _clearError();

    try {

      await cartProvider.waitForPendingOperations();

      try {
        await chatProvider.unsubscribe();
      } catch (e) {
        debugPrint('Chat unsubscribe khi logout lỗi: $e');
      }

      await _authService.logout();

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

  void clearProfile() {
    _resetProfileState();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
