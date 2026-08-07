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
  String _range = '30d';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<OrderProvider>().loadAllOrders(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
    ]);
  }

  List<OrderModel> _completedInRange(List<OrderModel> source) {
    final now = DateTime.now();

    final DateTime? start = switch (_range) {
      'today' => DateTime(now.year, now.month, now.day),
      '7d' => now.subtract(const Duration(days: 7)),
      '30d' => now.subtract(const Duration(days: 30)),
      '90d' => now.subtract(const Duration(days: 90)),
      _ => null,
    };

    final result =
        source.where((order) {
          if (!order.isCompleted) {
            return false;
          }

          if (start == null) {
            return true;
          }

          return order.orderDate.isAfter(start) ||
              order.orderDate.isAtSameMomentAs(start);
        }).toList();

    result.sort((a, b) => a.orderDate.compareTo(b.orderDate));

    return result;
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

    final completed = _completedInRange(orderProvider.orders);

    final totalRevenue = completed.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    final paidRevenue = completed
        .where((order) => order.paymentStatus == 'paid')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    final averageOrder =
        completed.isEmpty ? 0.0 : totalRevenue / completed.length;

    final totalItems = completed.fold<int>(
      0,
      (sum, order) =>
          sum +
          order.items.fold<int>(0, (itemSum, item) => itemSum + item.quantity),
    );

    final chartPoints = _buildChartPoints(completed, _range);

    final topProducts = _buildProductStats(completed);

    final categories = _buildCategoryStats(completed);

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
                20,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RevenueHeader(
                        selectedRange: _range,
                        onRangeChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _range = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (orderProvider.isLoading &&
                          orderProvider.orders.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: AppColors.primary,
                          ),
                        ),
                      _RevenueKpiGrid(
                        totalRevenue: totalRevenue,
                        paidRevenue: paidRevenue,
                        orderCount: completed.length,
                        averageOrder: averageOrder,
                        totalItems: totalItems,
                      ),
                      const SizedBox(height: 16),
                      if (orderProvider.isLoading &&
                          orderProvider.orders.isEmpty)
                        const SizedBox(
                          height: 420,
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
                        _RevenueChartCard(
                          title: _chartTitle(_range),
                          points: chartPoints,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, inner) {
                            final wide = inner.maxWidth >= 920;

                            final productCard = _TopProductsCard(
                              items: topProducts,
                            );

                            final categoryCard = _CategoryBreakdownCard(
                              items: categories,
                            );

                            if (!wide) {
                              return Column(
                                children: [
                                  productCard,
                                  const SizedBox(height: 16),
                                  categoryCard,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: productCard),
                                const SizedBox(width: 16),
                                Expanded(flex: 5, child: categoryCard),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RecentCompletedOrders(
                          orders: completed.reversed.take(8).toList(),
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

class _RevenueHeader extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String?> onRangeChanged;

  const _RevenueHeader({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Báo cáo hiệu quả kinh doanh',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Số liệu được tổng hợp từ các đơn hàng đã hoàn thành.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          );

          final selector = SizedBox(
            width: compact ? constraints.maxWidth : 220,
            child: DropdownButtonFormField<String>(
              value: selectedRange,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Khoảng thời gian',
                prefixIcon: const Icon(Icons.date_range_rounded),
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Hôm nay')),
                DropdownMenuItem(value: '7d', child: Text('7 ngày gần nhất')),
                DropdownMenuItem(value: '30d', child: Text('30 ngày gần nhất')),
                DropdownMenuItem(value: '90d', child: Text('90 ngày gần nhất')),
                DropdownMenuItem(value: 'all', child: Text('Toàn bộ dữ liệu')),
              ],
              onChanged: onRangeChanged,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), selector],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 18),
              selector,
            ],
          );
        },
      ),
    );
  }
}

class _RevenueKpiGrid extends StatelessWidget {
  final double totalRevenue;
  final double paidRevenue;
  final int orderCount;
  final double averageOrder;
  final int totalItems;

