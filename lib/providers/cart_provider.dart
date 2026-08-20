// FILE HỌC TẬP: lib/providers/cart_provider.dart
// Vai trò: Provider quản lý trạng thái giỏ hàng.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/services/cart_service.dart';

// Lớp CartProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class CartProvider extends ChangeNotifier {
  final CartService _cartService;

  final List<CartItemModel> _items = [];

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  // Hàng đợi giúp các thao tác + / - / xóa chạy tuần tự,
  // tránh request PocketBase hoàn thành sai thứ tự khi người dùng bấm nhanh.
  Future<void> _operationQueue = Future<void>.value();

  // Khởi tạo CartProvider: nhận các tham số cần thiết để tạo đối tượng cho provider quản lý trạng thái giỏ hàng.
  CartProvider({CartService? cartService})
    : _cartService = cartService ?? CartService();

  // =========================================================
  // GETTERS
  // =========================================================

  // Đọc các mục (items): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<CartItemModel> get items => List.unmodifiable(_items);

  // Đọc trạng thái rỗng (isEmpty): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isEmpty => _items.isEmpty;

  // Đọc trạng thái not rỗng (isNotEmpty): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isNotEmpty => _items.isNotEmpty;

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;

  // Đọc trạng thái syncing (isSyncing): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isSyncing => _isSyncing;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc tổng số lượng món (itemCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get itemCount {
    return _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  // Đọc unique mục số lượng (uniqueItemCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get uniqueItemCount => _items.length;

  // Đọc tổng tiền giỏ hàng (totalPrice): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get totalPrice {
    return _items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  // Đọc tổng giá gốc trước khuyến mãi (totalOriginalPrice): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get totalOriginalPrice {
    return _items.fold<double>(0, (sum, item) => sum + item.originalSubtotal);
  }

  // Đọc tổng số tiền giảm giá (totalDiscount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get totalDiscount {
    return _items.fold<double>(0, (sum, item) => sum + item.totalDiscount);
  }

  // Đọc trạng thái có giảm giá (hasDiscount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasDiscount => totalDiscount > 0;

  // =========================================================
  // LOAD FROM POCKETBASE
  // =========================================================

  // Tải giỏ hàng (loadCart): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<bool> loadCart() async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final result = await _cartService.fetchActiveCartItems();

      _items
        ..clear()
        ..addAll(result);

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));

      debugPrint('loadCart error: $e');

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Làm mới giỏ hàng (refreshCart): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<bool> refreshCart() async {
    // Quan trọng trước checkout:
    // chờ toàn bộ thao tác + / - / xóa đang xếp hàng ghi PocketBase xong
    // rồi mới đọc lại cart từ server.
    await _operationQueue;

    return loadCart();
  }

  // =========================================================
  // FIND
  // =========================================================

  // Xử lý containsProduct: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái giỏ hàng.
  bool containsProduct(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // Lấy mục by sản phẩm mã (getItemByProductId): truy xuất và trả kết quả cho lớp gọi.
  CartItemModel? getItemByProductId(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  // Xử lý _indexOfItem: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái giỏ hàng.
  int _indexOfItem(CartItemModel item) {
    return _items.indexWhere((element) => element.sameLine(item));
  }

  // Xử lý _indexOfProductAndNote: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái giỏ hàng.
  int _indexOfProductAndNote(String productId, String note) {
    final normalizedNote = note.trim();

    return _items.indexWhere(
      (item) =>
          item.productId == productId && item.normalizedNote == normalizedNote,
    );
  }

  // =========================================================
  // ADD PRODUCT
  // =========================================================

  // Thêm sản phẩm (addProduct): đưa mục mới vào state/backend và cập nhật giao diện.
  Future<bool> addProduct(
    ProductModel product, {
    int quantity = 1,
    String note = '',
  }) {
    final item = CartItemModel.fromProduct(
      product,
      quantity: quantity,
      note: note,
    );

    return addItem(item);
  }

  // =========================================================
  // ADD ITEM
  // =========================================================

  // Thêm mục (addItem): đưa mục mới vào state/backend và cập nhật giao diện.
  Future<bool> addItem(CartItemModel item) async {
    if (item.quantity <= 0) {
      _setError('Số lượng sản phẩm không hợp lệ');
      return false;
    }

    // Cập nhật UI ngay.
    final index = _indexOfItem(item);

    if (index >= 0) {
      final currentItem = _items[index];

      _items[index] = currentItem.copyWith(
        quantity: currentItem.quantity + item.quantity,
        price: item.price,
        originalPrice: item.originalPrice,
      );
    } else {
      _items.add(item);
    }

    _clearError();
    notifyListeners();

    // Sau đó ghi xuống PocketBase theo đúng thứ tự thao tác.
    return _enqueueOperation(
      () => _cartService.addItem(item),
      operationName: 'addItem',
    );
  }

  // =========================================================
  // REMOVE ITEM
  // =========================================================

  // Xóa mục (removeItem): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> removeItem(CartItemModel item) async {
    final index = _indexOfItem(item);

    if (index == -1) {
      return false;
    }

    _items.removeAt(index);
    _clearError();
    notifyListeners();

    return _enqueueOperation(
      () => _cartService.removeItem(item),
      operationName: 'removeItem',
    );
  }

  // Xóa by sản phẩm mã (removeByProductId): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> removeByProductId(String productId) async {
    final exists = _items.any((item) => item.productId == productId);

    if (!exists) {
      return false;
    }

    _items.removeWhere((item) => item.productId == productId);

    _clearError();
    notifyListeners();

    return _enqueueOperation(
      () => _cartService.removeByProductId(productId),
      operationName: 'removeByProductId',
    );
  }

  // =========================================================
  // INCREASE
  // =========================================================

  // Cập nhật state (increaseQty): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  Future<bool> increaseQty(CartItemModel item) async {
    final index = _indexOfItem(item);

    if (index == -1) {
      return false;
    }

    final currentItem = _items[index];
    final newQuantity = currentItem.quantity + 1;

    _items[index] = currentItem.copyWith(quantity: newQuantity);

    _clearError();
    notifyListeners();

    final serverItem = _items[index];

    return _enqueueOperation(
      () =>
          _cartService.updateQuantity(item: serverItem, quantity: newQuantity),
      operationName: 'increaseQty',
    );
  }

  // Legacy: thao tác dòng đầu tiên có productId.
  // Xử lý increaseQuantity: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái giỏ hàng.
  Future<bool> increaseQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index == -1) {
      return false;
    }

    return increaseQty(_items[index]);
  }

  // =========================================================
  // DECREASE
  // =========================================================

  // Cập nhật state (decreaseQty): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  Future<bool> decreaseQty(CartItemModel item) async {
    final index = _indexOfItem(item);

    if (index == -1) {
      return false;
    }

    final currentItem = _items[index];

    if (currentItem.quantity <= 1) {
      _items.removeAt(index);
      _clearError();
      notifyListeners();

      return _enqueueOperation(
        () => _cartService.removeItem(currentItem),
        operationName: 'decreaseQty/remove',
      );
    }

    final newQuantity = currentItem.quantity - 1;

    _items[index] = currentItem.copyWith(quantity: newQuantity);

    _clearError();
    notifyListeners();

    final serverItem = _items[index];

    return _enqueueOperation(
      () =>
          _cartService.updateQuantity(item: serverItem, quantity: newQuantity),
      operationName: 'decreaseQty',
    );
  }

  // Legacy: thao tác dòng đầu tiên có productId.
  // Xử lý decreaseQuantity: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái giỏ hàng.
  Future<bool> decreaseQuantity(String productId) async {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index == -1) {
      return false;
    }

    return decreaseQty(_items[index]);
  }

  // =========================================================
  // UPDATE QUANTITY
  // =========================================================

  // Cập nhật số lượng (updateQuantity): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<bool> updateQuantity({
    required String productId,
    required int quantity,
    String note = '',
  }) async {
    int index = _indexOfProductAndNote(productId, note);

    // Tương thích code cũ chưa truyền note.
    if (index == -1 && note.trim().isEmpty) {
      index = _items.indexWhere((item) => item.productId == productId);
    }

    if (index == -1) {
      return false;
    }

    final currentItem = _items[index];

    if (quantity <= 0) {
      _items.removeAt(index);
      _clearError();
      notifyListeners();

      return _enqueueOperation(
        () => _cartService.removeItem(currentItem),
        operationName: 'updateQuantity/remove',
      );
    }

    final updatedItem = currentItem.copyWith(quantity: quantity);

    _items[index] = updatedItem;

    _clearError();
    notifyListeners();

    return _enqueueOperation(
      () => _cartService.updateQuantity(item: updatedItem, quantity: quantity),
      operationName: 'updateQuantity',
    );
  }

  // =========================================================
  // REMOVE ONLY PURCHASED ITEMS
  // =========================================================

  // Xóa đã mua các mục (removePurchasedItems): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> removePurchasedItems(List<CartItemModel> purchasedItems) async {
    if (purchasedItems.isEmpty) return true;

    await _operationQueue;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    try {
      await _cartService.removePurchasedItems(purchasedItems);

      final purchasedKeys = purchasedItems
          .map((item) => '${item.productId}|${item.normalizedNote}')
          .toSet();

      // Cập nhật local state ngay, không tải lại toàn bộ cart và product.
      _items.removeWhere(
        (item) => purchasedKeys.contains('${item.productId}|${item.normalizedNote}'),
      );

      return true;
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''));
      debugPrint('removePurchasedItems cart sync error: $error');

      // Chỉ fallback reload khi thao tác xóa thực sự bị lỗi.
      try {
        final result = await _cartService.fetchActiveCartItems();
        _items
          ..clear()
          ..addAll(result);
      } catch (_) {}

      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // =========================================================
  // CLEAR CART
  // =========================================================

  // Xóa giỏ hàng (clearCart): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> clearCart() async {
    _items.clear();
    _clearError();
    notifyListeners();

    return _enqueueOperation(
      _cartService.clearActiveCartItems,
      operationName: 'clearCart',
    );
  }

  // Dùng sau khi create order thành công ở bước Order/Checkout:
  // cart hiện tại -> converted, lần mua tiếp theo sẽ tạo cart active mới.
  // Cập nhật state (convertCartAfterOrder): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  Future<bool> convertCartAfterOrder() async {
    _items.clear();
    _clearError();
    notifyListeners();

    return _enqueueOperation(
      _cartService.convertActiveCart,
      operationName: 'convertCartAfterOrder',
    );
  }

  // =========================================================
  // LOGOUT / ACCOUNT CHANGE
  // =========================================================

  /// Chờ các thao tác giỏ hàng đang xếp hàng hoàn tất trước khi đổi tài khoản.
  /// Tránh request của tài khoản cũ tiếp tục chạy sau khi authStore đã bị xóa.
  // Cập nhật state (waitForPendingOperations): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  Future<void> waitForPendingOperations() async {
    await _operationQueue;
  }

  /// Chỉ xóa state local và cache khi đăng xuất/đổi tài khoản.
  /// Không gọi API xóa giỏ hàng trên PocketBase.
  // Cập nhật state (resetCart): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  void resetCart() {
    _items.clear();
    _clearError();
    _cartService.resetCache();
    notifyListeners();
  }

  // =========================================================
  // OPERATION QUEUE
  // =========================================================

  // Cập nhật state (_enqueueOperation): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  Future<bool> _enqueueOperation(
    Future<void> Function() action, {
    required String operationName,
  }) {
    final completer = Completer<bool>();

    _operationQueue = _operationQueue.then((_) async {
      _isSyncing = true;
      notifyListeners();

      try {
        await action();

        _clearError();
        completer.complete(true);
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');

        _setError(message);

        debugPrint('$operationName cart sync error: $e');

        completer.complete(false);
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    });

    return completer.future;
  }

  // =========================================================
  // ERROR
  // =========================================================

  // Xóa error (clearError): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Cập nhật error (_setError): gán state nội bộ và thông báo lại cho UI khi cần.
  void _setError(String message) {
    _errorMessage = message;
  }

  // Xóa error (_clearError): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void _clearError() {
    _errorMessage = null;
  }
}
