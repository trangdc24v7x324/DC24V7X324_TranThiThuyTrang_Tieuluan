import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/app_notification_model.dart';

class NotificationService {
  static const Set<String> allowedTypes = {
    'promotion',
    'new_product',
    'general',
    'order_success',
    'order_confirmed',
    'order_preparing',
    'order_delivering',
    'order_completed',
    'order_cancelled',
  };

  String _normalizeType(String type) {
    final value = type.trim();

    if (value == 'order' || value == 'new_order') {
      return 'order_success';
    }

    if (allowedTypes.contains(value)) {
      return value;
    }

    return 'general';
  }

  String _shortOrderId(String orderId) {
    final value = orderId.trim();

    if (value.length <= 8) {
      return value.toUpperCase();
    }

    return value.substring(0, 8).toUpperCase();
  }

  Map<String, String> _buildOrderContent({
    required String orderId,
    required String status,
    String cancelReason = '',
  }) {
    final shortId = _shortOrderId(orderId);

    switch (status) {
      case 'placed':
        return {
          'type': 'order_success',
          'title': 'Đặt hàng thành công',
          'body': 'Đơn #$shortId đã được tạo và đang chờ cửa hàng xác nhận.',
        };

      case 'confirmed':
        return {
          'type': 'order_confirmed',
          'title': 'Đơn hàng đã được xác nhận',
          'body':
              'Cửa hàng đã xác nhận đơn #$shortId và sẽ bắt đầu chuẩn bị món.',
        };

      case 'preparing':
        return {
          'type': 'order_preparing',
          'title': 'Món ăn đang được chuẩn bị',
          'body':
              'Đơn #$shortId đang được chuẩn bị. Bạn vui lòng chờ trong ít phút.',
        };

      case 'delivering':
        return {
          'type': 'order_delivering',
          'title': 'Đơn hàng đang được giao',
          'body':
              'Đơn #$shortId đã rời cửa hàng và đang trên đường giao đến bạn.',
        };

      case 'completed':
        return {
          'type': 'order_completed',
          'title': 'Giao hàng thành công',
          'body':
              'Đơn #$shortId đã hoàn thành. Cảm ơn bạn đã đặt món tại YourFood.',
        };

      case 'cancelled':
        final reason = cancelReason.trim();

        return {
          'type': 'order_cancelled',
          'title': 'Đơn hàng đã bị hủy',
          'body':
              reason.isEmpty
                  ? 'Đơn #$shortId đã bị hủy.'
                  : 'Đơn #$shortId đã bị hủy. Lý do: $reason',
        };

      default:
        return {
          'type': 'general',
          'title': 'Cập nhật đơn hàng',
          'body': 'Đơn #$shortId vừa có thay đổi mới.',
        };
    }
  }

  // =========================================================
  // FETCH
  // =========================================================

  Future<List<AppNotificationModel>> fetchCustomerNotifications({
    required String userId,
  }) async {
    final safeUserId = userId.trim();

    if (safeUserId.isEmpty) {
      return <AppNotificationModel>[];
    }

    // Chỉ đọc notification personal của chính Customer.
    // Không đọc broadcast targetRole=customer cũ vì isRead của loại đó
    // dùng chung giữa tất cả Customer.
    final records = await pb
        .collection('notifications')
        .getFullList(
          sort: '-created',
          filter:
              'targetRole = "personal" && '
              'targetUser = "$safeUserId"',
        );

    return records.map((record) {
      return AppNotificationModel.fromJson({
        'id': record.id,
        ...record.data,
        'created': record.created,
        'updated': record.updated,
      });
    }).toList();
  }

  Future<List<AppNotificationModel>> fetchManagerNotifications() async {
    final records = await pb
        .collection('notifications')
        .getFullList(
          sort: '-created',
          filter: 'targetRole = "manager" || targetRole = "all"',
        );

    return records.map((record) {
      return AppNotificationModel.fromJson({
        'id': record.id,
        ...record.data,
        'created': record.created,
        'updated': record.updated,
      });
    }).toList();
  }

  // =========================================================
  // MANAGER -> CUSTOMER BROADCAST
  // =========================================================

  Future<List<String>> _fetchActiveCustomerIds() async {
    try {
      final records = await pb
          .collection('users')
          .getFullList(
            sort: 'created',
            filter: 'role = "customer" && isActive = true',
          );

      return records.map((record) => record.id).toList();
    } catch (_) {
      // Fallback cho schema cũ hoặc rule chưa dùng được isActive.
      final records = await pb
          .collection('users')
          .getFullList(sort: 'created', filter: 'role = "customer"');

      return records.map((record) => record.id).toList();
    }
  }