  const _RevenueKpiGrid({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.orderCount,
    required this.averageOrder,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _RevenueKpiCard(
        label: 'Doanh thu hoàn thành',
        value: _formatMoney(totalRevenue),
        note: '$orderCount đơn hoàn thành',
        icon: Icons.trending_up_rounded,
        color: AppColors.primary,
      ),
      _RevenueKpiCard(
        label: 'Doanh thu đã thanh toán',
        value: _formatMoney(paidRevenue),
        note: 'Dòng tiền đã xác nhận',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
      ),
      _RevenueKpiCard(
        label: 'Giá trị đơn trung bình',
        value: _formatMoney(averageOrder),
        note: 'Trung bình mỗi đơn',
        icon: Icons.analytics_outlined,
        color: const Color(0xFF4F46E5),
      ),
      _RevenueKpiCard(
        label: 'Sản phẩm đã bán',
        value: '$totalItems',
        note: 'Tổng số lượng món',
        icon: Icons.fastfood_rounded,
        color: const Color(0xFFF59E0B),
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

class _RevenueKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;

  const _RevenueKpiCard({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(17),
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
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                color: color.withOpacity(0.6),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${points.length} mốc',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (points.isEmpty)
            const SizedBox(
              height: 260,
              child: Center(
                child: Text(
                  'Chưa có doanh thu trong khoảng thời gian này.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 290,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children:
                      points.map((point) {
                        final ratio =
                            maxValue <= 0 ? 0.0 : point.value / maxValue;

                        final barHeight = math.max(8.0, ratio * 205).toDouble();

                        return SizedBox(
                          width: 78,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Tooltip(
                                  message:
                                      '${point.label}: ${_formatMoney(point.value)}',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 34,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.78,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(9),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  point.label,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
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
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<_ProductStat> items;

  const _TopProductsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxQuantity =
        items.isEmpty
            ? 0
            : items
                .map((item) => item.quantity)
                .reduce((a, b) => a > b ? a : b);

    return _AnalyticsCard(
      title: 'Sản phẩm bán chạy',
      subtitle: 'Xếp hạng theo số lượng trong đơn hoàn thành',
      icon: Icons.emoji_events_rounded,
      child:
          items.isEmpty
              ? const _AnalyticsEmpty(message: 'Chưa có dữ liệu sản phẩm.')
              : Column(
                children: List.generate(math.min(items.length, 8).toInt(), (
                  index,
                ) {
                  final item = items[index];
                  final ratio =
                      maxQuantity == 0 ? 0.0 : item.quantity / maxQuantity;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                index < 3
                                    ? const Color(0xFFFFF7ED)
                                    : AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color:
                                  index < 3
                                      ? const Color(0xFFC2410C)
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.quantity} món',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 7,
                                  backgroundColor:
                                      AppColors.backgroundSecondary,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatMoney(item.revenue),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  final List<_CategoryStat> items;

  const _CategoryBreakdownCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.revenue);

    return _AnalyticsCard(
      title: 'Cơ cấu theo danh mục',
      subtitle: 'Tỷ trọng doanh thu của từng nhóm món',
      icon: Icons.donut_large_rounded,
      child:
          items.isEmpty
              ? const _AnalyticsEmpty(message: 'Chưa có dữ liệu danh mục.')
              : Column(
                children:
                    items.take(8).map((item) {
                      final ratio = total <= 0 ? 0.0 : item.revenue / total;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(ratio * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8,
                                backgroundColor: AppColors.backgroundSecondary,
                                color: AppColors.primary.withOpacity(0.78),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${item.quantity} món',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                                const Spacer(),
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
                      );
                    }).toList(),
              ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _RecentCompletedOrders extends StatelessWidget {
  final List<OrderModel> orders;

  const _RecentCompletedOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'Đơn hoàn thành gần đây',
      subtitle: 'Các giao dịch mới nhất trong khoảng đã chọn',
      icon: Icons.history_rounded,
      child:
          orders.isEmpty
              ? const _AnalyticsEmpty(message: 'Chưa có đơn hoàn thành.')
              : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children:
                          orders.map((order) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${_shortId(order.id)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${order.receiverName} • ${_formatDate(order.orderDate)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatMoney(order.totalAmount),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        AppColors.backgroundSecondary,
                      ),
                      columns: const [
                        DataColumn(label: Text('MÃ ĐƠN')),
                        DataColumn(label: Text('KHÁCH HÀNG')),
                        DataColumn(label: Text('NGÀY HOÀN THÀNH')),
                        DataColumn(label: Text('THANH TOÁN')),
                        DataColumn(label: Text('GIÁ TRỊ')),
                      ],
                      rows:
                          orders.map((order) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '#${_shortId(order.id)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                DataCell(Text(order.receiverName)),
                                DataCell(Text(_formatDate(order.orderDate))),
                                DataCell(
                                  Text(_paymentLabel(order.paymentStatus)),
                                ),
                                DataCell(
                                  Text(
                                    _formatMoney(order.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  );
                },
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
      height: 170,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
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
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 52),
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

class _ChartPoint {
  final String label;
  final double value;

  const _ChartPoint({required this.label, required this.value});
}

class _ProductStat {
  final String name;
  int quantity;
  double revenue;

  _ProductStat({required this.name, this.quantity = 0, this.revenue = 0});
}

class _CategoryStat {
  final String name;
  int quantity;
  double revenue;

  _CategoryStat({required this.name, this.quantity = 0, this.revenue = 0});
}

List<_ChartPoint> _buildChartPoints(List<OrderModel> orders, String range) {
  if (orders.isEmpty) {
    return const [];
  }

  final useMonth = range == 'all' || range == '90d';

  final grouped = <String, double>{};

  for (final order in orders) {
    final date = order.orderDate;

    final key =
        useMonth
            ? '${date.year}-${date.month.toString().padLeft(2, '0')}'
            : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    grouped[key] = (grouped[key] ?? 0) + order.totalAmount;
  }

  final keys = grouped.keys.toList()..sort();

  final limited = useMonth ? keys.takeLast(12) : keys.takeLast(18);

  return limited.map((key) {
    if (useMonth) {
      final parts = key.split('-');
      return _ChartPoint(
        label: '${parts[1]}/${parts[0].substring(2)}',
        value: grouped[key] ?? 0,
      );
    }

    final parts = key.split('-');

    return _ChartPoint(
      label: '${parts[2]}/${parts[1]}',
      value: grouped[key] ?? 0,
    );
  }).toList();
}

List<_ProductStat> _buildProductStats(List<OrderModel> orders) {
  final map = <String, _ProductStat>{};

  for (final order in orders) {
    for (final item in order.items) {
      final name =
          item.productName.trim().isEmpty
              ? 'Sản phẩm'
              : item.productName.trim();

      final stat = map.putIfAbsent(name, () => _ProductStat(name: name));

      stat.quantity += item.quantity;
      stat.revenue += item.subtotal;
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

List<_CategoryStat> _buildCategoryStats(List<OrderModel> orders) {
  final map = <String, _CategoryStat>{};

  for (final order in orders) {
    for (final item in order.items) {
      final name =
          item.categoryTitle.trim().isEmpty
              ? 'Khác'
              : item.categoryTitle.trim();

      final stat = map.putIfAbsent(name, () => _CategoryStat(name: name));

      stat.quantity += item.quantity;
      stat.revenue += item.subtotal;
    }
  }

  final result = map.values.toList();

  result.sort((a, b) => b.revenue.compareTo(a.revenue));

  return result;
}

String _chartTitle(String range) {
  switch (range) {
    case 'today':
      return 'Doanh thu hôm nay';
    case '7d':
      return 'Biểu đồ doanh thu 7 ngày';
    case '30d':
      return 'Biểu đồ doanh thu 30 ngày';
    case '90d':
      return 'Biểu đồ doanh thu 90 ngày';
    default:
      return 'Biểu đồ doanh thu toàn thời gian';
  }
}

String _paymentLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Đã thanh toán';
    case 'pending':
      return 'Chờ xác nhận';
    case 'failed':
      return 'Thanh toán lỗi';
    default:
      return 'Chưa thanh toán';
  }
}

String _shortId(String id) {
  final value = id.trim().toUpperCase();

  return value.length <= 10 ? value : value.substring(0, 10);
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');

  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

String _formatMoney(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);

    final remaining = digits.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
  }

  return '${buffer}đ';
}

extension _TakeLastExtension<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) {
      return this;
    }

    return skip(length - count);
  }
}
