import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  final List<OrderModel> _orders = [];

  OrderModel? _selectedOrder;

  bool _isLoading = false;
  bool _isPlacingOrder = false;
  bool _isUpdatingStatus = false;

  String? _errorMessage;

  List<OrderModel> get orders => List.unmodifiable(_orders);

  OrderModel? get selectedOrder => _selectedOrder;

  bool get isLoading => _isLoading;

  bool get isPlacingOrder => _isPlacingOrder;

  bool get isUpdatingStatus => _isUpdatingStatus;

  String? get errorMessage => _errorMessage;

  bool get hasOrders => _orders.isNotEmpty;

  List<OrderModel> get activeOrders {
    return _orders.where((order) => order.isActive).toList();
  }

  List<OrderModel> get completedOrders {
    return _orders.where((order) => order.isCompleted).toList();
  }

  List<OrderModel> get cancelledOrders {
    return _orders.where((order) => order.isCancelled).toList();
  }

  int get pendingOrderCount {
    return _orders.where((order) => order.isActive).length;
  }

  int get completedOrderCount {
    return _orders.where((order) => order.isCompleted).length;
  }

  int get cancelledOrderCount {
    return _orders.where((order) => order.isCancelled).length;
  }

  double get completedRevenue {
    return _orders
        .where((order) => order.isCompleted)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  double get totalRevenue {
    return _orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.fetchMyOrders();

      _orders
        ..clear()
        ..addAll(result);
    } catch (e) {
      _setError('Không thể tải danh sách đơn hàng');

      debugPrint('loadOrders error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllOrders() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _orderService.fetchAllOrders();

      _orders
        ..clear()
        ..addAll(result);
    } catch (e) {
      _setError('Không thể tải danh sách đơn hàng');

      debugPrint('loadAllOrders error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedOrder = await _orderService.fetchOrderDetail(orderId);

      final index = _orders.indexWhere((order) => order.id == orderId);

      if (index != -1 && _selectedOrder != null) {
        _orders[index] = _selectedOrder!;
      }
    } catch (e) {
      _setError('Không thể tải chi tiết đơn hàng');

      debugPrint('loadOrderDetail error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> placeOrder(
    List<CartItemModel> cartItems,
    double totalAmount, {
    required String receiverName,
    required String receiverPhone,
    required String address,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String paymentMethod,
    String note = '',
  }) async {
    if (cartItems.isEmpty) {
      _setError('Giỏ hàng đang trống');

      return false;
    }

    if (totalAmount <= 0) {
      _setError('Tổng tiền không hợp lệ');

      return false;
    }

    _isPlacingOrder = true;
    _clearError();
    notifyListeners();

    try {
      final String orderId = await _orderService.createOrder(
        items: cartItems,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        deliveryAddress: address,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        paymentMethod: paymentMethod,
        note: note,
      );

      await loadOrders();

      _selectedOrder = findOrderById(orderId);

      return true;
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''));

      debugPrint('placeOrder error: $error');

      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    bool reloadAll = true,
    String cancelReason = '',
  }) async {
    // reloadAll được giữ lại để tương thích với code cũ.
    // Phiên bản tối ưu luôn chỉ refresh đúng order vừa cập nhật.
    if (_isUpdatingStatus) {
      _setError('Hệ thống đang xử lý một cập nhật khác');
      return false;
    }

    _isUpdatingStatus = true;
    _clearError();
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        status: status,
        cancelReason: cancelReason,
      );

      await refreshOrder(orderId);

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));

      debugPrint('updateOrderStatus error: $e');

      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  Future<bool> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    bool reloadAll = true,
  }) async {
    // reloadAll được giữ lại để tương thích với code cũ.
    // Phiên bản tối ưu luôn chỉ refresh đúng order vừa cập nhật.
    if (_isUpdatingStatus) {
      _setError('Hệ thống đang xử lý một cập nhật khác');
      return false;
    }

    _isUpdatingStatus = true;
    _clearError();
    notifyListeners();

    try {
      await _orderService.updatePaymentStatus(
        orderId: orderId,
        paymentStatus: paymentStatus,
      );

      await refreshOrder(orderId);

      return true;
    } catch (e) {
      _setError('Cập nhật trạng thái thanh toán thất bại');

      debugPrint('updatePaymentStatus error: $e');

      return false;
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  Future<void> refreshOrder(String orderId) async {
    try {
      final refreshedOrder = await _orderService.fetchOrderDetail(orderId);

      final index = _orders.indexWhere((order) => order.id == orderId);

      if (index == -1) {
        _orders.insert(0, refreshedOrder);
      } else {
        _orders[index] = refreshedOrder;
      }

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = refreshedOrder;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('refreshOrder error: $e');
      rethrow;
    }
  }

  OrderModel? findOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  List<OrderModel> filterByStatus(String status) {
    return _orders.where((order) => order.orderStatus == status).toList();
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    _selectedOrder = null;
    _clearError();
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

  Future<bool> hasCompletedPurchase(String productId) async {
    try {
      return await _orderService.hasCompletedPurchase(productId);
    } catch (error) {
      debugPrint('hasCompletedPurchase error: $error');

      return false;
    }
  }

  Future<Set<String>> getCompletedPurchasedProductIds() async {
    try {
      return await _orderService.fetchCompletedPurchasedProductIds();
    } catch (error) {
      debugPrint(
        'getCompletedPurchasedProductIds '
        'error: $error',
      );

      return <String>{};
    }
  }
}
