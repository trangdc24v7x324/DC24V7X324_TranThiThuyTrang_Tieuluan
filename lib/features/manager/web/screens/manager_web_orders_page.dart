import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_invoice_print.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/order_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

class ManagerWebOrdersPage extends StatefulWidget {
  const ManagerWebOrdersPage({super.key});

  @override
  State<ManagerWebOrdersPage> createState() => _ManagerWebOrdersPageState();
}

class _ManagerWebOrdersPageState extends State<ManagerWebOrdersPage> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'processing';
  String _paymentFilter = 'all';
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<OrderProvider>().loadAllOrders(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
    ]);
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();

    final result =
        orders.where((order) {
          final matchesQuery =
              query.isEmpty ||
              order.id.toLowerCase().contains(query) ||
              order.receiverName.toLowerCase().contains(query) ||
              order.receiverPhone.toLowerCase().contains(query) ||
              order.deliveryAddress.toLowerCase().contains(query);

          final matchesStatus = switch (_statusFilter) {
            'all' => true,
            'processing' => order.isActive,
            'completed' => order.isCompleted,
            'cancelled' => order.isCancelled,
            _ => order.orderStatus == _statusFilter,
          };

          final matchesPayment =
              _paymentFilter == 'all' || order.paymentStatus == _paymentFilter;

          return matchesQuery && matchesStatus && matchesPayment;
        }).toList();

    result.sort((a, b) {
      final aDate = a.created ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.created ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return result;
  }

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = 'processing';
      _paymentFilter = 'all';
      _currentPage = 1;
    });
  }

  Future<void> _openOrderDetail(OrderModel order) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return ManagerWebOrderDetailDialog(orderId: order.id);
      },
    );

    if (!mounted) {
      return;
    }

    await context.read<OrderProvider>().loadAllOrders();
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

    final filteredOrders = _filterOrders(orderProvider.orders);

    final totalPages =
        math.max(1, (filteredOrders.length / _rowsPerPage).ceil()).toInt();

    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;

    final endIndex =
        math.min(startIndex + _rowsPerPage, filteredOrders.length).toInt();

    final visibleOrders =
        filteredOrders.isEmpty
            ? <OrderModel>[]
            : filteredOrders.sublist(startIndex, endIndex);

    final paidRevenue = orderProvider.orders
        .where((order) => order.isCompleted && order.paymentStatus == 'paid')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return ManagerWebLayout(
      title: 'Quản lý đơn hàng',
      currentRoute: AppRoutes.managerOrders,
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
                      if (orderProvider.isLoading &&
                          orderProvider.orders.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: AppColors.primary,
                          ),
                        ),
                      _OrderSummaryGrid(
                        processing: orderProvider.pendingOrderCount,
                        completed: orderProvider.completedOrderCount,
                        cancelled: orderProvider.cancelledOrderCount,
                        paidRevenue: paidRevenue,
                      ),
                      const SizedBox(height: 18),
                      _OrderFilters(
                        searchController: _searchController,
                        statusFilter: _statusFilter,
                        paymentFilter: _paymentFilter,
                        onSearchChanged: (_) {
                          setState(() {
                            _currentPage = 1;
                          });
                        },
                        onStatusChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _statusFilter = value;
                            _currentPage = 1;
                          });
                        },
                        onPaymentChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _paymentFilter = value;
                            _currentPage = 1;
                          });
                        },
                        onReset: _resetFilters,
                      ),
                      const SizedBox(height: 14),
                      _OrdersPanel(
                        isLoading:
                            orderProvider.isLoading &&
                            orderProvider.orders.isEmpty,
                        errorMessage: orderProvider.errorMessage,
                        orders: visibleOrders,
                        totalFiltered: filteredOrders.length,
                        startIndex: startIndex,
                        onOpen: _openOrderDetail,
                        onRetry: _loadData,
                      ),
                      if (!orderProvider.isLoading &&
                          filteredOrders.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _PaginationBar(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          rowsPerPage: _rowsPerPage,
                          totalItems: filteredOrders.length,
                          startIndex: startIndex,
                          endIndex: endIndex,
                          onRowsPerPageChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _rowsPerPage = value;
                              _currentPage = 1;
                            });
                          },
                          onPrevious:
                              _currentPage > 1
                                  ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                  : null,
                          onNext:
                              _currentPage < totalPages
                                  ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                  : null,
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

class _OrderSummaryGrid extends StatelessWidget {
  final int processing;
  final int completed;
  final int cancelled;
  final double paidRevenue;

