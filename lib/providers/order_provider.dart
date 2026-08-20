// FILE HỌC TẬP: lib/providers/order_provider.dart
// Vai trò: Provider quản lý trạng thái đơn hàng.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/services/order_service.dart';

// Lớp OrderProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  final List<OrderModel> _orders = [];

  OrderModel? _selectedOrder;

  bool _isLoading = false;
  bool _isPlacingOrder = false;
  bool _isUpdatingStatus = false;

  String? _errorMessage;

  // Đọc đơn hàng (orders): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<OrderModel> get orders => List.unmodifiable(_orders);

  // Đọc đã chọn đơn hàng (selectedOrder): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  OrderModel? get selectedOrder => _selectedOrder;

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;

  // Đọc trạng thái placing đơn hàng (isPlacingOrder): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isPlacingOrder => _isPlacingOrder;

  // Đọc trạng thái updating trạng thái (isUpdatingStatus): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isUpdatingStatus => _isUpdatingStatus;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc trạng thái có đơn hàng (hasOrders): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasOrders => _orders.isNotEmpty;

  // Đọc đang hoạt động đơn hàng (activeOrders): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<OrderModel> get activeOrders {
    return _orders.where((order) => order.isActive).toList();
  }

  // Đọc hoàn thành đơn hàng (completedOrders): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<OrderModel> get completedOrders {
    return _orders.where((order) => order.isCompleted).toList();
  }

  // Đọc khả năng celled đơn hàng (cancelledOrders): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<OrderModel> get cancelledOrders {
    return _orders.where((order) => order.isCancelled).toList();
  }

  // Đọc pending đơn hàng số lượng (pendingOrderCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get pendingOrderCount {
    return _orders.where((order) => order.isActive).length;
  }

  // Đọc hoàn thành đơn hàng số lượng (completedOrderCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get completedOrderCount {
    return _orders.where((order) => order.isCompleted).length;
  }

  // Đọc khả năng celled đơn hàng số lượng (cancelledOrderCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get cancelledOrderCount {
    return _orders.where((order) => order.isCancelled).length;
  }

  // Đọc hoàn thành doanh thu (completedRevenue): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get completedRevenue {
    return _orders
        .where((order) => order.isCompleted)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  // Đọc tổng doanh thu (totalRevenue): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get totalRevenue {
    return _orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  // Tải đơn hàng (loadOrders): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
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

  // Tải tất cả đơn hàng (loadAllOrders): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
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

  // Tải chi tiết đơn hàng (loadOrderDetail): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
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

  // Xử lý placeOrder: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái đơn hàng.
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
      final createdOrder = await _orderService.createOrder(
        items: cartItems,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        deliveryAddress: address,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        paymentMethod: paymentMethod,
        note: note,
      );

      // Cập nhật local state trực tiếp, không tải lại toàn bộ lịch sử đơn.
      _selectedOrder = createdOrder;
      _orders.removeWhere((order) => order.id == createdOrder.id);
      _orders.insert(0, createdOrder);

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

  // Cập nhật trạng thái đơn hàng (updateOrderStatus): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
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

  // Cập nhật thanh toán trạng thái (updatePaymentStatus): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
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

  // Làm mới đơn hàng (refreshOrder): tải dữ liệu mới nhất và đồng bộ state hiện tại.
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

  // Cập nhật state (findOrderById): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  OrderModel? findOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // Lọc/tìm by trạng thái (filterByStatus): tạo tập dữ liệu phù hợp theo điều kiện đang chọn.
  List<OrderModel> filterByStatus(String status) {
    return _orders.where((order) => order.orderStatus == status).toList();
  }

  // Xóa đã chọn đơn hàng (clearSelectedOrder): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  // Xóa đơn hàng (clearOrders): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearOrders() {
    _orders.clear();
    _selectedOrder = null;
    _clearError();
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

  // Kiểm tra điều kiện (hasCompletedPurchase): đánh giá trạng thái có hoàn thành purchase và trả kết quả cho lớp gọi.
  Future<bool> hasCompletedPurchase(String productId) async {
    try {
      return await _orderService.hasCompletedPurchase(productId);
    } catch (error) {
      debugPrint('hasCompletedPurchase error: $error');

      return false;
    }
  }

  // Lấy hoàn thành đã mua sản phẩm các mã (getCompletedPurchasedProductIds): truy xuất và trả kết quả cho lớp gọi.
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
