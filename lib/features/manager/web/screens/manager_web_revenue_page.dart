import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

class ManagerWebRevenuePage extends StatefulWidget {
  const ManagerWebRevenuePage({super.key});

  @override
  State<ManagerWebRevenuePage> createState() => _ManagerWebRevenuePageState();
}

class _ManagerWebRevenuePageState extends State<ManagerWebRevenuePage> {
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
      context.read<ProfileProvider>().loadProfile(forceReload: true),
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
    final ratingMap = <String, _RatingStat>{};
    final productNames = <String, String>{};
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

        // Đã sort -updated nên record đầu tiên là trạng thái mới nhất.
        paymentMap.putIfAbsent(orderId, () => status);
      }
    } catch (e) {
      debugPrint('REVENUE LOAD PAYMENTS ERROR: $e');
      errors.add('payments');
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

        if (record.id.isNotEmpty) {
          productNames[record.id] = title.isEmpty ? 'Sản phẩm' : title;
        }
      }
    } catch (e) {
      debugPrint('REVENUE LOAD PRODUCTS ERROR: $e');
      errors.add('products');
    }

    // =========================================================
    // RATING THẬT TỪ PRODUCT_REVIEWS
    // =========================================================
    try {
      final reviews = await pb
          .collection('product_reviews')
          .getFullList(sort: '-created');

      final ratingTotals = <String, double>{};
      final ratingCounts = <String, int>{};

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

        ratingTotals[productId] = (ratingTotals[productId] ?? 0) + rating;
        ratingCounts[productId] = (ratingCounts[productId] ?? 0) + 1;
      }

      for (final entry in ratingCounts.entries) {
        final productId = entry.key;
        final count = entry.value;
        final total = ratingTotals[productId] ?? 0;

        ratingMap[productId] = _RatingStat(
          productId: productId,
          productName: productNames[productId] ?? 'Sản phẩm',
          average: count == 0 ? 0 : total / count,
          count: count,
        );
      }
    } catch (e) {
      debugPrint('REVENUE LOAD REVIEWS ERROR: $e');
      errors.add('product_reviews');
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

      if (errors.isNotEmpty) {
        _auxError = 'Một phần dữ liệu chưa tải được: ${errors.join(', ')}';
      }
    });
  }

  // =========================================================
  // FILTER
  // =========================================================

  String _effectivePaymentStatus(OrderModel order) {
    // Manager đã xác nhận thanh toán, đặc biệt COD/Tiền mặt.
    if (order.paymentStatus == 'paid') {
      return 'paid';
    }

    // QR/MoMo demo ưu tiên trạng thái trong payments.
    return _paymentStatusByOrderId[order.id] ?? order.paymentStatus;
  }

  DateTime _businessDate(OrderModel order) {
    // DB hiện chưa có completed_at riêng.
    // updated là mốc gần nhất với lúc hoàn tất/xác nhận đơn.
    return (order.updated ?? order.created ?? order.orderDate).toLocal();
  }

  DateTimeRange? get _activeDateRange {
    final now = DateTime.now();

    switch (_range) {
      case 'today':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );

      case '7d':
        final today = DateTime(now.year, now.month, now.day);
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );

      case '30d':
        final today = DateTime(now.year, now.month, now.day);
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

  bool _isInsideSelectedRange(DateTime date) {
    final range = _activeDateRange;

    if (range == null) {
      return true;
    }

    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  List<OrderModel> _qualifiedOrders(List<OrderModel> source) {
    final result =
        source.where((order) {
          if (!order.isCompleted) {
            return false;
          }

          if (_effectivePaymentStatus(order) != 'paid') {
            return false;
          }

          return _isInsideSelectedRange(_businessDate(order));
        }).toList();

    result.sort((a, b) => _businessDate(a).compareTo(_businessDate(b)));

    return result;
  }

  Future<void> _selectCustomRange() async {
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
      helpText: 'Chọn khoảng thời gian thống kê',
      cancelText: 'Hủy',
      confirmText: 'Áp dụng',
      saveText: 'Áp dụng',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _customRange = picked;
      _range = 'custom';
    });
  }

  void _selectPreset(String value) {
    setState(() {
      _range = value;
    });
  }

  // =========================================================
  // DIALOGS
  // =========================================================

  Future<void> _showSoldProductsDialog(List<_ProductStat> products) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
            child: Column(
              children: [
                _DialogHeader(
                  title: 'Chi tiết hàng hóa đã bán',
                  subtitle: _rangeDescription(),
                  icon: Icons.inventory_2_outlined,
                  onClose: () => Navigator.pop(dialogContext),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child:
                      products.isEmpty
                          ? const _AnalyticsEmpty(
                            message:
                                'Không có sản phẩm bán trong khoảng đã chọn.',
                          )
                          : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStatePropertyAll(
                                  AppColors.backgroundSecondary,
                                ),
                                columns: const [
                                  DataColumn(label: Text('SẢN PHẨM')),
                                  DataColumn(label: Text('SL BÁN')),
                                  DataColumn(label: Text('TIỀN MÓN')),
                                  DataColumn(label: Text('RATING')),
                                ],
                                rows:
                                    products.map((item) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            SizedBox(
                                              width: 260,
                                              child: Text(
                                                item.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('${item.quantity}')),
                                          DataCell(
                                            Text(_formatMoney(item.revenue)),
                                          ),
                                          DataCell(
                                            _RatingBadge(
                                              average: item.rating,
                                              count: item.reviewCount,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRatingsDialog(List<_RatingStat> ratings) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
            child: Column(
              children: [
                _DialogHeader(
                  title: 'Rating khách hàng theo sản phẩm',
                  subtitle:
                      'Điểm trung bình thực tế từ collection product_reviews',
                  icon: Icons.star_rate_rounded,
                  onClose: () => Navigator.pop(dialogContext),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child:
                      ratings.isEmpty
                          ? const _AnalyticsEmpty(
                            message: 'Chưa có đánh giá từ khách hàng.',
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: ratings.length,
                            separatorBuilder:
                                (_, __) =>
                                    const Divider(color: AppColors.border),
                            itemBuilder: (context, index) {
                              final item = ratings[index];

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                                title: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.count} đánh giá thực tế',
                                ),
                                trailing: Text(
                                  item.average.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // LABELS
  // =========================================================

  String _rangeDescription() {
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

  void _logout() {
    pb.authStore.clear();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';

    final avatarUrl = profile?.avatarUrl ?? '';

    // Chỉ tính đơn HOÀN THÀNH + ĐÃ THANH TOÁN.
    final qualifiedOrders = _qualifiedOrders(orderProvider.orders);

    // Doanh thu được tách rõ:
    // - Tiền sản phẩm: orders.subtotal (đã phản ánh giá sale)
    // - Phí giao hàng: orders.delivery_fee
    final productRevenue = qualifiedOrders.fold<double>(
      0,
      (sum, order) => sum + order.subtotal,
    );

    final deliveryRevenue = qualifiedOrders.fold<double>(
      0,
      (sum, order) => sum + order.deliveryFee,
    );

    final totalRevenue = productRevenue + deliveryRevenue;

    final soldQuantity = qualifiedOrders.fold<int>(
      0,
      (sum, order) =>
          sum +
          order.items.fold<int>(0, (itemSum, item) => itemSum + item.quantity),
    );

    final productStats = _buildProductStats(
      qualifiedOrders,
      _ratingByProductId,
    );

    final ratingStats =
        _ratingByProductId.values.toList()..sort((a, b) {
          final byCount = b.count.compareTo(a.count);

          if (byCount != 0) {
            return byCount;
          }

          return b.average.compareTo(a.average);
        });

    final chartPoints = _buildRevenueChartPoints(
      qualifiedOrders,
      _businessDate,
      _range,
      _customRange,
    );

    final totalReviewCount = ratingStats.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );

    final weightedRating =
        totalReviewCount == 0
            ? 0.0
            : ratingStats.fold<double>(
                  0,
                  (sum, item) => sum + item.average * item.count,
                ) /
                totalReviewCount;

    return ManagerWebLayout(
      title: 'Doanh thu & thống kê',
      currentRoute: AppRoutes.managerRevenue,
      managerName: managerName,
      avatarUrl: avatarUrl,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1100
                    ? 24.0
                    : constraints.maxWidth >= 700
                    ? 18.0
                    : 12.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(
                        selectedRange: _range,
                        rangeDescription: _rangeDescription(),
                        customRange: _customRange,
                        onPresetSelected: _selectPreset,
                        onCustomRange: _selectCustomRange,
                      ),

                      if (_auxError != null) ...[
                        const SizedBox(height: 10),
                        _CompactWarning(message: _auxError!),
                      ],

                      if ((orderProvider.isLoading || _isAuxLoading) &&
                          orderProvider.orders.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(
                          minHeight: 3,
                          color: AppColors.primary,
                        ),
                      ],

                      const SizedBox(height: 14),

                      _KpiGrid(
                        totalRevenue: totalRevenue,
                        productRevenue: productRevenue,
                        deliveryRevenue: deliveryRevenue,
                        soldQuantity: soldQuantity,
                        orderCount: qualifiedOrders.length,
                        onSoldProductsTap:
                            productStats.isEmpty
                                ? null
                                : () => _showSoldProductsDialog(productStats),
                      ),

                      const SizedBox(height: 14),

                      if (orderProvider.isLoading &&
                          orderProvider.orders.isEmpty)
                        const SizedBox(
                          height: 380,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (orderProvider.errorMessage != null &&
                          orderProvider.orders.isEmpty)
                        _ErrorCard(
                          message: orderProvider.errorMessage!,
                          onRetry: _loadData,
                        )
                      else ...[
                        LayoutBuilder(
                          builder: (context, inner) {
                            final wide = inner.maxWidth >= 980;

                            final chart = _RevenueChartCard(
                              title:
                                  'Doanh thu ${_rangeDescription().toLowerCase()}',
                              points: chartPoints,
                            );

                            final split = _RevenueSplitCard(
                              totalRevenue: totalRevenue,
                              productRevenue: productRevenue,
                              deliveryRevenue: deliveryRevenue,
                              orderCount: qualifiedOrders.length,
                            );

                            if (!wide) {
                              return Column(
                                children: [
                                  chart,
                                  const SizedBox(height: 14),
                                  split,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: chart),
                                const SizedBox(width: 14),
                                Expanded(flex: 4, child: split),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        LayoutBuilder(
                          builder: (context, inner) {
                            final wide = inner.maxWidth >= 900;

                            final soldCard = _SoldProductsCard(
                              title:
                                  _range == 'today'
                                      ? 'Hàng hóa bán hôm nay'
                                      : 'Hàng hóa đã bán',
                              subtitle:
                                  'Đơn hoàn thành và đã thanh toán • '
                                  '${_rangeDescription()}',
                              items: productStats.take(5).toList(),
                              onViewAll:
                                  productStats.length > 5
                                      ? () =>
                                          _showSoldProductsDialog(productStats)
                                      : null,
                            );

                            final ratingCard = _RatingsCard(
                              items: ratingStats.take(5).toList(),
                              averageRating: weightedRating,
                              totalReviewCount: totalReviewCount,
                              onViewAll:
                                  ratingStats.length > 5
                                      ? () => _showRatingsDialog(ratingStats)
                                      : ratingStats.isNotEmpty
                                      ? () => _showRatingsDialog(ratingStats)
                                      : null,
                            );

                            if (!wide) {
                              return Column(
                                children: [
                                  soldCard,
                                  const SizedBox(height: 14),
                                  ratingCard,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: soldCard),
                                const SizedBox(width: 14),
                                Expanded(flex: 5, child: ratingCard),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================
// HEADER + FILTER
// ===========================================================

class _DashboardHeader extends StatelessWidget {
  final String selectedRange;
  final String rangeDescription;
  final DateTimeRange? customRange;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onCustomRange;

  const _DashboardHeader({
    required this.selectedRange,
    required this.rangeDescription,
    required this.customRange,
    required this.onPresetSelected,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('today', 'Hôm nay'),
      ('7d', '7 ngày'),
      ('30d', '30 ngày'),
      ('all', 'Toàn bộ'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hiệu quả kinh doanh',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Đang thống kê: $rangeDescription • '
                'chỉ tính đơn hoàn thành và đã thanh toán.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          );

          final filterRow = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...filters.map((item) {
                final selected = selectedRange == item.$1;

                return ChoiceChip(
                  selected: selected,
                  label: Text(item.$2),
                  avatar: Icon(
                    item.$1 == 'today'
                        ? Icons.today_rounded
                        : Icons.date_range_rounded,
                    size: 16,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.backgroundSecondary,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => onPresetSelected(item.$1),
                );
              }),
              OutlinedButton.icon(
                onPressed: onCustomRange,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(
                  selectedRange == 'custom'
                      ? rangeDescription
                      : 'Tự chọn thời gian',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      selectedRange == 'custom'
                          ? AppColors.primary
                          : AppColors.textPrimary,
                  side: BorderSide(
                    color:
                        selectedRange == 'custom'
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), filterRow],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: filterRow,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================
// KPI
// ===========================================================

class _KpiGrid extends StatelessWidget {
  final double totalRevenue;
  final double productRevenue;
  final double deliveryRevenue;
  final int soldQuantity;
  final int orderCount;
  final VoidCallback? onSoldProductsTap;

  const _KpiGrid({
    required this.totalRevenue,
    required this.productRevenue,
    required this.deliveryRevenue,
    required this.soldQuantity,
    required this.orderCount,
    required this.onSoldProductsTap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        label: 'Tổng thu đã xác nhận',
        value: _formatMoney(totalRevenue),
        note: '$orderCount đơn hoàn thành',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.primary,
      ),
      _KpiCard(
        label: 'Tiền sản phẩm',
        value: _formatMoney(productRevenue),
        note: 'Không gồm phí giao hàng',
        icon: Icons.fastfood_rounded,
        color: const Color(0xFF4F46E5),
      ),
      _KpiCard(
        label: 'Phí giao hàng',
        value: _formatMoney(deliveryRevenue),
        note: 'Thu từ giao nhận',
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF0891B2),
      ),
      _KpiCard(
        label: 'Sản phẩm đã bán',
        value: '$soldQuantity',
        note:
            onSoldProductsTap == null
                ? 'Chưa có hàng bán'
                : 'Bấm để xem chi tiết',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFF59E0B),
        onTap: onSoldProductsTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 1120) {
          columns = 4;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        }

        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// REVENUE CHART
// ===========================================================

class _RevenueChartCard extends StatelessWidget {
  final String title;
  final List<_ChartPoint> points;

  const _RevenueChartCard({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
      0,
      (current, item) => current > item.value ? current : item.value,
    );

    return _DashboardCard(
      title: title,
      subtitle: 'Tổng thu = tiền sản phẩm + phí giao hàng',
      icon: Icons.bar_chart_rounded,
      child:
          points.isEmpty
              ? const _AnalyticsEmpty(
                message: 'Chưa có doanh thu hợp lệ trong khoảng thời gian này.',
              )
              : SizedBox(
                height: 235,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:
                        points.map((point) {
                          final ratio =
                              maxValue <= 0 ? 0.0 : point.value / maxValue;

                          final barHeight =
                              math.max(8.0, ratio * 165).toDouble();

                          return SizedBox(
                            width: 70,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message:
                                        '${point.label}: '
                                        '${_formatMoney(point.value)}',
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      width: 32,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.80,
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    point.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
    );
  }
}

// ===========================================================
// REVENUE SPLIT
// ===========================================================

class _RevenueSplitCard extends StatelessWidget {
  final double totalRevenue;
  final double productRevenue;
  final double deliveryRevenue;
  final int orderCount;

  const _RevenueSplitCard({
    required this.totalRevenue,
    required this.productRevenue,
    required this.deliveryRevenue,
    required this.orderCount,
  });

  @override
  Widget build(BuildContext context) {
    final productRatio =
        totalRevenue <= 0 ? 0.0 : productRevenue / totalRevenue;
    final deliveryRatio =
        totalRevenue <= 0 ? 0.0 : deliveryRevenue / totalRevenue;

    return _DashboardCard(
      title: 'Cơ cấu khoản thu',
      subtitle: '$orderCount đơn đã ghi nhận',
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        children: [
          _SplitRow(
            label: 'Tiền sản phẩm',
            amount: productRevenue,
            ratio: productRatio,
            color: const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 16),
          _SplitRow(
            label: 'Phí giao hàng',
            amount: deliveryRevenue,
            ratio: deliveryRatio,
            color: const Color(0xFF0891B2),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tổng thu',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  _formatMoney(totalRevenue),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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

class _SplitRow extends StatelessWidget {
  final String label;
  final double amount;
  final double ratio;
  final Color color;

  const _SplitRow({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _formatMoney(amount),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.backgroundSecondary,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
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

class _SoldProductsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ProductStat> items;
  final VoidCallback? onViewAll;

  const _SoldProductsCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.inventory_2_outlined,
      trailing:
          onViewAll == null
              ? null
              : TextButton(
                onPressed: onViewAll,
                child: const Text('Xem tất cả'),
              ),
      child:
          items.isEmpty
              ? const _AnalyticsEmpty(
                message: 'Chưa có hàng hóa bán trong khoảng đã chọn.',
              )
              : Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 9,
                    ),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 9,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '${item.quantity} món',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(item.revenue),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RatingBadge(
                          average: item.rating,
                          count: item.reviewCount,
                          compact: true,
                        ),
                      ],
                    ),
                  );
                }),
              ),
    );
  }
}

// ===========================================================
// RATINGS
// ===========================================================

class _RatingsCard extends StatelessWidget {
  final List<_RatingStat> items;
  final double averageRating;
  final int totalReviewCount;
  final VoidCallback? onViewAll;

  const _RatingsCard({
    required this.items,
    required this.averageRating,
    required this.totalReviewCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Đánh giá khách hàng',
      subtitle:
          totalReviewCount == 0
              ? 'Chưa có rating thực tế'
              : '${averageRating.toStringAsFixed(1)}/5 • '
                  '$totalReviewCount lượt đánh giá',
      icon: Icons.star_rate_rounded,
      trailing:
          onViewAll == null
              ? null
              : TextButton(
                onPressed: onViewAll,
                child: const Text('Xem chi tiết'),
              ),
      child:
          items.isEmpty
              ? const _AnalyticsEmpty(
                message: 'Chưa có đánh giá từ khách hàng.',
              )
              : Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RatingBadge(average: item.average, count: item.count),
                      ],
                    ),
                  );
                }),
              ),
    );
  }
}

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
          horizontal: compact ? 7 : 9,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          'Chưa có',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
          const SizedBox(width: 3),
          Text(
            compact
                ? average.toStringAsFixed(1)
                : '${average.toStringAsFixed(1)} ($count)',
            style: const TextStyle(
              color: Color(0xFFB45309),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// COMMON CARD
// ===========================================================

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CompactWarning extends StatelessWidget {
  final String message;

  const _CompactWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$message. Các phần còn lại vẫn dùng dữ liệu fallback.',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsEmpty extends StatelessWidget {
  final String message;

  const _AnalyticsEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 135,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 50),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// DATA MODELS
// ===========================================================

class _ChartPoint {
  final String label;
  final double value;

  const _ChartPoint({required this.label, required this.value});
}

class _ProductStat {
  final String productId;
  final String name;

  int quantity = 0;
  double revenue = 0;
  double rating = 0;
  int reviewCount = 0;

  _ProductStat({required this.productId, required this.name});
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
// BUILD STATISTICS
// ===========================================================

List<_ProductStat> _buildProductStats(
  List<OrderModel> orders,
  Map<String, _RatingStat> ratings,
) {
  final map = <String, _ProductStat>{};

  for (final order in orders) {
    for (final item in order.items) {
      final productId = item.productId.trim();

      final name =
          item.productName.trim().isEmpty
              ? 'Sản phẩm'
              : item.productName.trim();

      final key =
          productId.isNotEmpty ? productId : 'name:${name.toLowerCase()}';

      final stat = map.putIfAbsent(
        key,
        () => _ProductStat(productId: productId, name: name),
      );

      stat.quantity += item.quantity;
      stat.revenue += item.subtotal;

      if (productId.isNotEmpty) {
        final rating = ratings[productId];

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

List<_ChartPoint> _buildRevenueChartPoints(
  List<OrderModel> orders,
  DateTime Function(OrderModel) businessDate,
  String range,
  DateTimeRange? customRange,
) {
  if (orders.isEmpty) {
    return const [];
  }

  // Hôm nay: hiển thị theo giờ để nhìn được hàng/doanh thu trong ngày.
  if (range == 'today') {
    final grouped = <int, double>{};

    for (final order in orders) {
      final date = businessDate(order);
      grouped[date.hour] =
          (grouped[date.hour] ?? 0) + order.subtotal + order.deliveryFee;
    }

    final hours = grouped.keys.toList()..sort();

    return hours
        .map(
          (hour) => _ChartPoint(
            label: '${hour.toString().padLeft(2, '0')}h',
            value: grouped[hour] ?? 0,
          ),
        )
        .toList();
  }

  final customDays =
      customRange == null
          ? 0
          : customRange.end.difference(customRange.start).inDays + 1;

  final useMonth = range == 'all' || (range == 'custom' && customDays > 60);

  final grouped = <String, double>{};

  for (final order in orders) {
    final date = businessDate(order);

    final key =
        useMonth
            ? '${date.year}-'
                '${date.month.toString().padLeft(2, '0')}'
            : '${date.year}-'
                '${date.month.toString().padLeft(2, '0')}-'
                '${date.day.toString().padLeft(2, '0')}';

    grouped[key] = (grouped[key] ?? 0) + order.subtotal + order.deliveryFee;
  }

  final keys = grouped.keys.toList()..sort();

  final displayKeys = keys.length <= 24 ? keys : keys.sublist(keys.length - 24);

  return displayKeys.map((key) {
    final parts = key.split('-');

    if (useMonth) {
      return _ChartPoint(
        label: '${parts[1]}/${parts[0].substring(2)}',
        value: grouped[key] ?? 0,
      );
    }

    return _ChartPoint(
      label: '${parts[2]}/${parts[1]}',
      value: grouped[key] ?? 0,
    );
  }).toList();
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
