// FILE HỌC TẬP: lib/features/manager/app/screens/manager_orders_page.dart
// Vai trò: Màn hình Manager App quản lý đơn hàng.
// Luồng sử dụng: Hiển thị nghiệp vụ quản lý trên ứng dụng và gọi Provider/Service tương ứng.

import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/models/payment_record_model.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/services/payment_service.dart';
import 'package:project_trangdc24v7x324/services/map_navigation_service.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:project_trangdc24v7x324/utils/order_status_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Mở chỉ đường giao hàng: dùng tọa độ đã lưu của đơn và vị trí hiện tại của thiết bị.
// Mở chỉ đường (_openDeliveryDirections): lấy tọa độ đơn hàng và gọi MapNavigationService mở Google Maps.
Future<void> _openDeliveryDirections(
  BuildContext context,
  OrderModel order,
) async {
  if (!order.hasDeliveryCoordinates) return;

  try {
    await MapNavigationService.openDirections(
      latitude: order.deliveryLatitude,
      longitude: order.deliveryLongitude,
    );
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }
}

// Lớp ManagerOrdersPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerOrdersPage extends StatefulWidget {
  // Khởi tạo ManagerOrdersPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const ManagerOrdersPage({super.key});

  // Tạo state (createState): liên kết ManagerOrdersPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<ManagerOrdersPage> createState() => _ManagerOrdersPageState();
}

