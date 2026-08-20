// FILE HỌC TẬP: lib/providers/notification_provider.dart
// Vai trò: Provider quản lý trạng thái thông báo.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/app_notification_model.dart';
import 'package:project_trangdc24v7x324/services/notification_service.dart';

// Lớp NotificationProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  final List<AppNotificationModel> _notifications = [];

  bool _isLoading = false;
  bool _isCreating = false;

  String? _errorMessage;

  // Đọc thông báo (notifications): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<AppNotificationModel> get notifications {
    return List.unmodifiable(_notifications);
  }

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;

  // Đọc trạng thái creating (isCreating): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isCreating => _isCreating;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc số thông báo chưa đọc (unreadCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  // Đọc trạng thái có chưa đọc (hasUnread): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasUnread => unreadCount > 0;

  // Đọc chưa đọc thông báo (unreadNotifications): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<AppNotificationModel> get unreadNotifications {
    return _notifications.where((item) => !item.isRead).toList();
  }

  // Đọc đã đọc thông báo (readNotifications): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<AppNotificationModel> get readNotifications {
    return _notifications.where((item) => item.isRead).toList();
  }

  // Tải khách hàng thông báo (loadCustomerNotifications): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadCustomerNotifications() async {
    final userId = pb.authStore.model?.id;

    if (userId == null || userId.isEmpty) {
      debugPrint('loadCustomerNotifications: userId rỗng');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _service.fetchCustomerNotifications(userId: userId);

      _notifications
        ..clear()
        ..addAll(result);

      debugPrint('Customer notifications: ${_notifications.length}');
      debugPrint('Customer unreadCount: $unreadCount');

      for (final item in _notifications) {
        debugPrint(
          'NOTI => title: ${item.title}, type: ${item.type}, '
          'targetRole: ${item.targetRole}, targetUser: ${item.targetUser}, '
          'orderId: ${item.orderId}, isRead: ${item.isRead}',
        );
      }

      notifyListeners();
    } catch (e) {
      _setError('Không thể tải thông báo: $e');
      debugPrint('loadCustomerNotifications error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Tải quản lý thông báo (loadManagerNotifications): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadManagerNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _service.fetchManagerNotifications();

      _notifications
        ..clear()
        ..addAll(result);

      debugPrint('Manager notifications: ${_notifications.length}');
      debugPrint('Manager unreadCount: $unreadCount');

      notifyListeners();
    } catch (e) {
      _setError('Không thể tải thông báo quản lý: $e');
      debugPrint('loadManagerNotifications error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Đánh dấu đã đọc (markAsRead): cập nhật một thông báo thành đã đọc và đồng bộ state.
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);

      final index = _notifications.indexWhere(
        (item) => item.id == notificationId,
      );

      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Không thể đánh dấu đã đọc: $e');
      debugPrint('markAsRead error: $e');
      return false;
    }
  }

  // Đánh dấu tất cả đã đọc (markAllAsRead): cập nhật toàn bộ thông báo chưa đọc của người dùng.
  Future<bool> markAllAsRead() async {
    try {
      await _service.markAllAsRead(_notifications);

      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }

      notifyListeners();

      return true;
    } catch (e) {
      _setError('Không thể đánh dấu tất cả đã đọc: $e');
      debugPrint('markAllAsRead error: $e');
      return false;
    }
  }

  /// Manager tạo thông báo chung cho Customer.
  /// Không loadCustomerNotifications ở đây vì người đang đăng nhập là Manager.
  // Tạo khách hàng thông báo (createCustomerNotification): dựng dữ liệu mới và chuyển sang service/backend để lưu.
  Future<bool> createCustomerNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    _isCreating = true;
    _clearError();
    notifyListeners();

    try {
      await _service.createCustomerNotification(
        title: title,
        body: body,
        type: type,
      );

      // Manager vừa gửi xong -> tải lại danh sách để lịch sử hiển thị ngay.
      await loadManagerNotifications();

      return true;
    } catch (e) {
      _setError('Tạo thông báo thất bại: $e');
      debugPrint('createCustomerNotification error: $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Customer tự tạo/thêm thông báo đặt hàng cho chính mình.
  // Tạo đơn hàng created thông báo for khách hàng (createOrderCreatedNotificationForCustomer): dựng dữ liệu mới và chuyển sang
  // service/backend để lưu.
  Future<bool> createOrderCreatedNotificationForCustomer({
    required String customerId,
    required String orderId,
  }) async {
    try {
      await _service.createOrderCreatedNotificationForCustomer(
        customerId: customerId,
        orderId: orderId,
      );

      await loadCustomerNotifications();

      return true;
    } catch (e) {
      _setError('Không thể tạo thông báo đặt hàng');
      debugPrint('createOrderCreatedNotificationForCustomer error: $e');
      return false;
    }
  }

  /// Tạo thông báo cập nhật trạng thái đơn hàng cho Customer.
  // Tạo đơn hàng trạng thái thông báo for khách hàng (createOrderStatusNotificationForCustomer): dựng dữ liệu mới và chuyển sang
  // service/backend để lưu.
  Future<bool> createOrderStatusNotificationForCustomer({
    required String customerId,
    required String orderId,
    required String status,
    String cancelReason = '',
  }) async {
    try {
      await _service.createOrderStatusNotificationForCustomer(
        customerId: customerId,
        orderId: orderId,
        status: status,
        cancelReason: cancelReason,
      );

      return true;
    } catch (e) {
      _setError('Không thể tạo thông báo cập nhật đơn hàng: $e');
      debugPrint('createOrderStatusNotificationForCustomer error: $e');
      return false;
    }
  }

  // Xóa thông báo (deleteNotification): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(notificationId);

      _notifications.removeWhere((item) => item.id == notificationId);

      notifyListeners();

      return true;
    } catch (e) {
      _setError('Xóa thông báo thất bại');
      debugPrint('deleteNotification error: $e');
      return false;
    }
  }

  // Xóa thông báo (clearNotifications): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearNotifications() {
    _notifications.clear();
    _errorMessage = null;
    notifyListeners();
  }

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
