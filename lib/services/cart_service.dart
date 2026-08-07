import 'package:CT466_project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:CT466_project_trangdc24v7x324/models/cart_item_model.dart';

class CartService {
  String? _cachedActiveCartId;
  String? _cachedUserId;

  String _requireUserId() {
    final authUser = pb.authStore.model;

    if (authUser == null || authUser.id.trim().isEmpty) {
      throw Exception('Chưa đăng nhập');
    }

    final userId = authUser.id.trim();

    if (_cachedUserId != userId) {
      _cachedUserId = userId;
      _cachedActiveCartId = null;
    }

    return userId;
  }

  Future<String?> getActiveCartId({bool createIfMissing = false}) async {
    final userId = _requireUserId();

    if (_cachedActiveCartId != null && _cachedActiveCartId!.isNotEmpty) {
      return _cachedActiveCartId;
    }

    final records = await pb
        .collection('carts')
        .getFullList(
          filter: 'user = "$userId" && status = "active"',
          sort: '-updated',
        );

    if (records.isNotEmpty) {
      final primaryCartId = records.first.id;
      _cachedActiveCartId = primaryCartId;

      if (records.length > 1) {
        for (final duplicateCart in records.skip(1)) {
          await _mergeCartInto(
            sourceCartId: duplicateCart.id,
            targetCartId: primaryCartId,
          );

          await pb
              .collection('carts')
              .update(duplicateCart.id, body: {'status': 'converted'});
        }
      }

      return primaryCartId;
    }

    if (!createIfMissing) {
      return null;
    }

    final created = await pb
        .collection('carts')
        .create(body: {'user': userId, 'status': 'active'});

    _cachedActiveCartId = created.id;
    return created.id;
  }

  Future<String> getOrCreateActiveCartId() async {
    final cartId = await getActiveCartId(createIfMissing: true);

    if (cartId == null || cartId.isEmpty) {
      throw Exception('Không thể tạo giỏ hàng');
    }

    return cartId;
  }

  Future<List<CartItemModel>> fetchActiveCartItems() async {
    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return <CartItemModel>[];
    }

    final itemRecords = await pb
        .collection('cart_items')
        .getFullList(filter: 'cart = "$cartId"', sort: 'created');

    if (itemRecords.isEmpty) {
      return <CartItemModel>[];
    }

    final List<CartItemModel> result = [];
    final Map<String, Map<String, String>> categoryCache = {};

    for (final itemRecord in itemRecords) {
      final productId = (itemRecord.data['product'] ?? '').toString().trim();

      if (productId.isEmpty) {
        continue;
      }

      try {
        final productRecord = await pb.collection('products').getOne(productId);

        final productData = productRecord.data;

        // Nếu field isAvailable chưa tồn tại ở dữ liệu cũ thì mặc định
        // vẫn coi sản phẩm đang bán để tránh xóa nhầm cart item.
        final dynamic rawAvailability = productData['isAvailable'];

        final bool isAvailable =
            rawAvailability == null ? true : _toBool(rawAvailability);

        final double originalPrice = _toDouble(productData['price']);

        // Trước checkout/cart refresh:
        // món đã ngừng bán hoặc có giá không hợp lệ sẽ bị loại khỏi
        // active cart trên PocketBase, không cho đi tiếp sang Payment.
        if (!isAvailable || originalPrice <= 0) {
          try {
            await pb.collection('cart_items').delete(itemRecord.id);
          } catch (_) {}

          continue;
        }

        final item = await _mapCartItem(
          cartItemRecord: itemRecord,
          productRecord: productRecord,
          categoryCache: categoryCache,
        );

        result.add(item);
      } catch (_) {
        // Product đã bị xóa thật khỏi database:
        // dọn luôn cart_item mồ côi để active cart sạch.
        try {
          await pb.collection('cart_items').delete(itemRecord.id);
        } catch (_) {}
      }
    }