  const _OrderSummaryGrid({
    required this.processing,
    required this.completed,
    required this.cancelled,
    required this.paidRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _OrderSummaryCard(
        label: 'Đang xử lý',
        value: '$processing',
        caption: 'Đơn cần theo dõi',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _OrderSummaryCard(
        label: 'Hoàn thành',
        value: '$completed',
        caption: 'Đơn giao thành công',
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
      ),
      _OrderSummaryCard(
        label: 'Đã hủy',
        value: '$cancelled',
        caption: 'Đơn không tiếp tục',
        icon: Icons.cancel_outlined,
        color: Colors.red,
      ),
      _OrderSummaryCard(
        label: 'Doanh thu đã thu',
        value: _formatMoney(paidRevenue),
        caption: 'Đơn hoàn thành, đã thanh toán',
        icon: Icons.payments_rounded,
        color: const Color(0xFF4F46E5),
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

class _OrderSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _OrderSummaryCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
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
        ],
      ),
    );
  }
}

class _OrderFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final String paymentFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentChanged;
  final VoidCallback onReset;

  const _OrderFilters({
    required this.searchController,
    required this.statusFilter,
    required this.paymentFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPaymentChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1080;
          final medium = constraints.maxWidth >= 660;

          final searchWidth =
              wide
                  ? math.max(320.0, constraints.maxWidth - 660).toDouble()
                  : constraints.maxWidth;

          final secondaryWidth =
              wide
                  ? 190.0
                  : medium
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm mã đơn, tên, số điện thoại hoặc địa chỉ',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                              tooltip: 'Xóa từ khóa',
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                            : null,
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: secondaryWidth,
                child: DropdownButtonFormField<String>(
                  value: statusFilter,
                  isExpanded: true,
                  decoration: _filterDecoration(
                    'Trạng thái đơn',
                    Icons.local_shipping_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'processing',
                      child: Text('Đang xử lý'),
                    ),
                    DropdownMenuItem(value: 'all', child: Text('Tất cả đơn')),
                    DropdownMenuItem(
                      value: 'placed',
                      child: Text('Chờ xác nhận'),
                    ),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('Đã xác nhận'),
                    ),
                    DropdownMenuItem(
                      value: 'preparing',
                      child: Text('Đang chuẩn bị'),
                    ),
                    DropdownMenuItem(
                      value: 'delivering',
                      child: Text('Đang giao'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Hoàn thành'),
                    ),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: secondaryWidth,
                child: DropdownButtonFormField<String>(
                  value: paymentFilter,
                  isExpanded: true,
                  decoration: _filterDecoration(
                    'Thanh toán',
                    Icons.account_balance_wallet_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả thanh toán'),
                    ),
                    DropdownMenuItem(
                      value: 'unpaid',
                      child: Text('Chưa thanh toán'),
                    ),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Chờ xác nhận'),
                    ),
                    DropdownMenuItem(
                      value: 'paid',
                      child: Text('Đã thanh toán'),
                    ),
                    DropdownMenuItem(
                      value: 'failed',
                      child: Text('Thanh toán lỗi'),
                    ),
                  ],
                  onChanged: onPaymentChanged,
                ),
              ),
              SizedBox(
                width: wide ? 130 : secondaryWidth,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Đặt lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _filterDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _OrdersPanel extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<OrderModel> orders;
  final int totalFiltered;
  final int startIndex;
  final ValueChanged<OrderModel> onOpen;
  final VoidCallback onRetry;

  const _OrdersPanel({
    required this.isLoading,
    required this.errorMessage,
    required this.orders,
    required this.totalFiltered,
    required this.startIndex,
    required this.onOpen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh sách đơn hàng',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Bấm vào một đơn để xem và xử lý đầy đủ.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalFiltered đơn',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (isLoading)
            const SizedBox(
              height: 380,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (errorMessage != null && orders.isEmpty)
            SizedBox(
              height: 360,
              child: _OrderErrorState(message: errorMessage!, onRetry: onRetry),
            )
          else if (orders.isEmpty)
            const SizedBox(height: 360, child: _EmptyOrders())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 980) {
                  return _OrderCards(orders: orders, onOpen: onOpen);
                }

                return _OrderTable(
                  orders: orders,
                  startIndex: startIndex,
                  onOpen: onOpen,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OrderTable extends StatelessWidget {
  final List<OrderModel> orders;
  final int startIndex;
  final ValueChanged<OrderModel> onOpen;

  const _OrderTable({
    required this.orders,
    required this.startIndex,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1120),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AppColors.backgroundSecondary.withOpacity(0.78),
            ),
            headingTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            dataTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            dividerThickness: 0.8,
            horizontalMargin: 20,
            columnSpacing: 28,
            columns: const [
              DataColumn(label: Text('STT')),
              DataColumn(label: Text('ĐƠN HÀNG')),
              DataColumn(label: Text('KHÁCH HÀNG')),
              DataColumn(label: Text('TỔNG TIỀN')),
              DataColumn(label: Text('TRẠNG THÁI')),
              DataColumn(label: Text('THANH TOÁN')),
              DataColumn(label: Text('THAO TÁC')),
            ],
            rows: List.generate(orders.length, (index) {
              final order = orders[index];

              return DataRow(
                onSelectChanged: (_) {
                  onOpen(order);
                },
                cells: [
                  DataCell(Text('${startIndex + index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 175,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${_shortId(order.id)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(order.orderDate),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 230,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.receiverName.isEmpty
                                ? 'Khách hàng'
                                : order.receiverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.receiverPhone,
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
                  ),
                  DataCell(
                    Text(
                      _formatMoney(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  DataCell(
                    _StatusChip(
                      label: _statusLabel(order.orderStatus),
                      color: _statusColor(order.orderStatus),
                    ),
                  ),
                  DataCell(
                    _StatusChip(
                      label: _paymentLabel(order.paymentStatus),
                      color: _paymentColor(order.paymentStatus),
                    ),
                  ),
                  DataCell(
                    FilledButton.tonalIcon(
                      onPressed: () {
                        onOpen(order);
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('Xem đơn'),
                      style: FilledButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.primary.withOpacity(0.09),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _OrderCards extends StatelessWidget {
  final List<OrderModel> orders;
  final ValueChanged<OrderModel> onOpen;

  const _OrderCards({required this.orders, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 2 : 1;
          const spacing = 11.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children:
                orders.map((order) {
                  return SizedBox(
                    width: width,
                    child: Material(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        onTap: () => onOpen(order),
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '#${_shortId(order.id)}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  _StatusChip(
                                    label: _statusLabel(order.orderStatus),
                                    color: _statusColor(order.orderStatus),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                order.receiverName.isEmpty
                                    ? 'Khách hàng'
                                    : order.receiverName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.receiverPhone} • ${_formatDate(order.orderDate)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${order.items.length} sản phẩm',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(order.totalAmount),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _StatusChip(
                                    label: _paymentLabel(order.paymentStatus),
                                    color: _paymentColor(order.paymentStatus),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}

class ManagerWebOrderDetailDialog extends StatefulWidget {
  final String orderId;

  const ManagerWebOrderDetailDialog({super.key, required this.orderId});

  @override
  State<ManagerWebOrderDetailDialog> createState() =>
      _ManagerWebOrderDetailDialogState();
}

class _ManagerWebOrderDetailDialogState
    extends State<ManagerWebOrderDetailDialog> {
  bool _isBusy = false;
  String? _localError;
  String _selectedPaymentStatus = 'unpaid';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDetail);
  }

  Future<void> _loadDetail() async {
    await context.read<OrderProvider>().loadOrderDetail(widget.orderId);

    if (!mounted) {
      return;
    }

    final order = context.read<OrderProvider>().selectedOrder;

    if (order != null && order.id == widget.orderId) {
      setState(() {
        _selectedPaymentStatus = order.paymentStatus;
      });
    }
  }

  Future<void> _updateNextStatus(OrderModel order) async {
    final nextStatus = _nextStatus(order.orderStatus);

    if (nextStatus.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Chuyển sang "${_statusLabel(nextStatus)}"?',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Hệ thống sẽ cập nhật trạng thái đơn '
            '#${_shortId(order.id)} và gửi thông báo đến khách hàng.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Chưa cập nhật'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runBusy(() async {
      final provider = context.read<OrderProvider>();

      final success = await provider.updateOrderStatus(
        orderId: order.id,
        status: nextStatus,
        reloadAll: true,
      );

      if (!success) {
        throw Exception(
          provider.errorMessage ?? 'Không thể cập nhật trạng thái',
        );
      }

      await provider.loadOrderDetail(order.id);
    });
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final controller = TextEditingController();
    String? validationMessage;

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Hủy đơn hàng',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 500,
                child: TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Lý do hủy',
                    hintText: 'Ví dụ: Hết món, không liên hệ được khách...',
                    errorText: validationMessage,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Quay lại'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) {
                      setDialogState(() {
                        validationMessage = 'Bắt buộc nhập lý do hủy';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Xác nhận hủy'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    await _runBusy(() async {
      final provider = context.read<OrderProvider>();

      final success = await provider.updateOrderStatus(
        orderId: order.id,
        status: 'cancelled',
        cancelReason: reason,
        reloadAll: true,
      );

      if (!success) {
        throw Exception(provider.errorMessage ?? 'Không thể hủy đơn');
      }

      await provider.loadOrderDetail(order.id);
    });
  }

  Future<void> _updatePaymentStatus(OrderModel order) async {
    if (_selectedPaymentStatus == order.paymentStatus) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cập nhật thanh toán',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Chuyển trạng thái thanh toán từ '
            '"${_paymentLabel(order.paymentStatus)}" sang '
            '"${_paymentLabel(_selectedPaymentStatus)}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      setState(() {
        _selectedPaymentStatus = order.paymentStatus;
      });
      return;
    }

    await _runBusy(() async {
      final provider = context.read<OrderProvider>();

      final success = await provider.updatePaymentStatus(
        orderId: order.id,
        paymentStatus: _selectedPaymentStatus,
        reloadAll: true,
      );

      if (!success) {
        throw Exception(
          provider.errorMessage ?? 'Không thể cập nhật thanh toán',
        );
      }

      await provider.loadOrderDetail(order.id);
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _localError = null;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _localError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240, maxHeight: 900),
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final selected = provider.selectedOrder;

            final order =
                selected != null && selected.id == widget.orderId
                    ? selected
                    : provider.findOrderById(widget.orderId);

            final isInitialLoading = provider.isLoading && order == null;

            return Column(
              children: [
                _DetailHeader(
                  order: order,
                  isBusy: _isBusy,
                  onClose: () {
                    Navigator.pop(context);
                  },
                  onCopyId:
                      order == null
                          ? null
                          : () {
                            Clipboard.setData(ClipboardData(text: order.id));

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép mã đơn'),
                              ),
                            );
                          },
                  onPrint:
                      order == null
                          ? null
                          : () {
                            printManagerInvoice(order: order);
                          },
                ),
                const Divider(height: 1, color: AppColors.border),
                if (_isBusy)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                  ),
                Expanded(
                  child:
                      isInitialLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                          : order == null
                          ? _DetailError(
                            message:
                                provider.errorMessage ??
                                'Không tìm thấy đơn hàng',
                            onRetry: _loadDetail,
                          )
                          : _buildOrderBody(order),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderBody(OrderModel order) {
    final next = _nextStatus(order.orderStatus);

    final canCancel =
        order.orderStatus == 'placed' || order.orderStatus == 'confirmed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;

          final leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusTimeline(order: order),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Thông tin giao hàng',
                icon: Icons.local_shipping_outlined,
                child: Column(
                  children: [
                    _InfoLine(label: 'Người nhận', value: order.receiverName),
                    _InfoLine(
                      label: 'Số điện thoại',
                      value: order.receiverPhone,
                    ),
                    _InfoLine(label: 'Địa chỉ', value: order.deliveryAddress),
                    _InfoLine(
                      label: 'Ngày đặt',
                      value: _formatDate(order.orderDate),
                    ),
                    if (order.note.trim().isNotEmpty)
                      _InfoLine(
                        label: 'Ghi chú đơn',
                        value: order.note,
                        emphasize: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Sản phẩm đã đặt (${order.items.length})',
                icon: Icons.fastfood_rounded,
                child:
                    order.items.isEmpty
                        ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: Center(
                            child: Text(
                              'Đơn chưa có dữ liệu sản phẩm.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                        : Column(
                          children:
                              order.items
                                  .map((item) => _OrderItemTile(item: item))
                                  .toList(),
                        ),
              ),
              if (order.cancelReason.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Lý do hủy đơn',
                  icon: Icons.report_gmailerrorred_rounded,
                  accentColor: Colors.red,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      order.cancelReason,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );

          final rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Thanh toán',
                icon: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    _MoneyLine(label: 'Tạm tính', value: order.subtotal),
                    _MoneyLine(label: 'Giảm giá', value: -order.discountAmount),
                    _MoneyLine(
                      label: 'Phí giao hàng',
                      value: order.deliveryFee,
                    ),
                    const Divider(height: 22, color: AppColors.border),
                    _MoneyLine(
                      label: 'Tổng cộng',
                      value: order.totalAmount,
                      isTotal: true,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái thanh toán',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('Chưa thanh toán'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Chờ xác nhận'),
                        ),
                        DropdownMenuItem(
                          value: 'paid',
                          child: Text('Đã thanh toán'),
                        ),
                        DropdownMenuItem(
                          value: 'failed',
                          child: Text('Thanh toán lỗi'),
                        ),
                      ],
                      onChanged:
                          _isBusy
                              ? null
                              : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedPaymentStatus = value;
                                });
                              },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isBusy ||
                                    _selectedPaymentStatus ==
                                        order.paymentStatus
                                ? null
                                : () {
                                  _updatePaymentStatus(order);
                                },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Lưu trạng thái thanh toán'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          printManagerInvoice(order: order);
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('In hóa đơn giả lập'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Xử lý đơn hàng',
                icon: Icons.admin_panel_settings_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(
                      label: 'Trạng thái hiện tại',
                      value: _statusLabel(order.orderStatus),
                    ),
                    _InfoLine(
                      label: 'Phương thức thanh toán',
                      value: order.paymentMethod,
                    ),
                    const SizedBox(height: 8),
                    if (_localError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _localError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (next.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _isBusy
                                  ? null
                                  : () {
                                    _updateNextStatus(order);
                                  },
                          style: FilledButton.styleFrom(
                            backgroundColor: _statusColor(next),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: Icon(_nextStatusIcon(next)),
                          label: Text('Chuyển sang ${_statusLabel(next)}'),
                        ),
                      ),
                    if (canCancel) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isBusy
                                  ? null
                                  : () {
                                    _cancelOrder(order);
                                  },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Hủy đơn hàng'),
                        ),
                      ),
                    ],
                    if (next.isEmpty && !canCancel)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            order.orderStatus,
                          ).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          order.isCompleted
                              ? 'Đơn hàng đã hoàn thành. Không còn bước xử lý tiếp theo.'
                              : 'Đơn hàng đã bị hủy. Không thể tiếp tục xử lý.',
                          style: TextStyle(
                            color: _statusColor(order.orderStatus),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );

          if (!wide) {
            return Column(
              children: [leftColumn, const SizedBox(height: 16), rightColumn],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: leftColumn),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: rightColumn),
            ],
          );
        },
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final OrderModel? order;
  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback? onCopyId;
  final VoidCallback? onPrint;

  const _DetailHeader({
    required this.order,
    required this.isBusy,
    required this.onClose,
    required this.onCopyId,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 12, 17),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order == null
                      ? 'Chi tiết đơn hàng'
                      : 'Đơn #${_shortId(order!.id)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order == null
                      ? 'Đang tải dữ liệu đơn hàng'
                      : '${order!.receiverName} • ${_formatDate(order!.orderDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onCopyId != null)
            IconButton(
              tooltip: 'Sao chép mã đơn',
              onPressed: isBusy ? null : onCopyId,
              icon: const Icon(Icons.copy_rounded),
            ),
          if (onPrint != null)
            IconButton(
              tooltip: 'In hóa đơn giả lập',
              onPressed: isBusy ? null : onPrint,
              icon: const Icon(Icons.print_rounded),
            ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: isBusy ? null : onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final OrderModel order;

  const _StatusTimeline({required this.order});

  static const statuses = [
    'placed',
    'confirmed',
    'preparing',
    'delivering',
    'completed',
  ];

  @override
  Widget build(BuildContext context) {
    if (order.isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đơn hàng đã bị hủy và không còn nằm trong luồng xử lý.',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = statuses.indexOf(order.orderStatus);

    return _SectionCard(
      title: 'Tiến trình đơn hàng',
      icon: Icons.timeline_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              children: List.generate(statuses.length, (index) {
                final status = statuses[index];
                final reached = index <= currentIndex;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        _TimelineDot(
                          reached: reached,
                          current: index == currentIndex,
                          color: _statusColor(status),
                        ),
                        if (index != statuses.length - 1)
                          Container(
                            width: 2,
                            height: 38,
                            color:
                                reached
                                    ? _statusColor(status).withOpacity(0.45)
                                    : AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color:
                                    reached
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                fontWeight:
                                    reached ? FontWeight.w900 : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusDescription(status),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            );
          }

          return Row(
            children: List.generate(statuses.length * 2 - 1, (slot) {
              if (slot.isOdd) {
                final leftIndex = (slot - 1) ~/ 2;

                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 33),
                    decoration: BoxDecoration(
                      color:
                          leftIndex < currentIndex
                              ? _statusColor(statuses[leftIndex + 1])
                              : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }

              final index = slot ~/ 2;
              final status = statuses[index];
              final reached = index <= currentIndex;

              return SizedBox(
                width: 118,
                child: Column(
                  children: [
                    _TimelineDot(
                      reached: reached,
                      current: index == currentIndex,
                      color: _statusColor(status),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusLabel(status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            reached
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: reached ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final bool reached;
  final bool current;
  final Color color;

  const _TimelineDot({
    required this.reached,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: current ? 36 : 30,
      height: current ? 36 : 30,
      decoration: BoxDecoration(
        color: reached ? color : AppColors.backgroundSecondary,
        shape: BoxShape.circle,
        border: Border.all(
          color: reached ? color : AppColors.border,
          width: current ? 4 : 2,
        ),
        boxShadow:
            current
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.22),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: Icon(
        reached ? Icons.check_rounded : Icons.circle_outlined,
        color: reached ? Colors.white : AppColors.textSecondary,
        size: current ? 20 : 16,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return Container(
      width: double.infinity,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _InfoLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? 'Không có' : value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? 'Không có' : value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _MoneyLine({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final negative = value < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isTotal ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            negative ? '-${_formatMoney(value.abs())}' : _formatMoney(value),
            style: TextStyle(
              color:
                  isTotal
                      ? AppColors.primary
                      : negative
                      ? AppColors.success
                      : AppColors.textPrimary,
              fontSize: isTotal ? 20 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(url: item.productImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatMoney(item.unitPrice)} × ${item.quantity}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (item.categoryTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.categoryTitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Ghi chú: ${item.note}',
                      style: const TextStyle(
                        color: Color(0xFF9A3412),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatMoney(item.subtotal),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _placeholder();
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.fastfood_rounded, color: AppColors.textSecondary),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrderErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 54),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textGrey,
            size: 58,
          ),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy đơn hàng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hãy thay đổi từ khóa hoặc bộ lọc đang sử dụng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 52),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final ValueChanged<int?> onRowsPerPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.onRowsPerPageChanged,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          Text(
            'Hiển thị ${startIndex + 1}–$endIndex trong $totalItems đơn',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Số dòng:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: rowsPerPage,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: onRowsPerPageChanged,
              ),
              const SizedBox(width: 14),
              Text(
                'Trang $currentPage/$totalPages',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Trang trước',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _nextStatus(String status) {
  switch (status) {
    case 'placed':
      return 'confirmed';
    case 'confirmed':
      return 'preparing';
    case 'preparing':
      return 'delivering';
    case 'delivering':
      return 'completed';
    default:
      return '';
  }
}

IconData _nextStatusIcon(String status) {
  switch (status) {
    case 'confirmed':
      return Icons.verified_rounded;
    case 'preparing':
      return Icons.soup_kitchen_rounded;
    case 'delivering':
      return Icons.local_shipping_rounded;
    case 'completed':
      return Icons.task_alt_rounded;
    default:
      return Icons.arrow_forward_rounded;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'placed':
      return 'Chờ xác nhận';
    case 'confirmed':
      return 'Đã xác nhận';
    case 'preparing':
      return 'Đang chuẩn bị';
    case 'delivering':
      return 'Đang giao';
    case 'completed':
      return 'Hoàn thành';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return status;
  }
}

String _statusDescription(String status) {
  switch (status) {
    case 'placed':
      return 'Khách vừa tạo đơn';
    case 'confirmed':
      return 'Cửa hàng đã nhận đơn';
    case 'preparing':
      return 'Món đang được chế biến';
    case 'delivering':
      return 'Đơn đang trên đường giao';
    case 'completed':
      return 'Khách đã nhận hàng';
    default:
      return '';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'placed':
      return const Color(0xFFF59E0B);
    case 'confirmed':
      return const Color(0xFF2563EB);
    case 'preparing':
      return const Color(0xFF7C3AED);
    case 'delivering':
      return const Color(0xFF0891B2);
    case 'completed':
      return AppColors.success;
    case 'cancelled':
      return Colors.red;
    default:
      return AppColors.textSecondary;
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
    case 'unpaid':
      return 'Chưa thanh toán';
    default:
      return status;
  }
}

Color _paymentColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'failed':
      return Colors.red;
    default:
      return AppColors.textSecondary;
  }
}

String _shortId(String id) {
  final value = id.trim().toUpperCase();

  if (value.length <= 10) {
    return value;
  }

  return value.substring(0, 10);
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
