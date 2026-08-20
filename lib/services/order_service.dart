// FILE HỌC TẬP: lib/services/order_service.dart
// Vai trò: Service nghiệp vụ đơn hàng.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:flutter/foundation.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/services/notification_service.dart';
import 'package:project_trangdc24v7x324/services/delivery_service.dart';
import 'package:project_trangdc24v7x324/utils/delivery_location_helper.dart';

// Lớp OrderService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class OrderService {
  final NotificationService _notificationService = NotificationService();
  final DeliveryService _deliveryService = DeliveryService();

  // =========================================================
  // CREATE ORDER
  // =========================================================
  //
  // Tạo đơn hàng: tự xác thực lại giá/phí trên backend data và trả về snapshot đơn vừa tạo.
  //
  // Tạo đơn hàng (createOrder): kiểm tra sản phẩm, tính phí giao hàng, ghi order/order_items và phát thông báo.
  Future<OrderModel> createOrder({
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

    // Kiểm tra sản phẩm song song: giảm thời gian chờ khi đơn có nhiều món.
    final resolvedItems = await Future.wait(
      items.map((item) async {
        if (item.productId.trim().isEmpty) {
          throw Exception('Sản phẩm "${item.title}" bị thiếu productId');
        }

        return _resolveOrderItem(item);
      }),
    );

    final subtotal = resolvedItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    final originalSubtotal = resolvedItems.fold<double>(
      0,
      (sum, item) => sum + item.originalSubtotal,
    );

    final discountAmount =
        originalSubtotal > subtotal ? originalSubtotal - subtotal : 0;

    // Tính lại phí ngay trước khi ghi đơn để không tin số tiền từ UI.
    final deliveryQuote = await _deliveryService.quoteForCoordinates(
      latitude: deliveryLatitude,
      longitude: deliveryLongitude,
    );

    if (!deliveryQuote.isDeliverable) {
      throw Exception(deliveryQuote.message);
    }

    final deliveryFee = deliveryQuote.deliveryFee;
    final distanceKm = deliveryQuote.distanceKm;
    final totalAmount = subtotal + deliveryFee;

    // Giữ địa chỉ dễ đọc và tọa độ chỉ đường trong cùng field hiện có.
    // Cách này không yêu cầu đổi schema PocketBase ở bản V1.
    final storedDeliveryAddress = DeliveryLocationHelper.encode(
      address: deliveryAddress,
      latitude: deliveryLatitude,
      longitude: deliveryLongitude,
    );

    final orderRecord = await pb.collection('orders').create(
      body: {
        'user': authUser.id,
        'receiver_name': receiverName.trim(),
        'receiver_phone': receiverPhone.trim(),
        'delivery_address': storedDeliveryAddress,
        'payment_method': paymentMethod.trim(),
        'payment_status': _getInitialPaymentStatus(paymentMethod),
        'order_status': 'placed',
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'distance_km': distanceKm,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'note': note.trim(),
        'cancel_reason': '',
      },
    );

    final createdItems = <OrderItemModel>[];

    try {
      for (final resolved in resolvedItems) {
        final item = resolved.cartItem;

        final body = <String, dynamic>{
          'order': orderRecord.id,
          'product': item.productId,
          'product_name': item.title,
          'product_image': item.image,
          'unit_price': resolved.unitPrice,
          'quantity': item.quantity,
          'subtotal': resolved.subtotal,
          'note': item.note.trim(),
          'category_title': item.categoryTitle,
          'category_slug': item.categorySlug,
        };

        if (item.categoryId.trim().isNotEmpty) {
          body['category'] = item.categoryId;
        }

        final itemRecord = await pb.collection('order_items').create(body: body);

        createdItems.add(
          OrderItemModel.fromJson({
            'id': itemRecord.id,
            ...itemRecord.data,
            'created': itemRecord.created,
            'updated': itemRecord.updated,
          }),
        );
      }
    } catch (error) {
      // Rollback các dòng đã tạo trước khi xóa đơn cha.
      for (final item in createdItems) {
        try {
          await pb.collection('order_items').delete(item.id);
        } catch (_) {}
      }

      try {
        await pb.collection('orders').delete(orderRecord.id);
      } catch (deleteError) {
        debugPrint(
          'Không thể rollback đơn hàng ${orderRecord.id}: $deleteError',
        );
      }

      throw Exception('Không thể tạo chi tiết đơn hàng: $error');
    }

    // Thông báo chạy song song và không được làm thất bại đơn hàng.
    try {
      await Future.wait([
        _notificationService.createOrderCreatedNotificationForCustomer(
          customerId: authUser.id,
          orderId: orderRecord.id,
        ),
        _notificationService.createNewOrderNotificationForManager(
          orderId: orderRecord.id,
          receiverName: receiverName,
          totalAmount: totalAmount,
          paymentMethod: paymentMethod,
        ),
      ]);
    } catch (error) {
      debugPrint('Tạo đơn thành công nhưng tạo thông báo lỗi: $error');
    }

    // Trả thẳng order vừa tạo để Provider không reload toàn bộ lịch sử đơn.
    return OrderModel.fromJson(
      {
        'id': orderRecord.id,
        ...orderRecord.data,
        'created': orderRecord.created,
        'updated': orderRecord.updated,
      },
      items: createdItems,
    );
  }

  // =========================================================
  // RE-CHECK PRODUCT PRICE
  // =========================================================

  // Xử lý đơn hàng mục (_resolveOrderItem): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
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

  // Kiểm tra điều kiện (_hasActiveSale): đánh giá trạng thái có đang hoạt động khuyến mãi và trả kết quả cho lớp gọi.
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

  // Lấy của tôi đơn hàng (fetchMyOrders): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

  // Lấy tất cả đơn hàng (fetchAllOrders): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<List<OrderModel>> fetchAllOrders() async {
    final orderRecords = await pb
        .collection('orders')
        .getFullList(sort: '-created');

    return _mapOrderRecords(orderRecords);
  }

  // Lấy chi tiết đơn hàng (fetchOrderDetail): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

  // Kiểm tra điều kiện (hasCompletedPurchase): đánh giá trạng thái có hoàn thành purchase và trả kết quả cho lớp gọi.
  Future<bool> hasCompletedPurchase(String productId) async {
    final safeProductId = productId.trim();

    if (safeProductId.isEmpty) {
      return false;
    }

    final purchasedIds = await fetchCompletedPurchasedProductIds();

    return purchasedIds.contains(safeProductId);
  }

  // Kiểm tra sản phẩm đã mua: chỉ nhận đơn completed + paid và tải item song song.
  // Lấy hoàn thành đã mua sản phẩm các mã (fetchCompletedPurchasedProductIds): truy xuất từ PocketBase và trả kết quả cho lớp
  // gọi.
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

    final latestPaymentStatus = <String, String>{};

    if (completedOrders.any(
      (order) => (order.data['payment_status'] ?? '').toString().trim() != 'paid',
    )) {
      try {
        final paymentRecords = await pb
            .collection('payments')
            .getFullList(sort: '-updated');

        for (final record in paymentRecords) {
          final orderId = (record.data['order'] ?? '').toString().trim();
          final status = (record.data['status'] ?? '').toString().trim();

          if (orderId.isNotEmpty && status.isNotEmpty) {
            latestPaymentStatus.putIfAbsent(orderId, () => status);
          }
        }
      } catch (error) {
        debugPrint('Không thể tải trạng thái payment khi kiểm tra review: $error');
      }
    }

    final paidOrderIds = completedOrders
        .where((order) {
          final orderStatus =
              (order.data['payment_status'] ?? '').toString().trim();
          return orderStatus == 'paid' ||
              latestPaymentStatus[order.id] == 'paid';
        })
        .map((order) => order.id.toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (paidOrderIds.isEmpty) {
      return <String>{};
    }

    final itemGroups = await Future.wait(
      paidOrderIds.map(
        (orderId) => pb
            .collection('order_items')
            .getFullList(filter: 'order = "$orderId"'),
      ),
    );

    final productIds = <String>{};

    for (final itemRecords in itemGroups) {
      for (final itemRecord in itemRecords) {
        final productId =
            (itemRecord.data['product'] ?? '').toString().trim();
        if (productId.isNotEmpty) {
          productIds.add(productId);
        }
      }
    }

    return productIds;
  }

  // =========================================================
  // UPDATE STATUS
  // =========================================================

  // Cập nhật trạng thái đơn hàng (updateOrderStatus): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
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
      debugPrint('Cập nhật đơn thành công nhưng tạo thông báo lỗi: $e');
    }
  }

  // Kiểm tra điều kiện (_isValidStatusTransition): đánh giá trạng thái hợp lệ trạng thái transition và trả kết quả cho lớp gọi.
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

  // Cập nhật thanh toán trạng thái (updatePaymentStatus): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
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

  // Ánh xạ danh sách đơn: tải chi tiết các đơn song song để giảm thời gian chờ N đơn liên tiếp.
  // Ánh xạ đơn hàng bản ghi (_mapOrderRecords): chuyển dữ liệu thô thành cấu trúc ứng dụng sử dụng.
  Future<List<OrderModel>> _mapOrderRecords(List<dynamic> orderRecords) async {
    return Future.wait(
      orderRecords.map((orderRecord) async {
        final items = await _fetchOrderItems(orderRecord.id);

        return OrderModel.fromJson(
          {
            'id': orderRecord.id,
            ...orderRecord.data,
            'created': orderRecord.created,
            'updated': orderRecord.updated,
          },
          items: items,
        );
      }),
    );
  }

  // Lấy đơn hàng các mục (_fetchOrderItems): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

  // Lấy ban đầu thanh toán trạng thái (_getInitialPaymentStatus): truy xuất và trả kết quả cho lớp gọi.
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

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ đơn hàng.
  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  // Xử lý _toBool: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ đơn hàng.
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

  // Xử lý _toDateTime: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ đơn hàng.
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

// Lớp _ResolvedOrderItem: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _ResolvedOrderItem {
  final CartItemModel cartItem;
  final double originalPrice;
  final double unitPrice;

  // Khởi tạo _ResolvedOrderItem: nhận các tham số cần thiết để tạo đối tượng cho service nghiệp vụ đơn hàng.
  const _ResolvedOrderItem({
    required this.cartItem,
    required this.originalPrice,
    required this.unitPrice,
  });

  // Đọc tạm tính (subtotal): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get subtotal => unitPrice * cartItem.quantity;

  // Đọc gốc tạm tính (originalSubtotal): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get originalSubtotal => originalPrice * cartItem.quantity;
}
