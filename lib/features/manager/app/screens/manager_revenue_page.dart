import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';

class ManagerRevenuePage extends StatefulWidget {
  const ManagerRevenuePage({super.key});

  @override
  State<ManagerRevenuePage> createState() => _ManagerRevenuePageState();
}

class _ManagerRevenuePageState extends State<ManagerRevenuePage> {
  static const Color primaryRed = Color(0xFFEF2A39);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color surface = Colors.white;
  static const Color softBg = Color(0xFFF7F7F9);

  String _range = 'today';
  DateTimeRange? _customRange;

  final Map<String, String> _paymentStatusByOrderId = {};
  final Map<String, _RatingStat> _ratingByProductId = {};
  final Map<String, String> _productNameById = {};

  bool _isAuxLoading = false;
  String? _auxError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<OrderProvider>().loadAllOrders(),
      _loadAuxiliaryData(),
    ]);
  }

  Future<void> _loadAuxiliaryData() async {
    if (mounted) {
      setState(() {
        _isAuxLoading = true;
        _auxError = null;
      });
    }

    final paymentMap = <String, String>{};
    final productNames = <String, String>{};
    final ratingMap = <String, _RatingStat>{};
    final errors = <String>[];

    // =========================================================
    // PAYMENT STATUS THẬT
    // =========================================================
    try {
      final records = await pb
          .collection('payments')
          .getFullList(sort: '-updated');

      for (final record in records) {
        final orderId = (record.data['order'] ?? '').toString().trim();
        final status = (record.data['status'] ?? '').toString().trim();

        if (orderId.isEmpty || status.isEmpty) {
          continue;
        }

        // Đã sort -updated nên chỉ giữ trạng thái mới nhất của mỗi order.
        paymentMap.putIfAbsent(orderId, () => status);
      }
    } catch (e) {
      debugPrint('APP REVENUE LOAD PAYMENTS ERROR: $e');
      errors.add('thanh toán');
    }

    // =========================================================
    // PRODUCT NAME
    // =========================================================
    try {
      final products = await pb
          .collection('products')
          .getFullList(sort: 'title');

      for (final record in products) {
        final title = (record.data['title'] ?? '').toString().trim();

        productNames[record.id] = title.isEmpty ? 'Sản phẩm' : title;
      }
    } catch (e) {
      debugPrint('APP REVENUE LOAD PRODUCTS ERROR: $e');
      errors.add('sản phẩm');
    }

    // =========================================================
    // RATING THẬT
    // =========================================================
    try {
      final reviews = await pb
          .collection('product_reviews')
          .getFullList(sort: '-created');

      final totals = <String, double>{};
      final counts = <String, int>{};

      for (final record in reviews) {
        final productId =
            (record.data['product'] ?? record.data['productId'] ?? '')
                .toString()
                .trim();

        final rawRating = record.data['rating'];

        final rating =
            rawRating is num
                ? rawRating.toDouble()
                : double.tryParse(rawRating?.toString() ?? '') ?? 0;

        if (productId.isEmpty || rating < 1 || rating > 5) {
          continue;
        }

        totals[productId] = (totals[productId] ?? 0) + rating;
        counts[productId] = (counts[productId] ?? 0) + 1;
      }

      for (final entry in counts.entries) {
        final productId = entry.key;
        final count = entry.value;
        final total = totals[productId] ?? 0;

        ratingMap[productId] = _RatingStat(
          productId: productId,
          productName: productNames[productId] ?? 'Sản phẩm',
          average: count == 0 ? 0 : total / count,
          count: count,
        );
      }
    } catch (e) {
      debugPrint('APP REVENUE LOAD REVIEWS ERROR: $e');
      errors.add('đánh giá');
    }

    if (!mounted) return;

    setState(() {
      _paymentStatusByOrderId
        ..clear()
        ..addAll(paymentMap);

      _productNameById
        ..clear()
        ..addAll(productNames);

      _ratingByProductId
        ..clear()
        ..addAll(ratingMap);

      _isAuxLoading = false;

      _auxError =
          errors.isEmpty ? null : 'Chưa tải được dữ liệu ${errors.join(', ')}';
    });
  }

  // =========================================================
  // DATE RANGE
  // =========================================================

  DateTimeRange? get _activeRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_range) {
      case 'today':
        return DateTimeRange(
          start: today,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );

      case '7d':
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );

      case '30d':
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );

      case 'custom':
        if (_customRange == null) return null;

        return DateTimeRange(
          start: DateTime(
            _customRange!.start.year,
            _customRange!.start.month,
            _customRange!.start.day,
          ),
          end: DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
            23,
            59,
            59,
            999,
          ),
        );

      default:
        return null;
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(const Duration(days: 6)),
            end: DateTime(now.year, now.month, now.day),
          ),
      helpText: 'Chọn thời gian thống kê',
      cancelText: 'Hủy',
      confirmText: 'Áp dụng',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _customRange = picked;
      _range = 'custom';
    });
  }

  void _selectRange(String value) {
    setState(() {
      _range = value;
    });
  }

  String _rangeLabel() {
    if (_range == 'custom' && _customRange != null) {
      return '${_formatDay(_customRange!.start)} - '
          '${_formatDay(_customRange!.end)}';
    }

    switch (_range) {
      case 'today':
        return 'Hôm nay';
      case '7d':
        return '7 ngày gần nhất';
      case '30d':
        return '30 ngày gần nhất';
      case 'all':
        return 'Toàn bộ thời gian';
      default:
        return 'Khoảng đã chọn';
    }
  }

  // =========================================================
  // FILTER DATA
  // =========================================================

  String _effectivePaymentStatus(OrderModel order) {
    // Manager xác nhận paid (đặc biệt COD/tiền mặt) được ưu tiên.
    if (order.paymentStatus == 'paid') {
      return 'paid';
    }

    // QR/MoMo lấy trạng thái chi tiết từ payments.
    return _paymentStatusByOrderId[order.id] ?? order.paymentStatus;
  }

  DateTime _businessDate(OrderModel order) {
    // Model chưa có completed_at riêng.
    // Dùng updated của đơn hoàn thành và chuyển local timezone.
    return (order.updated ?? order.created ?? order.orderDate).toLocal();
  }

  bool _insideRange(DateTime date) {
    final range = _activeRange;

    if (range == null) {
      return true;
    }

    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  List<OrderModel> _qualifiedOrders(List<OrderModel> orders) {
    final result =
        orders.where((order) {
          if (!order.isCompleted) {
            return false;
          }

          if (_effectivePaymentStatus(order) != 'paid') {
            return false;
          }

          return _insideRange(_businessDate(order));
        }).toList();

    result.sort((a, b) => _businessDate(b).compareTo(_businessDate(a)));

    return result;
  }

  List<_ProductSaleStat> _buildProductStats(List<OrderModel> orders) {
    final map = <String, _ProductSaleStat>{};

    for (final order in orders) {
      for (final item in order.items) {
        final productId = item.productId.trim();
        final productName =
            item.productName.trim().isEmpty
                ? 'Sản phẩm'
                : item.productName.trim();

        final key =
            productId.isNotEmpty
                ? productId
                : 'name:${productName.toLowerCase()}';

        final stat = map.putIfAbsent(
          key,
          () => _ProductSaleStat(productId: productId, name: productName),
        );

        stat.quantity += item.quantity;
        stat.revenue += item.subtotal;

        if (productId.isNotEmpty) {
          final rating = _ratingByProductId[productId];

          if (rating != null) {
            stat.rating = rating.average;
            stat.reviewCount = rating.count;
          }
        }
      }
    }

    final result = map.values.toList();

    result.sort((a, b) {
      final byQuantity = b.quantity.compareTo(a.quantity);

      if (byQuantity != 0) {
        return byQuantity;
      }

      return b.revenue.compareTo(a.revenue);
    });

    return result;
  }

  // =========================================================
  // BOTTOM SHEETS
  // =========================================================

  Future<void> _showAllSoldProducts(List<_ProductSaleStat> products) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetContainer(
          title: 'Hàng hóa đã bán',
          subtitle: _rangeLabel(),
          child:
              products.isEmpty
                  ? const _EmptyMessage(
                    message: 'Chưa có hàng hóa bán trong khoảng này.',
                  )
                  : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F0F2)),
                    itemBuilder: (context, index) {
                      final item = products[index];

                      return _SoldProductRow(rank: index + 1, item: item);
                    },
                  ),
        );
      },
    );
  }

  Future<void> _showAllRatings(List<_RatingStat> ratings) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetContainer(
          title: 'Đánh giá khách hàng',
          subtitle: 'Rating thực tế theo sản phẩm',
          child:
              ratings.isEmpty
                  ? const _EmptyMessage(
                    message: 'Chưa có đánh giá từ khách hàng.',
                  )
                  : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: ratings.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF0F0F2)),
                    itemBuilder: (context, index) {
                      final item = ratings[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 3,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        title: Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text('${item.count} đánh giá thực tế'),
                        trailing: Text(
                          item.average.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    final orders = _qualifiedOrders(provider.orders);
    final productStats = _buildProductStats(orders);

    final productRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.subtotal,
    );

    final deliveryRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.deliveryFee,
    );

    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    final soldQuantity = orders.fold<int>(
      0,
      (sum, order) =>
          sum +
          order.items.fold<int>(0, (itemSum, item) => itemSum + item.quantity),
    );

    final ratings =
        _ratingByProductId.values.toList()..sort((a, b) {
          final byCount = b.count.compareTo(a.count);

          if (byCount != 0) {
            return byCount;
          }

          return b.average.compareTo(a.average);
        });

    final totalReviewCount = ratings.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );

    final averageRating =
        totalReviewCount == 0
            ? 0.0
            : ratings.fold<double>(
                  0,
                  (sum, item) => sum + item.average * item.count,
                ) /
                totalReviewCount;

    final loading =
        (provider.isLoading && provider.orders.isEmpty) ||
        (_isAuxLoading && provider.orders.isEmpty);

    return AppLayout(
      title: 'Doanh thu',
      showBack: true,
      child: AppBody(
        child:
            loading
                ? const Center(
                  child: CircularProgressIndicator(color: primaryRed),
                )
                : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
                    children: [
                      _RangeFilterCard(
                        selectedRange: _range,
                        rangeLabel: _rangeLabel(),
                        onSelect: _selectRange,
                        onCustom: _pickCustomRange,
                      ),

                      if (_auxError != null) ...[
                        const SizedBox(height: 10),
                        _WarningCard(message: _auxError!),
                      ],

                      if ((provider.isLoading || _isAuxLoading) &&
                          provider.orders.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(
                          minHeight: 3,
                          color: primaryRed,
                        ),
                      ],

                      const SizedBox(height: 13),

                      _RevenueHeroCard(
                        totalRevenue: totalRevenue,
                        orderCount: orders.length,
                        rangeLabel: _rangeLabel(),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _MiniKpiCard(
                              label: 'Tiền sản phẩm',
                              value: _formatMoney(productRevenue),
                              icon: Icons.fastfood_rounded,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniKpiCard(
                              label: 'Phí giao hàng',
                              value: _formatMoney(deliveryRevenue),
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _SoldQuantityCard(
                        quantity: soldQuantity,
                        orderCount: orders.length,
                        onTap:
                            productStats.isEmpty
                                ? null
                                : () => _showAllSoldProducts(productStats),
                      ),

                      const SizedBox(height: 13),

                      _RevenueSplitCard(
                        totalRevenue: totalRevenue,
                        productRevenue: productRevenue,
                        deliveryRevenue: deliveryRevenue,
                      ),

                      const SizedBox(height: 13),

                      _SectionCard(
                        title:
                            _range == 'today'
                                ? 'Hàng hóa bán hôm nay'
                                : 'Hàng hóa đã bán',
                        subtitle:
                            '${_rangeLabel()} • '
                            'đơn hoàn thành và đã thanh toán',
                        icon: Icons.inventory_2_outlined,
                        action:
                            productStats.length > 4
                                ? TextButton(
                                  onPressed:
                                      () => _showAllSoldProducts(productStats),
                                  child: const Text('Xem tất cả'),
                                )
                                : null,
                        child:
                            productStats.isEmpty
                                ? const _EmptyMessage(
                                  message:
                                      'Chưa có hàng hóa bán trong khoảng này.',
                                )
                                : Column(
                                  children: List.generate(
                                    productStats.length > 4
                                        ? 4
                                        : productStats.length,
                                    (index) {
                                      return _SoldProductRow(
                                        rank: index + 1,
                                        item: productStats[index],
                                      );
                                    },
                                  ),
                                ),
                      ),

                      const SizedBox(height: 13),

                      _SectionCard(
                        title: 'Đánh giá khách hàng',
                        subtitle:
                            totalReviewCount == 0
                                ? 'Chưa có rating thực tế'
                                : '${averageRating.toStringAsFixed(1)}/5 • '
                                    '$totalReviewCount lượt đánh giá',
                        icon: Icons.star_rate_rounded,
                        action:
                            ratings.isEmpty
                                ? null
                                : TextButton(
                                  onPressed: () => _showAllRatings(ratings),
                                  child: const Text('Xem chi tiết'),
                                ),
                        child:
                            ratings.isEmpty
                                ? const _EmptyMessage(
                                  message: 'Chưa có đánh giá từ khách hàng.',
                                )
                                : Column(
                                  children: List.generate(
                                    ratings.length > 4 ? 4 : ratings.length,
                                    (index) {
                                      final item = ratings[index];

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: textDark,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _RatingBadge(
                                              average: item.average,
                                              count: item.count,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

// ===========================================================
// FILTER
// ===========================================================

class _RangeFilterCard extends StatelessWidget {
  final String selectedRange;
  final String rangeLabel;
  final ValueChanged<String> onSelect;
  final VoidCallback onCustom;

  const _RangeFilterCard({
    required this.selectedRange,
    required this.rangeLabel,
    required this.onSelect,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: _ManagerRevenuePageState.primaryRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Khoảng thống kê',
                style: TextStyle(
                  color: _ManagerRevenuePageState.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            rangeLabel,
            style: const TextStyle(
              color: _ManagerRevenuePageState.textMuted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _RangeChip(
                label: 'Hôm nay',
                selected: selectedRange == 'today',
                onTap: () => onSelect('today'),
              ),
              _RangeChip(
                label: '7 ngày',
                selected: selectedRange == '7d',
                onTap: () => onSelect('7d'),
              ),
              _RangeChip(
                label: '30 ngày',
                selected: selectedRange == '30d',
                onTap: () => onSelect('30d'),
              ),
              _RangeChip(
                label: 'Toàn bộ',
                selected: selectedRange == 'all',
                onTap: () => onSelect('all'),
              ),
              _RangeChip(
                label: selectedRange == 'custom' ? rangeLabel : 'Tự chọn',
                selected: selectedRange == 'custom',
                icon: Icons.date_range_rounded,
                onTap: onCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar:
          icon == null
              ? null
              : Icon(
                icon,
                size: 15,
                color:
                    selected
                        ? Colors.white
                        : _ManagerRevenuePageState.textMuted,
              ),
      label: Text(label),
      selectedColor: _ManagerRevenuePageState.primaryRed,
      backgroundColor: _ManagerRevenuePageState.softBg,
      side: BorderSide(
        color:
            selected
                ? _ManagerRevenuePageState.primaryRed
                : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ManagerRevenuePageState.textDark,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    );
  }
}

// ===========================================================
// KPI
// ===========================================================

class _RevenueHeroCard extends StatelessWidget {
  final double totalRevenue;
  final int orderCount;
  final String rangeLabel;

  const _RevenueHeroCard({
    required this.totalRevenue,
    required this.orderCount,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5364), _ManagerRevenuePageState.primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: _ManagerRevenuePageState.primaryRed.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thu đã xác nhận',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatMoney(totalRevenue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$orderCount đơn • $rangeLabel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ManagerRevenuePageState.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _ManagerRevenuePageState.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldQuantityCard extends StatelessWidget {
  final int quantity;
  final int orderCount;
  final VoidCallback? onTap;

  const _SoldQuantityCard({
    required this.quantity,
    required this.orderCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDEDF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$quantity sản phẩm đã bán',
                      style: const TextStyle(
                        color: _ManagerRevenuePageState.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$orderCount đơn hợp lệ'
                      '${onTap == null ? '' : ' • Bấm để xem'}',
                      style: const TextStyle(
                        color: _ManagerRevenuePageState.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _ManagerRevenuePageState.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// SPLIT
// ===========================================================

class _RevenueSplitCard extends StatelessWidget {
  final double totalRevenue;
  final double productRevenue;
  final double deliveryRevenue;

  const _RevenueSplitCard({
    required this.totalRevenue,
    required this.productRevenue,
    required this.deliveryRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final productRatio =
        totalRevenue <= 0 ? 0.0 : productRevenue / totalRevenue;
    final deliveryRatio =
        totalRevenue <= 0 ? 0.0 : deliveryRevenue / totalRevenue;

    return _SectionCard(
      title: 'Cơ cấu khoản thu',
      subtitle: 'Tách tiền sản phẩm và phí giao hàng',
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        children: [
          _RevenuePartRow(
            label: 'Tiền sản phẩm',
            value: productRevenue,
            ratio: productRatio,
            color: const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 13),
          _RevenuePartRow(
            label: 'Phí giao hàng',
            value: deliveryRevenue,
            ratio: deliveryRatio,
            color: const Color(0xFF0891B2),
          ),
        ],
      ),
    );
  }
}

class _RevenuePartRow extends StatelessWidget {
  final String label;
  final double value;
  final double ratio;
  final Color color;

  const _RevenuePartRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeRatio = ratio.clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ManagerRevenuePageState.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _formatMoney(value),
              style: const TextStyle(
                color: _ManagerRevenuePageState.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: safeRatio,
            minHeight: 7,
            backgroundColor: _ManagerRevenuePageState.softBg,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: _ManagerRevenuePageState.textMuted,
              fontSize: 9.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// SOLD PRODUCTS
// ===========================================================

class _SoldProductRow extends StatelessWidget {
  final int rank;
  final _ProductSaleStat item;

  const _SoldProductRow({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  rank <= 3
                      ? const Color(0xFFFFF7ED)
                      : _ManagerRevenuePageState.softBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color:
                    rank <= 3
                        ? const Color(0xFFC2410C)
                        : _ManagerRevenuePageState.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ManagerRevenuePageState.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.quantity} món • ${_formatMoney(item.revenue)}',
                  style: const TextStyle(
                    color: _ManagerRevenuePageState.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          _RatingBadge(
            average: item.rating,
            count: item.reviewCount,
            compact: true,
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// RATING
// ===========================================================

class _RatingBadge extends StatelessWidget {
  final double average;
  final int count;
  final bool compact;

  const _RatingBadge({
    required this.average,
    required this.count,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: _ManagerRevenuePageState.softBg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          'Chưa có',
          style: TextStyle(
            color: _ManagerRevenuePageState.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
          const SizedBox(width: 2),
          Text(
            compact
                ? average.toStringAsFixed(1)
                : '${average.toStringAsFixed(1)} ($count)',
            style: const TextStyle(
              color: Color(0xFFB45309),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// COMMON
// ===========================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _ManagerRevenuePageState.primaryRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _ManagerRevenuePageState.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ManagerRevenuePageState.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ManagerRevenuePageState.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _WhiteCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _ManagerRevenuePageState.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String message;

  const _WarningCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ManagerRevenuePageState.textMuted,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _BottomSheetContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      top: false,
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ManagerRevenuePageState.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _ManagerRevenuePageState.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// DATA
// ===========================================================

class _ProductSaleStat {
  final String productId;
  final String name;

  int quantity = 0;
  double revenue = 0;
  double rating = 0;
  int reviewCount = 0;

  _ProductSaleStat({required this.productId, required this.name});
}

class _RatingStat {
  final String productId;
  final String productName;
  final double average;
  final int count;

  const _RatingStat({
    required this.productId,
    required this.productName,
    required this.average,
    required this.count,
  });
}

// ===========================================================
// FORMAT
// ===========================================================

String _formatDay(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');

  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

String _formatMoney(double value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);

    final remaining = digits.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
  }

  return '${negative ? '-' : ''}${buffer}đ';
}
