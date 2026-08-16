import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/services/notification_service.dart';
import 'package:project_trangdc24v7x324/services/delivery_service.dart';

class OrderService {
  final NotificationService _notificationService = NotificationService();
  final DeliveryService _deliveryService = DeliveryService();

  // =========================================================
  // CREATE ORDER
  // =========================================================
  //
  // Contract này khớp với OrderProvider hiện tại:
  // - KHÔNG nhận totalAmount từ client.
  // - Tự đọc lại giá sản phẩm từ PocketBase.
  // - Trả về orderId sau khi tạo thành công.
  //
  Future<String> createOrder({
    required List<CartItemModel> items,
    required String receiverName,
    required String receiverPhone,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String paymentMethod,
    required String note,
  }) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    if (items.isEmpty) {
      throw Exception('Giỏ hàng đang trống');
    }

    // Đọc lại giá hiện tại từ PocketBase trước khi tạo order.
    final List<_ResolvedOrderItem> resolvedItems = [];

    for (final item in items) {
      if (item.productId.trim().isEmpty) {
        throw Exception('Sản phẩm "${item.title}" bị thiếu productId');
      }

      final resolved = await _resolveOrderItem(item);
      resolvedItems.add(resolved);
    }

    final double subtotal = resolvedItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    final double originalSubtotal = resolvedItems.fold<double>(
      0,
      (sum, item) => sum + item.originalSubtotal,
    );

    final double discountAmount =
        originalSubtotal > subtotal ? originalSubtotal - subtotal : 0;

    // Tính lại khoảng cách/phí ngay trước khi tạo order.
    // Không dùng trực tiếp số tiền hiển thị từ PaymentPage.
    final deliveryQuote = await _deliveryService.quoteForCoordinates(
      latitude: deliveryLatitude,
      longitude: deliveryLongitude,
    );

    if (!deliveryQuote.isDeliverable) {
      throw Exception(deliveryQuote.message);
    }

    final double deliveryFee = deliveryQuote.deliveryFee;

    final double distanceKm = deliveryQuote.distanceKm;

    final double totalAmount = subtotal + deliveryFee;

    final orderRecord = await pb
        .collection('orders')
        .create(
          body: {
            'user': authUser.id,
            'receiver_name': receiverName.trim(),
            'receiver_phone': receiverPhone.trim(),
            'delivery_address': deliveryAddress.trim(),
            'payment_method': paymentMethod.trim(),
            'payment_status': _getInitialPaymentStatus(paymentMethod),
            'order_status': 'placed',
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'distance_km': distanceKm,
            'discount_amount': discountAmount,
            'total_amount': totalAmount,

            // Ghi chú chung của đơn hàng.
            'note': note.trim(),

            'cancel_reason': '',
          },
        );

    try {
      for (final resolved in resolvedItems) {
        final item = resolved.cartItem;

        final body = <String, dynamic>{
          'order': orderRecord.id,
          'product': item.productId,
          'product_name': item.title,
          'product_image': item.image,

          // Giá cuối cùng đã được đọc lại từ products.
          'unit_price': resolved.unitPrice,

          'quantity': item.quantity,
          'subtotal': resolved.subtotal,

          // Ghi chú RIÊNG của dòng sản phẩm.
          'note': item.note.trim(),

          'category_title': item.categoryTitle,
          'category_slug': item.categorySlug,
        };

        if (item.categoryId.trim().isNotEmpty) {
          body['category'] = item.categoryId;
        }

        await pb.collection('order_items').create(body: body);
      }
    } catch (e) {
      // Nếu tạo order_items lỗi thì rollback order cha.
      try {
        await pb.collection('orders').delete(orderRecord.id);
      } catch (deleteError) {
        print(
          'Không thể rollback đơn hàng '
          '${orderRecord.id}: $deleteError',
        );
      }

      throw Exception('Không thể tạo chi tiết đơn hàng: $e');
    }

    // Notification không được phép làm thất bại đơn hàng.
    try {
      await _notificationService.createOrderCreatedNotificationForCustomer(
        customerId: authUser.id,
        orderId: orderRecord.id,
      );

      await _notificationService.createNewOrderNotificationForManager(
        orderId: orderRecord.id,
        receiverName: receiverName,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      print('Tạo đơn thành công nhưng tạo thông báo lỗi: $e');
    }

    return orderRecord.id;
  }

  // =========================================================
  // RE-CHECK PRODUCT PRICE
  // =========================================================