// Lớp _ManagerOrdersPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _ManagerOrdersPageState extends State<ManagerOrdersPage> {
  final PaymentService _paymentService = PaymentService();

  final Map<String, PaymentRecordModel?> _paymentsByOrderId = {};
  final Set<String> _expandedOrderIds = {};

  String selectedFilter = 'processing';
  String? _updatingOrderId;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPage);
  }

  // Tải trang (_loadPage): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> _loadPage() async {
    try {
      await context.read<OrderProvider>().loadAllOrders();

      if (!mounted) return;

      await _loadMissingPaymentRecords(context.read<OrderProvider>().orders);
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // Xử lý _refresh: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    await _loadPage();
  }

  // Tải payment cho danh sách đơn: gom thành một request thay vì một request cho mỗi đơn.
  // Nạp payment còn thiếu (_loadMissingPaymentRecords): lấy trạng thái thanh toán theo order và cập nhật cache.
  Future<void> _loadMissingPaymentRecords(List<OrderModel> orders) async {
    final missingOrders =
        orders
            .where((order) => !_paymentsByOrderId.containsKey(order.id))
            .toList();

    if (missingOrders.isEmpty) return;

    try {
      final loaded = await _paymentService.fetchLatestByOrderIds(
        missingOrders.map((order) => order.id),
      );

      if (!mounted) return;

      setState(() {
        for (final order in missingOrders) {
          _paymentsByOrderId[order.id] = loaded[order.id];
        }
      });
    } catch (error) {
      debugPrint('Manager load payment records error: $error');

      if (!mounted) return;
      setState(() {
        for (final order in missingOrders) {
          _paymentsByOrderId.putIfAbsent(order.id, () => null);
        }
      });
    }
  }

  // Lấy kế tiếp trạng thái (_getNextStatus): truy xuất và trả kết quả cho lớp gọi.
  String _getNextStatus(String status) {
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

  // Xử lý _nextActionText: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  String _nextActionText(String nextStatus) {
    switch (nextStatus) {
      case 'confirmed':
        return 'Xác nhận';
      case 'preparing':
        return 'Chuẩn bị món';
      case 'delivering':
        return 'Bắt đầu giao';
      case 'completed':
        return 'Hoàn thành';
      default:
        return '';
    }
  }

  // Xử lý _nextActionIcon: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  IconData _nextActionIcon(String nextStatus) {
    switch (nextStatus) {
      case 'confirmed':
        return Icons.verified_rounded;
      case 'preparing':
        return Icons.restaurant_rounded;
      case 'delivering':
        return Icons.delivery_dining_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  // Kiểm tra điều kiện (_canCancel): đánh giá khả năng cancel và trả kết quả cho lớp gọi.
  bool _canCancel(OrderModel order) {
    return order.orderStatus == 'placed' || order.orderStatus == 'confirmed';
  }

  // Xử lý _paymentText: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  String _paymentText(OrderModel order) {
    final payment = _paymentsByOrderId[order.id];

    if (payment != null) {
      return payment.statusText;
    }

    switch (order.paymentStatus) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Đang chờ';
      case 'failed':
        return 'Thất bại';
      default:
        return 'Chưa thanh toán';
    }
  }

  // Xử lý _paymentColor: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  Color _paymentColor(OrderModel order) {
    final status = _paymentsByOrderId[order.id]?.status ?? order.paymentStatus;

    switch (status) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  // Lọc/tìm đơn hàng (_filterOrders): tạo tập dữ liệu phù hợp theo điều kiện đang chọn.
  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (selectedFilter) {
      case 'all':
        return orders;
      case 'processing':
        return orders.where((order) => order.isActive).toList();
      case 'completed':
        return orders.where((order) => order.isCompleted).toList();
      case 'cancelled':
        return orders.where((order) => order.isCancelled).toList();
      default:
        return orders
            .where((order) => order.orderStatus == selectedFilter)
            .toList();
    }
  }

  // Xử lý _countByFilter: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  int _countByFilter(List<OrderModel> orders, String filter) {
    if (filter == 'all') return orders.length;

    if (filter == 'processing') {
      return orders.where((order) => order.isActive).length;
    }

    if (filter == 'completed') {
      return orders.where((order) => order.isCompleted).length;
    }

    if (filter == 'cancelled') {
      return orders.where((order) => order.isCancelled).length;
    }

    return orders.where((order) => order.orderStatus == filter).length;
  }

  // Định dạng price (_formatPrice): chuyển dữ liệu thô thành giá trị dễ đọc để hiển thị.
  String _formatPrice(double price) {
    final text = price.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '$bufferđ';
  }

  // Xử lý _shortOrderId: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  String _shortOrderId(String orderId) {
    if (orderId.length <= 8) {
      return orderId.toUpperCase();
    }

    return orderId.substring(0, 8).toUpperCase();
  }

  // Hiển thị result (_showResult): mở thông báo/dialog hoặc thành phần hỗ trợ trên giao diện.
  void _showResult({
    required bool success,
    required String successMessage,
    String? errorMessage,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? successMessage : errorMessage ?? 'Thao tác thất bại.',
        ),
        backgroundColor:
            success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ),
    );
  }

  // Cập nhật trạng thái (_updateStatus): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<void> _updateStatus(
    OrderProvider provider,
    OrderModel order,
    String nextStatus,
  ) async {
    if (_updatingOrderId != null || nextStatus.isEmpty) {
      return;
    }

    setState(() => _updatingOrderId = order.id);

    final success = await provider.updateOrderStatus(
      orderId: order.id,
      status: nextStatus,
      reloadAll: false,
    );

    if (!mounted) return;

    setState(() => _updatingOrderId = null);

    _showResult(
      success: success,
      successMessage: 'Đã cập nhật đơn #${_shortOrderId(order.id)}.',
      errorMessage: provider.errorMessage,
    );
  }

  // Hủy đơn (_cancelOrder): xác nhận thao tác, cập nhật trạng thái đơn và làm mới dữ liệu liên quan.
  Future<void> _cancelOrder(OrderProvider provider, OrderModel order) async {
    if (!_canCancel(order) || _updatingOrderId != null) {
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CancelOrderDialog(orderCode: _shortOrderId(order.id)),
    );

    if (!mounted || reason == null || reason.trim().isEmpty) {
      return;
    }

    setState(() => _updatingOrderId = order.id);

    final success = await provider.updateOrderStatus(
      orderId: order.id,
      status: 'cancelled',
      cancelReason: reason.trim(),
      reloadAll: false,
    );

    if (!mounted) return;

    setState(() => _updatingOrderId = null);

    _showResult(
      success: success,
      successMessage: 'Đã hủy đơn #${_shortOrderId(order.id)}.',
      errorMessage: provider.errorMessage,
    );
  }

  // Bật/tắt expanded (_toggleExpanded): đảo trạng thái hiện tại theo thao tác người dùng.
  void _toggleExpanded(String orderId) {
    setState(() {
      if (_expandedOrderIds.contains(orderId)) {
        _expandedOrderIds.remove(orderId);
      } else {
        _expandedOrderIds.add(orderId);
      }
    });
  }

  // Xây dựng giao diện (build): dựng cây widget của _ManagerOrdersPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final allOrders = provider.orders;
    final visibleOrders = _filterOrders(allOrders);

    return AppLayout(
      title: 'Quản lý đơn hàng',
      showBack: true,
      child: AppBody(
        child:
            _isInitialLoading && allOrders.isEmpty
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEF2A39)),
                )
                : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _OrdersHeader(
                          total: allOrders.length,
                          processing: _countByFilter(allOrders, 'processing'),
                          completed: _countByFilter(allOrders, 'completed'),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildFilterBar(allOrders)),
                      if (_isRefreshing)
                        const SliverToBoxAdapter(
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (visibleOrders.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyOrders(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                          sliver: SliverList.separated(
                            itemCount: visibleOrders.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = visibleOrders[index];

                              final nextStatus = _getNextStatus(
                                order.orderStatus,
                              );

                              return _OrderCard(
                                order: order,
                                shortOrderId: _shortOrderId(order.id),
                                statusColor: OrderStatusHelper.getColor(
                                  order.orderStatus,
                                ),
                                nextStatus: nextStatus,
                                nextActionText: _nextActionText(nextStatus),
                                nextActionIcon: _nextActionIcon(nextStatus),
                                canCancel: _canCancel(order),
                                isUpdating: _updatingOrderId == order.id,
                                isExpanded: _expandedOrderIds.contains(
                                  order.id,
                                ),
                                paymentText: _paymentText(order),
                                paymentColor: _paymentColor(order),
                                onNext:
                                    () => _updateStatus(
                                      provider,
                                      order,
                                      nextStatus,
                                    ),
                                onCancel: () => _cancelOrder(provider, order),
                                onToggleExpanded:
                                    () => _toggleExpanded(order.id),
                                formatPrice: _formatPrice,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  // Tạo giao diện bộ lọc bar (_buildFilterBar): dựng widget con từ dữ liệu hiện tại.
  Widget _buildFilterBar(List<OrderModel> orders) {
    final filters = [
      ('processing', 'Đang xử lý'),
      ('placed', 'Mới đặt'),
      ('confirmed', 'Đã xác nhận'),
      ('preparing', 'Đang chuẩn bị'),
      ('delivering', 'Đang giao'),
      ('completed', 'Hoàn thành'),
      ('cancelled', 'Đã hủy'),
      ('all', 'Tất cả'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children:
            filters.map((filter) {
              final value = filter.$1;
              final label = filter.$2;
              final selected = selectedFilter == value;
              final count = _countByFilter(orders, value);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  label: Text('$label ($count)'),
                  selectedColor: const Color(0xFFEF2A39),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color:
                        selected
                            ? const Color(0xFFEF2A39)
                            : const Color(0xFFE2E8F0),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => setState(() => selectedFilter = value),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// Lớp _CancelOrderDialog: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _CancelOrderDialog extends StatefulWidget {
  final String orderCode;

  // Khởi tạo _CancelOrderDialog: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _CancelOrderDialog({required this.orderCode});

  // Tạo state (createState): liên kết _CancelOrderDialog với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

// Lớp _CancelOrderDialogState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  late final TextEditingController _controller;
  String? _validationMessage;
  bool _isClosing = false;

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  // Giải phóng tài nguyên (dispose): hủy controller/listener khi widget bị loại khỏi cây giao diện.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Điều hướng (_closeWithoutResult): xử lý dữ liệu cần thiết rồi chuyển sang màn hình/route phù hợp.
  void _closeWithoutResult() {
    if (_isClosing) return;

    setState(() => _isClosing = true);
    Navigator.of(context).pop();
  }

  // Điều hướng (_submit): xử lý dữ liệu cần thiết rồi chuyển sang màn hình/route phù hợp.
  void _submit() {
    if (_isClosing) return;

    final reason = _controller.text.trim();

    if (reason.isEmpty) {
      setState(() {
        _validationMessage = 'Vui lòng nhập lý do hủy.';
      });
      return;
    }

    setState(() => _isClosing = true);
    Navigator.of(context).pop(reason);
  }

  // Xây dựng giao diện (build): dựng cây widget của _CancelOrderDialogState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isClosing,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Hủy đơn #${widget.orderCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động này không thể hoàn tác. '
              'Khách hàng sẽ nhận được thông báo '
              'kèm lý do hủy.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isClosing,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Lý do hủy',
                hintText: 'Ví dụ: Món tạm hết, không thể giao...',
                border: const OutlineInputBorder(),
                errorText: _validationMessage,
              ),
              onChanged: (_) {
                if (_validationMessage != null) {
                  setState(() {
                    _validationMessage = null;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isClosing ? null : _closeWithoutResult,
            child: const Text('Quay lại'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: _isClosing ? null : _submit,
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }
}

// Lớp _OrdersHeader: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _OrdersHeader extends StatelessWidget {
  final int total;
  final int processing;
  final int completed;

  // Khởi tạo _OrdersHeader: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _OrdersHeader({
    required this.total,
    required this.processing,
    required this.completed,
  });

  // Xây dựng giao diện (build): dựng cây widget của _OrdersHeader từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Tổng đơn',
            value: '$total',
            icon: Icons.receipt_long_rounded,
          ),
          const _SummaryDivider(),
          _SummaryItem(
            label: 'Đang xử lý',
            value: '$processing',
            icon: Icons.timelapse_rounded,
          ),
          const _SummaryDivider(),
          _SummaryItem(
            label: 'Hoàn thành',
            value: '$completed',
            icon: Icons.done_all_rounded,
          ),
        ],
      ),
    );
  }
}

// Lớp _SummaryItem: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  // Khởi tạo _SummaryItem: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  // Xây dựng giao diện (build): dựng cây widget của _SummaryItem từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFEF2A39), size: 21),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Lớp _SummaryDivider: thành phần phục vụ màn hình manager app quản lý đơn hàng.
class _SummaryDivider extends StatelessWidget {
  // Khởi tạo _SummaryDivider: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _SummaryDivider();

  // Xây dựng giao diện (build): dựng cây widget của _SummaryDivider từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 46, color: const Color(0xFFFECACA));
  }
}

// Lớp _OrderCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String shortOrderId;
  final Color statusColor;
  final String nextStatus;
  final String nextActionText;
  final IconData nextActionIcon;
  final bool canCancel;
  final bool isUpdating;
  final bool isExpanded;
  final String paymentText;
  final Color paymentColor;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final VoidCallback onToggleExpanded;
  final String Function(double) formatPrice;

  // Khởi tạo _OrderCard: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _OrderCard({
    required this.order,
    required this.shortOrderId,
    required this.statusColor,
    required this.nextStatus,
    required this.nextActionText,
    required this.nextActionIcon,
    required this.canCancel,
    required this.isUpdating,
    required this.isExpanded,
    required this.paymentText,
    required this.paymentColor,
    required this.onNext,
    required this.onCancel,
    required this.onToggleExpanded,
    required this.formatPrice,
  });

  // Xây dựng giao diện (build): dựng cây widget của _OrderCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isUpdating
                  ? statusColor.withValues(alpha: 0.55)
                  : const Color(0xFFE5E7EB),
          width: isUpdating ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isUpdating)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn #$shortOrderId',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.receiverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.receiverPhone,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(order.totalAmount),
                          style: const TextStyle(
                            color: Color(0xFFEF2A39),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusBadge(
                          text: OrderStatusHelper.getText(order.orderStatus),
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _OrderProgress(
                  currentStatus: order.orderStatus,
                  color: statusColor,
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.hasDeliveryCoordinates) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _openDeliveryDirections(context, order),
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Mở chỉ đường'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      text: order.paymentMethod,
                    ),
                    _InfoChip(
                      icon: Icons.account_balance_wallet_outlined,
                      text: paymentText,
                      color: paymentColor,
                    ),
                    _InfoChip(
                      icon: Icons.restaurant_menu_rounded,
                      text: '${order.items.length} món',
                    ),
                    if (order.distanceKm > 0)
                      _InfoChip(
                        icon: Icons.route_outlined,
                        text: '${order.distanceKm.toStringAsFixed(1)} km',
                      ),
                  ],
                ),
                if (order.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ghi chú: ${order.note}',
                      style: const TextStyle(
                        color: Color(0xFF9A3412),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                if (order.cancelReason.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lý do hủy: ${order.cancelReason}',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 19),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            isExpanded
                                ? 'Ẩn món đã đặt'
                                : 'Xem ${order.items.length} món đã đặt',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState:
                      isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: _OrderItems(
                    order: order,
                    formatPrice: formatPrice,
                  ),
                ),
                if (nextStatus.isNotEmpty || canCancel) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (nextStatus.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            onPressed: isUpdating ? null : onNext,
                            icon:
                                isUpdating
                                    ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Icon(nextActionIcon),
                            label: Text(
                              isUpdating ? 'Đang cập nhật...' : nextActionText,
                            ),
                          ),
                        ),
                      if (nextStatus.isNotEmpty && canCancel)
                        const SizedBox(width: 9),
                      if (canCancel)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onPressed: isUpdating ? null : onCancel,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Hủy'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _OrderProgress: thành phần phục vụ màn hình manager app quản lý đơn hàng.
class _OrderProgress extends StatelessWidget {
  final String currentStatus;
  final Color color;

  // Khởi tạo _OrderProgress: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _OrderProgress({required this.currentStatus, required this.color});

  // Xử lý _step: thực hiện phần nghiệp vụ tương ứng trong màn hình manager app quản lý đơn hàng.
  int _step() {
    switch (currentStatus) {
      case 'placed':
        return 1;
      case 'confirmed':
        return 2;
      case 'preparing':
        return 3;
      case 'delivering':
        return 4;
      case 'completed':
        return 5;
      default:
        return 0;
    }
  }

  // Xây dựng giao diện (build): dựng cây widget của _OrderProgress từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'cancelled') {
      return const Row(
        children: [
          Icon(Icons.cancel_rounded, size: 17, color: Color(0xFFDC2626)),
          SizedBox(width: 6),
          Text(
            'Đơn hàng đã kết thúc do bị hủy',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final currentStep = _step();

    return Row(
      children: List.generate(5, (index) {
        final active = index < currentStep;

        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == 4 ? 0 : 5),
            decoration: BoxDecoration(
              color: active ? color : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

// Lớp _OrderItems: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _OrderItems extends StatelessWidget {
  final OrderModel order;
  final String Function(double) formatPrice;

  // Khởi tạo _OrderItems: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _OrderItems({required this.order, required this.formatPrice});

  // Xây dựng giao diện (build): dựng cây widget của _OrderItems từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Chưa có chi tiết món.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children:
            order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 29,
                      height: 29,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                          if (item.note.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'Ghi chú: ${item.note.trim()}',
                                style: const TextStyle(
                                  color: Color(0xFF9A3412),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatPrice(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

// Lớp _StatusBadge: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  // Khởi tạo _StatusBadge: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _StatusBadge({required this.text, required this.color});

  // Xây dựng giao diện (build): dựng cây widget của _StatusBadge từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Lớp _InfoChip: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  // Khởi tạo _InfoChip: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _InfoChip({required this.icon, required this.text, this.color});

  // Xây dựng giao diện (build): dựng cây widget của _InfoChip từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _EmptyOrders: thành phần phục vụ màn hình manager app quản lý đơn hàng.
class _EmptyOrders extends StatelessWidget {
  // Khởi tạo _EmptyOrders: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý đơn hàng.
  const _EmptyOrders();

  // Xây dựng giao diện (build): dựng cây widget của _EmptyOrders từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 68,
              color: Colors.grey.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không có đơn hàng phù hợp',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              'Hãy chọn bộ lọc khác hoặc kéo xuống để làm mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