    return result;
  }

  Future<void> addItem(CartItemModel item) async {
    if (item.productId.trim().isEmpty) {
      throw Exception('Sản phẩm không hợp lệ');
    }

    if (item.quantity <= 0) {
      throw Exception('Số lượng không hợp lệ');
    }

    final cartId = await getOrCreateActiveCartId();

    final existingRecord = await _findCartItemRecord(
      cartId: cartId,
      productId: item.productId,
      note: item.note,
    );

    if (existingRecord != null) {
      final currentQuantity = _toInt(existingRecord.data['quantity']);

      await pb
          .collection('cart_items')
          .update(
            existingRecord.id,
            body: {
              'quantity': currentQuantity + item.quantity,
              'note': item.note.trim(),
            },
          );

      return;
    }

    await pb
        .collection('cart_items')
        .create(
          body: {
            'cart': cartId,
            'product': item.productId,
            'quantity': item.quantity,
            'note': item.note.trim(),
          },
        );
  }

  Future<void> updateQuantity({
    required CartItemModel item,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(item);
      return;
    }

    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return;
    }

    final record = await _findCartItemRecord(
      cartId: cartId,
      productId: item.productId,
      note: item.note,
    );

    if (record == null) {
      await pb
          .collection('cart_items')
          .create(
            body: {
              'cart': cartId,
              'product': item.productId,
              'quantity': quantity,
              'note': item.note.trim(),
            },
          );

      return;
    }

    await pb
        .collection('cart_items')
        .update(
          record.id,
          body: {'quantity': quantity, 'note': item.note.trim()},
        );
  }

  Future<void> removeItem(CartItemModel item) async {
    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return;
    }

    final record = await _findCartItemRecord(
      cartId: cartId,
      productId: item.productId,
      note: item.note,
    );

    if (record == null) {
      return;
    }

    await pb.collection('cart_items').delete(record.id);
  }

  Future<void> removeByProductId(String productId) async {
    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return;
    }

    final records = await pb
        .collection('cart_items')
        .getFullList(filter: 'cart = "$cartId" && product = "$productId"');

    for (final record in records) {
      await pb.collection('cart_items').delete(record.id);
    }
  }

  // =========================================================
  // REMOVE PURCHASED ITEMS AFTER PARTIAL CHECKOUT
  // =========================================================

  Future<void> removePurchasedItems(List<CartItemModel> purchasedItems) async {
    if (purchasedItems.isEmpty) {
      return;
    }

    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return;
    }

    // Chỉ xóa đúng line được thanh toán:
    // productId + note.
    for (final item in purchasedItems) {
      await _deleteExactCartLine(
        cartId: cartId,
        productId: item.productId,
        note: item.note,
      );
    }

    // Kiểm tra lại để tránh trường hợp request đầu tiên bị lỗi mạng tạm thời.
    for (final item in purchasedItems) {
      final remainingMatches = await _findCartItemRecords(
        cartId: cartId,
        productId: item.productId,
        note: item.note,
      );

      if (remainingMatches.isNotEmpty) {
        await _deleteExactCartLine(
          cartId: cartId,
          productId: item.productId,
          note: item.note,
        );
      }
    }

    // Xác nhận các dòng đã mua thực sự không còn trong active cart.
    for (final item in purchasedItems) {
      final remainingMatches = await _findCartItemRecords(
        cartId: cartId,
        productId: item.productId,
        note: item.note,
      );

      if (remainingMatches.isNotEmpty) {
        throw Exception(
          'Đơn hàng đã tạo nhưng chưa thể cập nhật hết giỏ hàng. '
          'Vui lòng tải lại giỏ hàng.',
        );
      }
    }

    // Nếu cart không còn item nào thì chuyển cart -> converted.
    // Nếu còn item chưa chọn thanh toán thì GIỮ status = active.
    final remainingItems = await pb
        .collection('cart_items')
        .getFullList(filter: 'cart = "$cartId"');

    if (remainingItems.isEmpty) {
      await pb
          .collection('carts')
          .update(cartId, body: {'status': 'converted'});

      _cachedActiveCartId = null;
    }
  }

  Future<void> _deleteExactCartLine({
    required String cartId,
    required String productId,
    required String note,
  }) async {
    final records = await _findCartItemRecords(
      cartId: cartId,
      productId: productId,
      note: note,
    );

    for (final record in records) {
      await pb.collection('cart_items').delete(record.id);
    }
  }

  Future<List<dynamic>> _findCartItemRecords({
    required String cartId,
    required String productId,
    required String note,
  }) async {
    final records = await pb
        .collection('cart_items')
        .getFullList(
          filter:
              'cart = "$cartId" && '
              'product = "$productId"',
        );

    final normalizedNote = note.trim();

    return records.where((record) {
      final serverNote = (record.data['note'] ?? '').toString().trim();

      return serverNote == normalizedNote;
    }).toList();
  }

  Future<void> clearActiveCartItems() async {
    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return;
    }

    final records = await pb
        .collection('cart_items')
        .getFullList(filter: 'cart = "$cartId"');

    for (final record in records) {
      await pb.collection('cart_items').delete(record.id);
    }
  }

  Future<void> convertActiveCart() async {
    final cartId = await getActiveCartId();

    if (cartId == null || cartId.isEmpty) {
      return;
    }

    await pb.collection('carts').update(cartId, body: {'status': 'converted'});

    _cachedActiveCartId = null;
  }

  void resetCache() {
    _cachedActiveCartId = null;
    _cachedUserId = null;
  }

  Future<dynamic> _findCartItemRecord({
    required String cartId,
    required String productId,
    required String note,
  }) async {
    final records = await pb
        .collection('cart_items')
        .getFullList(
          filter:
              'cart = "$cartId" && '
              'product = "$productId"',
        );

    final normalizedNote = note.trim();

    for (final record in records) {
      final serverNote = (record.data['note'] ?? '').toString().trim();

      if (serverNote == normalizedNote) {
        return record;
      }
    }

    return null;
  }

  Future<void> _mergeCartInto({
    required String sourceCartId,
    required String targetCartId,
  }) async {
    final sourceItems = await pb
        .collection('cart_items')
        .getFullList(filter: 'cart = "$sourceCartId"');

    for (final sourceItem in sourceItems) {
      final productId = (sourceItem.data['product'] ?? '').toString().trim();

      if (productId.isEmpty) {
        continue;
      }

      final quantity = _toInt(sourceItem.data['quantity']);

      if (quantity <= 0) {
        continue;
      }

      final note = (sourceItem.data['note'] ?? '').toString().trim();

      final targetItem = await _findCartItemRecord(
        cartId: targetCartId,
        productId: productId,
        note: note,
      );

      if (targetItem == null) {
        await pb
            .collection('cart_items')
            .create(
              body: {
                'cart': targetCartId,
                'product': productId,
                'quantity': quantity,
                'note': note,
              },
            );
      } else {
        final targetQuantity = _toInt(targetItem.data['quantity']);

        await pb
            .collection('cart_items')
            .update(
              targetItem.id,
              body: {'quantity': targetQuantity + quantity},
            );
      }

      await pb.collection('cart_items').delete(sourceItem.id);
    }
  }

  Future<CartItemModel> _mapCartItem({
    required dynamic cartItemRecord,
    required dynamic productRecord,
    required Map<String, Map<String, String>> categoryCache,
  }) async {
    final productData = productRecord.data;

    final double originalPrice = _toDouble(productData['price']);

    final double salePrice = _toDouble(productData['salePrice']);

    final bool isOnSale = _toBool(productData['isOnSale']);

    final DateTime? saleStartAt = _toDateTime(productData['saleStartAt']);

    final DateTime? saleEndAt = _toDateTime(productData['saleEndAt']);

    final bool hasActiveSale = _hasActiveSale(
      originalPrice: originalPrice,
      salePrice: salePrice,
      isOnSale: isOnSale,
      saleStartAt: saleStartAt,
      saleEndAt: saleEndAt,
    );

    final double effectivePrice = hasActiveSale ? salePrice : originalPrice;

    final String categoryId = (productData['category'] ?? '').toString().trim();

    String categoryTitle = 'Khác';
    String categorySlug = 'khac';

    if (categoryId.isNotEmpty) {
      Map<String, String>? category = categoryCache[categoryId];

      if (category == null) {
        try {
          final categoryRecord = await pb
              .collection('categories')
              .getOne(categoryId);

          category = {
            'title': (categoryRecord.data['title'] ?? 'Khác').toString(),
            'slug': (categoryRecord.data['slug'] ?? 'khac').toString(),
          };

          categoryCache[categoryId] = category;
        } catch (_) {
          category = {'title': 'Khác', 'slug': 'khac'};
        }
      }

      categoryTitle = category['title'] ?? 'Khác';
      categorySlug = category['slug'] ?? 'khac';
    }

    final String fileName = (productData['image'] ?? '').toString().trim();

    final String image =
        fileName.isEmpty
            ? ''
            : '${pb.baseUrl}/api/files/products/'
                '${productRecord.id}/$fileName';

    return CartItemModel(
      productId: productRecord.id,
      title: (productData['title'] ?? '').toString(),
      image: image,
      price: effectivePrice,
      originalPrice: originalPrice,
      quantity: _toInt(cartItemRecord.data['quantity']),
      note: (cartItemRecord.data['note'] ?? '').toString().trim(),
      categoryId: categoryId,
      categoryTitle: categoryTitle,
      categorySlug: categorySlug,
    );
  }

  bool _hasActiveSale({
    required double originalPrice,
    required double salePrice,
    required bool isOnSale,
    required DateTime? saleStartAt,
    required DateTime? saleEndAt,
  }) {
    if (!isOnSale) {
      return false;
    }

    if (originalPrice <= 0 || salePrice <= 0 || salePrice >= originalPrice) {
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

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1' || text == 'yes';
  }

  DateTime? _toDateTime(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }
}
