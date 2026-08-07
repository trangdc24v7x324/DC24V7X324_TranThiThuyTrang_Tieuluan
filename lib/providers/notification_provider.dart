import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/app_notification_model.dart';
import 'package:project_trangdc24v7x324/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  final List<AppNotificationModel> _notifications = [];

  bool _isLoading = false;
  bool _isCreating = false;

  String? _errorMessage;

  List<AppNotificationModel> get notifications {
    return List.unmodifiable(_notifications);
  }

  bool get isLoading => _isLoading;

  bool get isCreating => _isCreating;

  String? get errorMessage => _errorMessage;

  int get unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  bool get hasUnread => unreadCount > 0;

  List<AppNotificationModel> get unreadNotifications {
    return _notifications.where((item) => !item.isRead).toList();
  }

  List<AppNotificationModel> get readNotifications {
    return _notifications.where((item) => item.isRead).toList();
  }

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
      _setError('Không thể đánh dấu đã đọc');
      debugPrint('markAsRead error: $e');
      return false;
    }
  }

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
      _setError('Không thể đánh dấu tất cả đã đọc');
      debugPrint('markAllAsRead error: $e');
      return false;
    }
  }

  /// Manager tạo thông báo chung cho Customer.
  /// Không loadCustomerNotifications ở đây vì người đang đăng nhập là Manager.
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

      return true;
    } catch (e) {
      _setError('Tạo thông báo thất bại');
      debugPrint('createCustomerNotification error: $e');
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Customer tự tạo/thêm thông báo đặt hàng cho chính mình.
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

  void clearNotifications() {
    _notifications.clear();
    _errorMessage = null;
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
