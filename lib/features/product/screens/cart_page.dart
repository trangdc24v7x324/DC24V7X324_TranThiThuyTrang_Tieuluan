import 'package:CT466_project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:CT466_project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:CT466_project_trangdc24v7x324/routes/app_routes.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_card.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<String> _selectedKeys = <String>{};

  bool _selectionInitialized = false;
  bool _isCheckingCart = false;

  String _lineKey(CartItemModel item) {
    return '${item.productId}|${item.normalizedNote}';
  }

  String formatPrice(double price) {
    final String text = price.round().toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final int positionFromEnd = text.length - i;

      result.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        result.write('.');
      }
    }

    return '${result}đ';
  }

  void _syncSelectionWithCart(List<CartItemModel> items) {
    final currentKeys = items.map(_lineKey).toSet();

    _selectedKeys.removeWhere((key) => !currentKeys.contains(key));

    // Lần đầu vào Cart: mặc định chọn tất cả để giữ trải nghiệm cũ.
    if (!_selectionInitialized) {
      _selectedKeys.addAll(currentKeys);
      _selectionInitialized = true;
    }
  }

  List<CartItemModel> _selectedItems(List<CartItemModel> items) {
    return items.where((item) {
      return _selectedKeys.contains(_lineKey(item));
    }).toList();
  }

  void _toggleItem(CartItemModel item, bool selected) {
    final key = _lineKey(item);

    setState(() {
      if (selected) {
        _selectedKeys.add(key);
      } else {
        _selectedKeys.remove(key);
      }
    });
  }

  void _toggleAll(List<CartItemModel> items, bool selected) {
    setState(() {
      if (selected) {
        _selectedKeys.addAll(items.map(_lineKey));
      } else {
        _selectedKeys.clear();
      }
    });
  }

  Future<void> _confirmRemove(
    BuildContext context,
    CartProvider cart,
    CartItemModel item,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Xóa khỏi giỏ hàng'),
          content: Text(
            'Bạn có muốn xóa '
            '"${item.title}" khỏi giỏ hàng không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final String key = _lineKey(item);

    await cart.removeItem(item);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedKeys.remove(key);
    });
  }

  Map<String, _CartSnapshot> _takeSnapshot(List<CartItemModel> items) {
    return {
      for (final item in items)
        _lineKey(item): _CartSnapshot(
          price: item.price,
          originalPrice: item.effectiveOriginalPrice,
          quantity: item.quantity,
        ),
    };
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    if (_isCheckingCart) {
      return;
    }

    final selectedBefore = _selectedItems(cart.items);

    if (selectedBefore.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sản phẩm để thanh toán.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Set<String> selectedKeysBefore = selectedBefore.map(_lineKey).toSet();

    final before = _takeSnapshot(selectedBefore);

    setState(() {
      _isCheckingCart = true;
    });

    final bool refreshed = await cart.refreshCart();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCheckingCart = false;
      _selectedKeys.removeWhere(
        (key) => !cart.items.map(_lineKey).contains(key),
      );
    });

    if (!refreshed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cart.errorMessage ??
                'Không thể kiểm tra lại giỏ hàng. Vui lòng thử lại.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final List<CartItemModel> selectedAfter =
        cart.items.where((item) {
          return selectedKeysBefore.contains(_lineKey(item));
        }).toList();

    final Set<String> afterKeys = selectedAfter.map(_lineKey).toSet();

    final bool selectedItemMissing =
        selectedKeysBefore.length != afterKeys.length ||
        selectedKeysBefore.any((key) => !afterKeys.contains(key));

    if (selectedItemMissing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Một số sản phẩm đã chọn không còn khả dụng '
            'và đã được cập nhật khỏi giỏ hàng.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final after = _takeSnapshot(selectedAfter);

    bool priceChanged = false;
    bool quantityChanged = false;

    for (final key in selectedKeysBefore) {
      final oldItem = before[key];
      final newItem = after[key];

      if (oldItem == null || newItem == null) {
        continue;
      }

      if (oldItem.price != newItem.price ||
          oldItem.originalPrice != newItem.originalPrice) {
        priceChanged = true;
      }

      if (oldItem.quantity != newItem.quantity) {
        quantityChanged = true;
      }
    }

    if (priceChanged || quantityChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            priceChanged
                ? 'Giá hoặc khuyến mãi của sản phẩm đã chọn vừa thay đổi. '
                    'Vui lòng kiểm tra lại trước khi thanh toán.'
                : 'Số lượng sản phẩm đã chọn vừa được đồng bộ lại. '
                    'Vui lòng kiểm tra lại.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.payment,
      arguments: List<CartItemModel>.from(selectedAfter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.watch<CartProvider>();

    _syncSelectionWithCart(cart.items);

    final selectedItems = _selectedItems(cart.items);

    final double selectedOriginalTotal = selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.originalSubtotal,
    );

    final double selectedDiscount = selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.totalDiscount,
    );

    final double selectedTotal = selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    final bool hasSelectedDiscount = selectedDiscount > 0;

    final bool allSelected =
        cart.items.isNotEmpty && selectedItems.length == cart.items.length;

    return AppLayout(
      title: 'Đơn hàng của bạn',
      showBack: true,
      child: AppBody(
        child:
            cart.items.isEmpty
                ? const _EmptyCart()
                : Column(
                  children: [
                    _SelectAllBar(
                      value: allSelected,
                      selectedCount: selectedItems.length,
                      totalCount: cart.items.length,
                      enabled: !_isCheckingCart,
                      onChanged: (value) {
                        _toggleAll(cart.items, value);
                      },
                    ),

                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];

                          final bool selected = _selectedKeys.contains(
                            _lineKey(item),
                          );

                          return _CartItemCard(
                            item: item,
                            selected: selected,
                            selectionEnabled: !_isCheckingCart,
                            onSelected: (value) {
                              _toggleItem(item, value);
                            },
                            price: formatPrice(item.price),
                            originalPrice: formatPrice(
                              item.effectiveOriginalPrice,
                            ),
                            subtotal: formatPrice(item.subtotal),
                            totalDiscount: formatPrice(item.totalDiscount),
                            onDecrease:
                                _isCheckingCart
                                    ? null
                                    : () async {
                                      final String key = _lineKey(item);

                                      final bool willRemove =
                                          item.quantity <= 1;

                                      await cart.decreaseQty(item);

                                      if (!mounted) {
                                        return;
                                      }

                                      if (willRemove) {
                                        setState(() {
                                          _selectedKeys.remove(key);
                                        });
                                      }
                                    },
                            onIncrease:
                                _isCheckingCart
                                    ? null
                                    : () {
                                      cart.increaseQty(item);
                                    },
                            onRemove:
                                _isCheckingCart
                                    ? null
                                    : () {
                                      _confirmRemove(context, cart, item);
                                    },
                          );
                        },
                      ),
                    ),

                    _CheckoutBox(
                      originalTotal: formatPrice(selectedOriginalTotal),
                      discount: formatPrice(selectedDiscount),
                      total: formatPrice(selectedTotal),
                      hasDiscount: hasSelectedDiscount,
                      selectedCount: selectedItems.length,
                      isChecking: _isCheckingCart,
                      onCheckout:
                          _isCheckingCart || selectedItems.isEmpty
                              ? null
                              : () {
                                _handleCheckout(context, cart);
                              },
                    ),
                  ],
                ),
      ),
    );
  }
}