  /// Manager gửi 1 nội dung cho toàn bộ Customer.
  ///
  /// Mỗi Customer nhận 1 record personal riêng:
  /// -> isRead riêng cho từng người.
  ///
  /// Đồng thời tạo 1 record targetRole=manager:
  /// -> dùng làm lịch sử thông báo Manager đã gửi.
  Future<void> createCustomerNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final safeTitle = title.trim();
    final safeBody = body.trim();
    final safeType = _normalizeType(type);

    if (safeTitle.isEmpty) {
      throw Exception('Tiêu đề thông báo đang trống');
    }

    if (safeBody.isEmpty) {
      throw Exception('Nội dung thông báo đang trống');
    }

    final customerIds = await _fetchActiveCustomerIds();

    if (customerIds.isEmpty) {
      throw Exception('Không tìm thấy Customer đang hoạt động');
    }

    for (final customerId in customerIds) {
      await create(
        title: safeTitle,
        body: safeBody,
        type: safeType,
        targetRole: 'personal',
        targetUser: customerId,
      );
    }

    // Log của Manager: đây là lịch sử đã gửi nên đánh dấu read=true
    // để không làm tăng badge thông báo mới của Manager.
    await create(
      title: safeTitle,
      body: safeBody,
      type: safeType,
      targetRole: 'manager',
      isRead: true,
    );
  }

  // =========================================================
  // CREATE CORE
  // =========================================================

  Future<void> create({
    required String title,
    required String body,
    required String type,
    required String targetRole,
    String? targetUser,
    String? orderId,
    bool isRead = false,
  }) async {
    final safeTitle = title.trim();
    final safeBody = body.trim();
    final safeRole = targetRole.trim();
    final safeType = _normalizeType(type);

    if (safeTitle.isEmpty) {
      throw Exception('Tiêu đề thông báo đang trống');
    }

    if (safeBody.isEmpty) {
      throw Exception('Nội dung thông báo đang trống');
    }

    if (safeRole.isEmpty) {
      throw Exception('Đối tượng nhận thông báo không hợp lệ');
    }

    final data = <String, dynamic>{
      'title': safeTitle,
      'body': safeBody,
      'type': safeType,
      'targetRole': safeRole,
      'isRead': isRead,
    };

    final safeTargetUser = targetUser?.trim() ?? '';
    final safeOrderId = orderId?.trim() ?? '';

    if (safeTargetUser.isNotEmpty) {
      data['targetUser'] = safeTargetUser;
    }

    if (safeOrderId.isNotEmpty) {
      data['orderId'] = safeOrderId;
    }

    await pb.collection('notifications').create(body: data);
  }

  // =========================================================
  // CUSTOMER ORDER NOTIFICATIONS
  // =========================================================

  Future<void> createOrderCreatedNotificationForCustomer({
    required String customerId,
    required String orderId,
  }) async {
    final content = _buildOrderContent(orderId: orderId, status: 'placed');

    await create(
      title: content['title']!,
      body: content['body']!,
      type: content['type']!,
      targetRole: 'personal',
      targetUser: customerId,
      orderId: orderId,
    );
  }

  Future<void> createOrderStatusNotificationForCustomer({
    required String customerId,
    required String orderId,
    required String status,
    String cancelReason = '',
  }) async {
    final content = _buildOrderContent(
      orderId: orderId,
      status: status,
      cancelReason: cancelReason,
    );

    await create(
      title: content['title']!,
      body: content['body']!,
      type: content['type']!,
      targetRole: 'personal',
      targetUser: customerId,
      orderId: orderId,
    );
  }

  // =========================================================
  // MANAGER ORDER NOTIFICATION
  // GIỮ NGUYÊN CONTRACT VÌ OrderService ĐANG GỌI HÀM NÀY.
  // =========================================================

  Future<void> createNewOrderNotificationForManager({
    required String orderId,
    required String receiverName,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    final shortId = _shortOrderId(orderId);

    await create(
      title: 'Có đơn hàng mới #$shortId',
      body:
          '${receiverName.trim()} vừa đặt đơn trị giá '
          '${_formatMoney(totalAmount)} • ${paymentMethod.trim()}.',
      type: 'order_success',
      targetRole: 'manager',
      orderId: orderId,
    );
  }

  String _formatMoney(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  // =========================================================
  // READ / DELETE
  // =========================================================

  Future<void> markAsRead(String notificationId) async {
    final safeId = notificationId.trim();

    if (safeId.isEmpty) {
      return;
    }

    await pb.collection('notifications').update(safeId, body: {'isRead': true});
  }

  Future<void> markAllAsRead(List<AppNotificationModel> notifications) async {
    for (final item in notifications) {
      if (!item.isRead) {
        await markAsRead(item.id);
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final safeId = notificationId.trim();

    if (safeId.isEmpty) {
      return;
    }

    await pb.collection('notifications').delete(safeId);
  }
}