  Future<_ResolvedOrderItem> _resolveOrderItem(CartItemModel item) async {
    final record = await pb.collection('products').getOne(item.productId);

    final data = record.data;

    final bool isAvailable = _toBool(data['isAvailable'], defaultValue: true);

    if (!isAvailable) {
      throw Exception('Sản phẩm "${item.title}" hiện đang tạm ngừng bán');
    }

    final double originalPrice = _toDouble(data['price']);
    final double salePrice = _toDouble(data['salePrice']);
    final bool isOnSale = _toBool(data['isOnSale']);

    final DateTime? saleStartAt = _toDateTime(data['saleStartAt']);

    final DateTime? saleEndAt = _toDateTime(data['saleEndAt']);

    if (originalPrice <= 0) {
      throw Exception('Giá sản phẩm "${item.title}" không hợp lệ');
    }

    final bool hasActiveSale = _hasActiveSale(
      originalPrice: originalPrice,
      salePrice: salePrice,
      isOnSale: isOnSale,
      saleStartAt: saleStartAt,
      saleEndAt: saleEndAt,
    );

    final double unitPrice = hasActiveSale ? salePrice : originalPrice;

    // Chặn race-condition:
    // nếu giá thay đổi sau lúc Cart/Payment vừa refresh nhưng trước khi
    // OrderService tạo đơn thì KHÔNG âm thầm tạo đơn theo giá mới.
    final bool effectivePriceChanged = (unitPrice - item.price).abs() > 0.001;

    final bool originalPriceChanged =
        (originalPrice - item.effectiveOriginalPrice).abs() > 0.001;

    if (effectivePriceChanged || originalPriceChanged) {
      throw Exception(
        'Giá sản phẩm "${item.title}" vừa thay đổi. '
        'Vui lòng quay lại giỏ hàng để kiểm tra giá mới.',
      );
    }

    return _ResolvedOrderItem(
      cartItem: item,
      originalPrice: originalPrice,
      unitPrice: unitPrice,
    );
  }

  bool _hasActiveSale({
    required double originalPrice,
    required double salePrice,
    required bool isOnSale,
    required DateTime? saleStartAt,
    required DateTime? saleEndAt,
  }) {
    if (!isOnSale) return false;

    if (salePrice <= 0 || originalPrice <= 0 || salePrice >= originalPrice) {
      return false;
    }

    final now = DateTime.now();

    if (saleStartAt != null && now.isBefore(saleStartAt)) {
      return false;
    }

    if (saleEndAt != null && now.isAfter(saleEndAt)) {
      return false;
    }

    return true;
  }

  // =========================================================
  // FETCH ORDERS
  // =========================================================

  Future<List<OrderModel>> fetchMyOrders() async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    final orderRecords = await pb
        .collection('orders')
        .getFullList(filter: 'user = "${authUser.id}"', sort: '-created');

