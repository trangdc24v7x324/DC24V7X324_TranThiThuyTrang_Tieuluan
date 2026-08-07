import 'dart:async';

import 'package:flutter/material.dart';

import 'package:CT466_project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/product_model.dart';
import 'package:CT466_project_trangdc24v7x324/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService;

  final List<CartItemModel> _items = [];

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  // Hàng đợi giúp các thao tác + / - / xóa chạy tuần tự,
  // tránh request PocketBase hoàn thành sai thứ tự khi người dùng bấm nhanh.
  Future<void> _operationQueue = Future<void>.value();

  CartProvider({CartService? cartService})
    : _cartService = cartService ?? CartService();

  // =========================================================
  // GETTERS
  // =========================================================

  List<CartItemModel> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  bool get isLoading => _isLoading;

  bool get isSyncing => _isSyncing;

  String? get errorMessage => _errorMessage;

  int get itemCount {
    return _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  int get uniqueItemCount => _items.length;

  double get totalPrice {
    return _items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  double get totalOriginalPrice {
    return _items.fold<double>(0, (sum, item) => sum + item.originalSubtotal);
  }

  double get totalDiscount {
    return _items.fold<double>(0, (sum, item) => sum + item.totalDiscount);
  }

  bool get hasDiscount => totalDiscount > 0;

  // =========================================================
  // LOAD FROM POCKETBASE
  // =========================================================

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

  bool containsProduct(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  CartItemModel? getItemByProductId(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  int _indexOfItem(CartItemModel item) {
    return _items.indexWhere((element) => element.sameLine(item));
  }

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

  Future<bool> removePurchasedItems(List<CartItemModel> purchasedItems) async {
    if (purchasedItems.isEmpty) {
      return true;
    }

    // Chờ toàn bộ thao tác +/-/xóa trước đó ghi xuống PocketBase xong.
    await _operationQueue;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    try {
      await _cartService.removePurchasedItems(purchasedItems);

      // Đọc lại server để local state chính xác tuyệt đối:
      // item chưa mua vẫn còn, item đã mua biến mất.
      final result = await _cartService.fetchActiveCartItems();

      _items
        ..clear()
        ..addAll(result);

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));

      debugPrint('removePurchasedItems cart sync error: $e');

      // Dù có lỗi, vẫn cố đọc lại server để UI phản ánh trạng thái thật.
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
  Future<void> waitForPendingOperations() async {
    await _operationQueue;
  }

  /// Chỉ xóa state local và cache khi đăng xuất/đổi tài khoản.
  /// Không gọi API xóa giỏ hàng trên PocketBase.
  void resetCart() {
    _items.clear();
    _clearError();
    _cartService.resetCache();
    notifyListeners();
  }

  // =========================================================
  // OPERATION QUEUE
  // =========================================================

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

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }
}
