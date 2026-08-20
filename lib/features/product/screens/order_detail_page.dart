
import 'package:project_trangdc24v7x324/models/order_item_model.dart';
import 'package:project_trangdc24v7x324/models/order_model.dart';
import 'package:project_trangdc24v7x324/models/payment_record_model.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/services/map_navigation_service.dart';
import 'package:project_trangdc24v7x324/services/payment_service.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final PaymentService _paymentService = PaymentService();

  PaymentRecordModel? _paymentRecord;
  bool _isLoadingPayment = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadDetail);
  }

  Future<void> _loadDetail() async {
    await context.read<OrderProvider>().loadOrderDetail(widget.orderId);

    await _loadPaymentRecord();
  }

  Future<void> _loadPaymentRecord() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingPayment = true;
    });

    try {
      final payment = await _paymentService.fetchByOrderId(widget.orderId);

      if (!mounted) {
        return;
      }

      setState(() {
        _paymentRecord = payment;
      });
    } catch (_) {

      if (mounted) {
        setState(() {
          _paymentRecord = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPayment = false;
        });
      }
    }
  }

  Future<void> _openDeliveryLocation(OrderModel order) async {
    if (!order.hasDeliveryCoordinates) return;

    try {
      await MapNavigationService.openDirections(
        latitude: order.deliveryLatitude,
        longitude: order.deliveryLongitude,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _openPaymentTest() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.paymentTest,
      arguments: {'orderId': widget.orderId},
    );

    if (!mounted) {
      return;
    }

    await _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(title: const Text('Chi tiết đơn hàng'), centerTitle: true),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          final order = provider.selectedOrder;

          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          final bool isCash = _paymentService.isCashMethod(order.paymentMethod);

          final String effectivePaymentStatus =
              _paymentRecord?.status ?? order.paymentStatus;

          final bool canContinuePayment =
              !isCash && effectivePaymentStatus != 'paid';

          return RefreshIndicator(
            onRefresh: _loadDetail,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  title: 'Thông tin đơn hàng',
                  child: Column(
                    children: [
                      _infoRow('Mã đơn', '#${order.id}'),
                      _infoRow('Ngày đặt', _formatDate(order.orderDate)),
                      _infoRow('Trạng thái', _statusText(order.orderStatus)),
                      _infoRow(
                        'Thanh toán',
                        _isLoadingPayment
                            ? 'Đang kiểm tra...'
                            : (_paymentRecord?.statusText ??
                                _paymentText(order.paymentStatus)),
                      ),
                      _infoRow('Phương thức', order.paymentMethod),

                      if (canContinuePayment) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _openPaymentTest,
                            icon: const Icon(Icons.qr_code_2),
                            label: Text(
                              _paymentRecord?.isFailed == true
                                  ? 'Thử thanh toán lại'
                                  : 'Tiếp tục thanh toán',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _section(
                  title: 'Thông tin giao hàng',
                  child: Column(
                    children: [
                      _infoRow('Người nhận', order.receiverName),
                      _infoRow('Số điện thoại', order.receiverPhone),
                      _infoRow('Địa chỉ', order.deliveryAddress),
                      if (order.distanceKm > 0)
                        _infoRow(
                          'Khoảng cách ước tính',
                          '${order.distanceKm.toStringAsFixed(1)} km',
                        ),
                      if (order.hasDeliveryCoordinates) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _openDeliveryLocation(order),
                            icon: const Icon(Icons.directions_outlined),
                            label: const Text('Xem vị trí giao hàng'),
                          ),
                        ),
                      ],
                      if (order.note.trim().isNotEmpty)
                        _infoRow('Ghi chú', order.note),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _section(
                  title: 'Sản phẩm đã đặt',
                  child: Column(
                    children:
                        order.items.map((item) => _orderItem(item)).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                _section(
                  title: 'Thanh toán',
                  child: Column(
                    children: [
                      _moneyRow('Tạm tính', order.subtotal),
                      _moneyRow('Phí giao hàng', order.deliveryFee),
                      _moneyRow('Giảm giá', order.discountAmount),
                      const Divider(),
                      _moneyRow('Tổng cộng', order.totalAmount, isTotal: true),
                    ],
                  ),
                ),

                if (order.cancelReason.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section(
                    title: 'Lý do hủy đơn',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        order.cancelReason,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Không có' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            _formatMoney(value),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: isTotal ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderItem(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _itemImage(item.productImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatMoney(item.unitPrice)} x ${item.quantity}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (item.categoryTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.categoryTitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ghi chú: ${item.note.trim()}',
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatMoney(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _itemImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.fastfood, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 58,
            height: 58,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'placed':
        return 'Đã đặt hàng';
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

  String _paymentText(String status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chưa thanh toán';
      case 'unpaid':
        return 'Chưa thanh toán';
      case 'failed':
        return 'Chưa thanh toán';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year '
        '$hour:$minute';
  }

  String _formatMoney(double value) {
    final text = value.toStringAsFixed(0);

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()}đ';
  }
}
