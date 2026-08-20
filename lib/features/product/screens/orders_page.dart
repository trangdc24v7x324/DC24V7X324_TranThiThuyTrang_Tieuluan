// FILE HỌC TẬP: lib/features/product/screens/orders_page.dart
// Vai trò: Màn hình đơn hàng.
// Luồng sử dụng: Phục vụ luồng mua hàng: xem món, giỏ hàng, đặt đơn, thanh toán hoặc theo dõi đơn.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/utils/order_status_helper.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';

// DESIGN SYSTEM
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_card.dart';

// Lớp OrdersPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class OrdersPage extends StatefulWidget {
  // Khởi tạo OrdersPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình đơn hàng.
  const OrdersPage({super.key});

  // Tạo state (createState): liên kết OrdersPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

// Lớp _OrdersPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _OrdersPageState extends State<OrdersPage> {
  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrderProvider>().loadOrders();
    });
  }

  // Định dạng giá (formatPrice): chuyển số tiền thành chuỗi dễ đọc để hiển thị.
  String formatPrice(double price) {
    final text = price.round().toString();
    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;
      result.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        result.write('.');
      }
    }

    return '$resultđ';
  }

  // Xây dựng giao diện (build): dựng cây widget của _OrdersPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    return AppLayout(
      title: 'Lịch sử mua hàng',
      showBack: true,

      child: AppBody(
        child:
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? const _EmptyOrders()
                : RefreshIndicator(
                  onRefresh: () {
                    return context.read<OrderProvider>().loadOrders();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      return _OrderCard(
                        orderId: order.id,
                        date:
                            '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                        statusText: OrderStatusHelper.getText(order.status),
                        statusColor: OrderStatusHelper.getColor(order.status),
                        total: formatPrice(order.totalAmount),
                        receiver:
                            '${order.receiverName} - ${order.receiverPhone}',
                        address: order.address,
                        payment: order.paymentMethod,
                        note: order.note,
                        itemCount: order.items.length,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.orderDetail,
                            arguments: order.id,
                          );
                        },
                      );
                    },
                  ),
                ),
      ),
    );
  }
}

// Lớp _EmptyOrders: thành phần phục vụ màn hình đơn hàng.
class _EmptyOrders extends StatelessWidget {
  // Khởi tạo _EmptyOrders: nhận các tham số cần thiết để tạo đối tượng cho màn hình đơn hàng.
  const _EmptyOrders();

  // Xây dựng giao diện (build): dựng cây widget của _EmptyOrders từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Chưa có đơn hàng nào',
        style: AppText.body.copyWith(color: AppColors.textGrey),
      ),
    );
  }
}

// Lớp _OrderCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _OrderCard extends StatelessWidget {
  final String orderId;
  final String date;
  final String statusText;
  final Color statusColor;
  final String total;
  final String receiver;
  final String address;
  final String payment;
  final String note;
  final int itemCount;
  final VoidCallback onTap;

  // Khởi tạo _OrderCard: nhận các tham số cần thiết để tạo đối tượng cho màn hình đơn hàng.
  const _OrderCard({
    required this.orderId,
    required this.date,
    required this.statusText,
    required this.statusColor,
    required this.total,
    required this.receiver,
    required this.address,
    required this.payment,
    required this.note,
    required this.itemCount,
    required this.onTap,
  });

  // Xây dựng giao diện (build): dựng cây widget của _OrderCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn hàng #$orderId',
                      style: AppText.productTitle,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textGrey),
                ],
              ),

              const SizedBox(height: 12),

              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: 'Ngày đặt: $date',
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text('Trạng thái: ', style: AppText.body),
                  _StatusBadge(text: statusText, color: statusColor),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text('Tổng tiền: ', style: AppText.body),
                  Text(total, style: AppText.price),
                ],
              ),

              const SizedBox(height: 8),

              _InfoRow(
                icon: Icons.fastfood_outlined,
                text: 'Số món: $itemCount',
              ),

              const SizedBox(height: 8),

              _InfoRow(icon: Icons.person_outline, text: receiver),

              const SizedBox(height: 8),

              _InfoRow(
                icon: Icons.location_on_outlined,
                text: 'Địa chỉ: $address',
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Xem chi tiết',
                  style: AppText.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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

// Lớp _InfoRow: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  // Khởi tạo _InfoRow: nhận các tham số cần thiết để tạo đối tượng cho màn hình đơn hàng.
  const _InfoRow({required this.icon, required this.text});

  // Xây dựng giao diện (build): dựng cây widget của _InfoRow từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppText.body)),
      ],
    );
  }
}

// Lớp _StatusBadge: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  // Khởi tạo _StatusBadge: nhận các tham số cần thiết để tạo đối tượng cho màn hình đơn hàng.
  const _StatusBadge({required this.text, required this.color});

  // Xây dựng giao diện (build): dựng cây widget của _StatusBadge từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