    return _mapOrderRecords(orderRecords);
  }

  Future<List<OrderModel>> fetchAllOrders() async {
    final orderRecords = await pb
        .collection('orders')
        .getFullList(sort: '-created');

    return _mapOrderRecords(orderRecords);
  }

  Future<OrderModel> fetchOrderDetail(String orderId) async {
    final orderRecord = await pb.collection('orders').getOne(orderId);

    final items = await _fetchOrderItems(orderId);

    return OrderModel.fromJson({
      'id': orderRecord.id,
      ...orderRecord.data,
      'created': orderRecord.created,
      'updated': orderRecord.updated,
    }, items: items);
  }

  // =========================================================
  // PURCHASE CHECK FOR REVIEW
  // =========================================================

  Future<bool> hasCompletedPurchase(String productId) async {
    final safeProductId = productId.trim();

    if (safeProductId.isEmpty) {
      return false;
    }

    final purchasedIds = await fetchCompletedPurchasedProductIds();

    return purchasedIds.contains(safeProductId);
  }

  /// Chỉ trả về sản phẩm mà Customer thực sự đủ điều kiện đánh giá:
  /// - đúng user đang đăng nhập;
  /// - order_status = completed;
  /// - thanh toán thực tế = paid;
  /// - order_items có chứa sản phẩm.
  Future<Set<String>> fetchCompletedPurchasedProductIds() async {
    final authUser = pb.authStore.model;

    if (authUser == null || authUser.id.trim().isEmpty) {
      return <String>{};
    }

    final completedOrders = await pb
        .collection('orders')
        .getFullList(
          filter:
              'user = "${authUser.id}" && '
              'order_status = "completed"',
          sort: '-updated',
        );

    if (completedOrders.isEmpty) {
      return <String>{};
    }

    final Set<String> productIds = <String>{};

    for (final order in completedOrders) {
      final orderPaymentStatus =
          (order.data['payment_status'] ?? '').toString().trim();

      bool isPaid = orderPaymentStatus == 'paid';

      // QR/MoMo demo: trạng thái thanh toán thật nằm ở collection payments.
      if (!isPaid) {
        try {
          final paymentRecords = await pb
              .collection('payments')
              .getFullList(
                filter: 'order = "${order.id}"',
                sort: '-updated',
              );

          if (paymentRecords.isNotEmpty) {
            final paymentStatus =
                (paymentRecords.first.data['status'] ?? '')
                    .toString()
                    .trim();

            isPaid = paymentStatus == 'paid';
          }
        } catch (e) {
          print(
            'Không thể kiểm tra payment của order '
            '${order.id}: $e',
          );
        }
      }

      if (!isPaid) {
        continue;
      }

      final itemRecords = await pb
          .collection('order_items')
          .getFullList(filter: 'order = "${order.id}"');

      for (final itemRecord in itemRecords) {
        final purchasedProductId =
            (itemRecord.data['product'] ?? '')
                .toString()
                .trim();

        if (purchasedProductId.isNotEmpty) {
          productIds.add(purchasedProductId);
        }
      }
    }

    return productIds;
  }

  // =========================================================
  // UPDATE STATUS
  // =========================================================

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String cancelReason = '',
  }) async {
    final safeOrderId = orderId.trim();
    final safeStatus = status.trim();
    final safeCancelReason = cancelReason.trim();

    if (safeOrderId.isEmpty) {
      throw Exception('orderId không hợp lệ');
    }

    const allowedStatuses = {
      'placed',
      'confirmed',
      'preparing',
      'delivering',
      'completed',
      'cancelled',
    };

    if (!allowedStatuses.contains(safeStatus)) {
      throw Exception('Trạng thái đơn hàng không hợp lệ');
    }

    final currentRecord = await pb.collection('orders').getOne(safeOrderId);

    final currentStatus = (currentRecord.data['order_status'] ?? '').toString();

    if (currentStatus == safeStatus) {
      return;
    }

    if (!_isValidStatusTransition(
      currentStatus: currentStatus,
      nextStatus: safeStatus,
    )) {
      throw Exception(
        'Không thể chuyển đơn từ "$currentStatus" sang "$safeStatus"',
      );
    }

    if (safeStatus == 'cancelled' && safeCancelReason.isEmpty) {
      throw Exception('Vui lòng nhập lý do hủy đơn');
    }

    final body = <String, dynamic>{'order_status': safeStatus};

    if (safeStatus == 'cancelled') {
      body['cancel_reason'] = safeCancelReason;
    }

    final updatedOrder = await pb
        .collection('orders')
        .update(safeOrderId, body: body);

    final customerId = (updatedOrder.data['user'] ?? '').toString().trim();

    if (customerId.isEmpty) {
      return;
    }

    try {
      await _notificationService.createOrderStatusNotificationForCustomer(
        customerId: customerId,
        orderId: safeOrderId,
        status: safeStatus,
        cancelReason: safeCancelReason,
      );
    } catch (e) {
      // Đơn đã cập nhật thành công nên notification không được rollback đơn.
      print('Cập nhật đơn thành công nhưng tạo thông báo lỗi: $e');
    }
  }

  bool _isValidStatusTransition({
    required String currentStatus,
    required String nextStatus,
  }) {
    if (nextStatus == 'cancelled') {
      return currentStatus == 'placed' || currentStatus == 'confirmed';
    }

    const transitions = {
      'placed': 'confirmed',
      'confirmed': 'preparing',
      'preparing': 'delivering',
      'delivering': 'completed',
    };

    return transitions[currentStatus] == nextStatus;
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
  }) async {
    await pb
        .collection('orders')
        .update(orderId, body: {'payment_status': paymentStatus});
  }

  // =========================================================
  // PRIVATE FETCH HELPERS
  // =========================================================

  Future<List<OrderModel>> _mapOrderRecords(List<dynamic> orderRecords) async {
    final List<OrderModel> orders = [];

    for (final orderRecord in orderRecords) {
      final items = await _fetchOrderItems(orderRecord.id);

      orders.add(
        OrderModel.fromJson({
          'id': orderRecord.id,
          ...orderRecord.data,
          'created': orderRecord.created,
          'updated': orderRecord.updated,
        }, items: items),
      );
    }

    return orders;
  }

  Future<List<OrderItemModel>> _fetchOrderItems(String orderId) async {
    final itemRecords = await pb
        .collection('order_items')
        .getFullList(filter: 'order = "$orderId"', sort: 'created');

    return itemRecords.map((record) {
      return OrderItemModel.fromJson({
        'id': record.id,
        ...record.data,
        'created': record.created,
        'updated': record.updated,
      });
    }).toList();
  }

  // =========================================================
  // PAYMENT
  // =========================================================

  String _getInitialPaymentStatus(String paymentMethod) {
    // Database orders.payment_status hiện tại không nhận "pending".
    //
    // Order chỉ phản ánh trạng thái thanh toán tổng quát:
    // - unpaid: chưa xác nhận đã thu tiền
    // - paid: đã xác nhận thanh toán
    //
    // Trạng thái chi tiết pending / failed được lưu ở collection payments.
    return 'unpaid';
  }

  // =========================================================
  // PARSE HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;

    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    final text = value.toString().trim().toLowerCase();

    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }

    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }

    return defaultValue;
  }

  DateTime? _toDateTime(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }
}

// ===========================================================
// INTERNAL SNAPSHOT MODEL
// ===========================================================

class _ResolvedOrderItem {
  final CartItemModel cartItem;
  final double originalPrice;
  final double unitPrice;

  const _ResolvedOrderItem({
    required this.cartItem,
    required this.originalPrice,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * cartItem.quantity;

  double get originalSubtotal => originalPrice * cartItem.quantity;
}
