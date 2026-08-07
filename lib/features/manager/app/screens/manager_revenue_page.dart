import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  String selectedFilter = 'month';
  final Set<String> expandedCategories = {};

  late DateTime startDate;
  late DateTime endDate;

  static const Color primaryRed = Color(0xFFEF2A39);
  static const Color orangeRed = Color(0xFFFF7A45);

  static const Color pastelOrange = Color(0xFFFFF3E8);
  static const Color pastelGreen = Color(0xFFEAF8EF);
  static const Color pastelBlue = Color(0xFFEAF2FF);
  static const Color pastelPurple = Color(0xFFF3EDFF);
  static const Color pastelGrey = Color(0xFFF7F7F9);

  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _setMonthRange();

    Future.microtask(() {
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  void _setTodayRange() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void _setWeekRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    startDate = DateTime(monday.year, monday.month, monday.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void _setMonthRange() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  void _selectFilter(String value) {
    setState(() {
      selectedFilter = value;
      expandedCategories.clear();

      if (value == 'today') {
        _setTodayRange();
      } else if (value == 'week') {
        _setWeekRange();
      } else {
        _setMonthRange();
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
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

    if (picked == null) return;

    setState(() {
      selectedFilter = 'custom';
      expandedCategories.clear();

      startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );

      endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
    });
  }

  Future<void> _refresh() async {
    await context.read<OrderProvider>().loadAllOrders();
  }

  bool _isInRange(DateTime date) {
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  List<OrderModel> _completedOrders(List<OrderModel> orders) {
    return orders.where((order) {
      return order.status == 'completed' && _isInRange(order.orderDate);
    }).toList();
  }

  double _totalRevenue(List<OrderModel> orders) {
    return orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
  }

  int _totalQuantity(List<_CategorySaleGroup> groups) {
    return groups.fold<int>(0, (sum, group) => sum + group.totalQuantity);
  }

  List<_CategorySaleGroup> _buildCategoryGroups(List<OrderModel> orders) {
    final categoryMap = <String, Map<String, _ProductSaleItem>>{};

    for (final order in orders) {
      for (final item in order.items) {
        final categoryName =
            item.categoryTitle.isNotEmpty ? item.categoryTitle : 'Khác';

        final productName =
            item.productName.isNotEmpty ? item.productName : 'Sản phẩm';

        categoryMap.putIfAbsent(categoryName, () => {});

        final products = categoryMap[categoryName]!;

        if (products.containsKey(productName)) {
          final old = products[productName]!;
          products[productName] = old.copyWith(
            quantity: old.quantity + item.quantity,
          );
        } else {
          products[productName] = _ProductSaleItem(
            name: productName,
            quantity: item.quantity,
          );
        }
      }
    }

    final groups =
        categoryMap.entries.map((entry) {
          final products =
              entry.value.values.toList()
                ..sort((a, b) => b.quantity.compareTo(a.quantity));

          return _CategorySaleGroup(
            categoryName: entry.key,
            products: products,
          );
        }).toList();

    groups.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    return groups;
  }

  String _formatPrice(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('nước') ||
        value.contains('drink') ||
        value.contains('beverage')) {
      return Icons.local_drink_rounded;
    }

    if (value.contains('combo')) {
      return Icons.dashboard_customize_rounded;
    }

    if (value.contains('food') ||
        value.contains('món') ||
        value.contains('ăn')) {
      return Icons.restaurant_rounded;
    }

    return Icons.fastfood_rounded;
  }

  Color _categoryPastelColor(int index) {
    final colors = [
      pastelOrange,
      pastelGreen,
      pastelBlue,
      pastelPurple,
      pastelGrey,
    ];

    return colors[index % colors.length];
  }

  Color _categoryIconColor(int index) {
    final colors = [
      const Color(0xFFF97316),
      const Color(0xFF16A34A),
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF64748B),
    ];

    return colors[index % colors.length];
  }

  void _toggleCategory(String categoryName) {
    setState(() {
      if (expandedCategories.contains(categoryName)) {
        expandedCategories.remove(categoryName);
      } else {
        expandedCategories.add(categoryName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    final completedOrders = _completedOrders(provider.orders);
    final totalRevenue = _totalRevenue(completedOrders);
    final categoryGroups = _buildCategoryGroups(completedOrders);
    final totalQuantity = _totalQuantity(categoryGroups);

    return AppLayout(
      title: 'Doanh thu',
      showBack: true,
      child: AppBody(
        child:
            provider.isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: primaryRed),
                )
                : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _FilterSection(
                        selectedFilter: selectedFilter,
                        rangeText:
                            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                        onToday: () => _selectFilter('today'),
                        onWeek: () => _selectFilter('week'),
                        onMonth: () => _selectFilter('month'),
                        onCustom: _pickCustomRange,
                      ),
                      const SizedBox(height: 14),
                      _RevenueCard(
                        totalRevenue: _formatPrice(totalRevenue),
                        orderCount: completedOrders.length,
                        rangeText:
                            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                      ),
                      const SizedBox(height: 24),
                      _StatisticHeader(
                        totalQuantity: totalQuantity,
                        categoryCount: categoryGroups.length,
                      ),
                      const SizedBox(height: 14),
                      if (categoryGroups.isEmpty)
                        const _EmptyState()
                      else
                        ...List.generate(categoryGroups.length, (index) {
                          final group = categoryGroups[index];

                          final isExpanded = expandedCategories.contains(
                            group.categoryName,
                          );

                          return _CategorySaleCard(
                            group: group,
                            isExpanded: isExpanded,
                            icon: _categoryIcon(group.categoryName),
                            pastelColor: _categoryPastelColor(index),
                            iconColor: _categoryIconColor(index),
                            onTap: () => _toggleCategory(group.categoryName),
                          );
                        }),
                    ],
                  ),
                ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String selectedFilter;
  final String rangeText;
  final VoidCallback onToday;
  final VoidCallback onWeek;
  final VoidCallback onMonth;
  final VoidCallback onCustom;

  const _FilterSection({
    required this.selectedFilter,
    required this.rangeText,
    required this.onToday,
    required this.onWeek,
    required this.onMonth,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khoảng thời gian',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ManagerRevenuePageState.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rangeText,
            style: const TextStyle(
              color: _ManagerRevenuePageState.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterButton(
                label: 'Hôm nay',
                selected: selectedFilter == 'today',
                onTap: onToday,
              ),
              _FilterButton(
                label: 'Tuần này',
                selected: selectedFilter == 'week',
                onTap: onWeek,
              ),
              _FilterButton(
                label: 'Tháng này',
                selected: selectedFilter == 'month',
                onTap: onMonth,
              ),
              _FilterButton(
                label: 'Tùy chọn',
                selected: selectedFilter == 'custom',
                onTap: onCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _ManagerRevenuePageState.primaryRed,
      backgroundColor: const Color(0xFFF7F7F9),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF374151),
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(
          color:
              selected
                  ? _ManagerRevenuePageState.primaryRed
                  : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String totalRevenue;
  final int orderCount;
  final String rangeText;

  const _RevenueCard({
    required this.totalRevenue,
    required this.orderCount,
    required this.rangeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _ManagerRevenuePageState.primaryRed,
            _ManagerRevenuePageState.orangeRed,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _ManagerRevenuePageState.primaryRed.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng doanh thu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalRevenue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$orderCount đơn hoàn thành • $rangeText',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
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

class _StatisticHeader extends StatelessWidget {
  final int totalQuantity;
  final int categoryCount;

  const _StatisticHeader({
    required this.totalQuantity,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteBox(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _ManagerRevenuePageState.pastelBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF2563EB),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê món được đặt',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _ManagerRevenuePageState.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bấm vào từng danh mục để xem sản phẩm bên trong',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalQuantity lượt bán • $categoryCount danh mục',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _ManagerRevenuePageState.primaryRed,
                    fontWeight: FontWeight.w800,
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

class _CategorySaleCard extends StatelessWidget {
  final _CategorySaleGroup group;
  final bool isExpanded;
  final IconData icon;
  final Color pastelColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategorySaleCard({
    required this.group,
    required this.isExpanded,
    required this.icon,
    required this.pastelColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteBox(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: pastelColor,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ManagerRevenuePageState.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.totalQuantity} lượt bán',
                          style: const TextStyle(
                            fontSize: 14,
                            color: _ManagerRevenuePageState.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 26,
                        color: _ManagerRevenuePageState.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ProductList(
              products: group.products,
              iconColor: iconColor,
              pastelColor: pastelColor,
            ),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<_ProductSaleItem> products;
  final Color iconColor;
  final Color pastelColor;

  const _ProductList({
    required this.products,
    required this.iconColor,
    required this.pastelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children:
            products.map((item) {
              return Container(
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: pastelColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _ManagerRevenuePageState.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _ManagerRevenuePageState.pastelGreen,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${item.quantity} lượt',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _WhiteBox(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _ManagerRevenuePageState.pastelBlue,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Chưa có món nào được đặt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _ManagerRevenuePageState.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Khi có đơn hàng hoàn thành, thống kê món bán sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _ManagerRevenuePageState.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const _WhiteBox({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEDF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CategorySaleGroup {
  final String categoryName;
  final List<_ProductSaleItem> products;

  const _CategorySaleGroup({
    required this.categoryName,
    required this.products,
  });

  int get totalQuantity {
    return products.fold<int>(0, (sum, item) => sum + item.quantity);
  }
}

class _ProductSaleItem {
  final String name;
  final int quantity;

  const _ProductSaleItem({required this.name, required this.quantity});

  _ProductSaleItem copyWith({String? name, int? quantity}) {
    return _ProductSaleItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}