class _SelectAllBar extends StatelessWidget {
  final bool value;
  final int selectedCount;
  final int totalCount;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SelectAllBar({
    required this.value,
    required this.selectedCount,
    required this.totalCount,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.primary,
            onChanged:
                enabled
                    ? (checked) {
                      onChanged(checked ?? false);
                    }
                    : null,
          ),
          const Expanded(
            child: Text(
              'Chọn tất cả',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$selectedCount/$totalCount sản phẩm',
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text('Giỏ hàng đang trống', style: AppText.body),
          const SizedBox(height: 6),
          Text(
            'Hãy thêm món ăn bạn yêu thích.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final bool selected;
  final bool selectionEnabled;

  final ValueChanged<bool> onSelected;

  final String price;
  final String originalPrice;
  final String subtotal;
  final String totalDiscount;

  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onRemove;

  const _CartItemCard({
    required this.item,
    required this.selected,
    required this.selectionEnabled,
    required this.onSelected,
    required this.price,
    required this.originalPrice,
    required this.subtotal,
    required this.totalDiscount,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 20),
                child: Checkbox(
                  value: selected,
                  activeColor: AppColors.primary,
                  onChanged:
                      selectionEnabled
                          ? (value) {
                            onSelected(value ?? false);
                          }
                          : null,
                ),
              ),

              _CartImage(image: item.image),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.productTitle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onRemove,
                          borderRadius: BorderRadius.circular(99),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (item.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ghi chú: ${item.note}',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 7),

                    if (item.hasDiscount)
                      Row(
                        children: [
                          Text(price, style: AppText.price),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              originalPrice,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF2A39),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '-${item.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(price, style: AppText.price),

                    const SizedBox(height: 9),

                    _QuantityControl(
                      quantity: item.quantity,
                      onDecrease: onDecrease,
                      onIncrease: onIncrease,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'Tạm tính',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const Spacer(),
              Text(
                subtotal,
                style: AppText.productTitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (item.hasDiscount) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  'Tiết kiệm',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                ),
                const Spacer(),
                Text(
                  totalDiscount,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  final String image;

  const _CartImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _FoodImage(image: image),
    );
  }
}

class _FoodImage extends StatelessWidget {
  final String image;

  const _FoodImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) {
      return const Icon(Icons.fastfood, color: Colors.grey);
    }

    final bool isNetwork =
        image.startsWith('http://') || image.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        image,
        fit: BoxFit.contain,
        errorBuilder:
            (_, __, ___) => const Icon(Icons.fastfood, color: Colors.grey),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.contain,
      errorBuilder:
          (_, __, ___) => const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(icon: Icons.remove, onTap: onDecrease),
        SizedBox(
          width: 38,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppText.productTitle,
          ),
        ),
        _QtyButton(icon: Icons.add, onTap: onIncrease),
      ],
    );
  }
}

class _CheckoutBox extends StatelessWidget {
  final String originalTotal;
  final String discount;
  final String total;

  final bool hasDiscount;
  final int selectedCount;
  final bool isChecking;

  final VoidCallback? onCheckout;

  const _CheckoutBox({
    required this.originalTotal,
    required this.discount,
    required this.total,
    required this.hasDiscount,
    required this.selectedCount,
    required this.isChecking,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDiscount) ...[
              Row(
                children: [
                  Text(
                    'Tạm tính theo giá gốc',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    originalTotal,
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Text(
                    'Khuyến mãi',
                    style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '-$discount',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Text('Tổng tiền', style: AppText.productTitle),
                const Spacer(),
                Text(total, style: AppText.total),
              ],
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedCount == 0
                    ? 'Chưa chọn sản phẩm'
                    : 'Đã chọn $selectedCount dòng sản phẩm',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onCheckout,
                child:
                    isChecking
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          selectedCount > 0
                              ? 'Thanh toán ($selectedCount)'
                              : 'Chọn sản phẩm để thanh toán',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade200 : AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey.shade400 : AppColors.textDark,
        ),
      ),
    );
  }
}

class _CartSnapshot {
  final double price;
  final double originalPrice;
  final int quantity;

  const _CartSnapshot({
    required this.price,
    required this.originalPrice,
    required this.quantity,
  });
}