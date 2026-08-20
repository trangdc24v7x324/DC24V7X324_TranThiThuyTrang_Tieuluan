// FILE HỌC TẬP: lib/features/notification/notification_page.dart
// Vai trò: Màn hình thông báo.
// Luồng sử dụng: Tải, hiển thị và cập nhật trạng thái thông báo theo vai trò người dùng.

import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/app_notification_model.dart';
import 'package:project_trangdc24v7x324/providers/notification_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_card.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:provider/provider.dart';

// Lớp NotificationsPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class NotificationsPage extends StatefulWidget {
  // Khởi tạo NotificationsPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình thông báo.
  const NotificationsPage({super.key});

  // Tạo state (createState): liên kết NotificationsPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

// Lớp _NotificationsPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _NotificationsPageState extends State<NotificationsPage> {
  String selectedFilter = 'all';

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationProvider>().loadCustomerNotifications();
    });
  }

  // Lấy biểu tượng (_getIcon): truy xuất và trả kết quả cho lớp gọi.
  IconData _getIcon(String type) {
    switch (type) {
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'new_product':
        return Icons.fastfood_rounded;
      case 'general':
        return Icons.campaign_rounded;
      case 'order':
      case 'order_success':
        return Icons.check_circle_rounded;
      case 'order_confirmed':
        return Icons.verified_rounded;
      case 'order_preparing':
        return Icons.restaurant_rounded;
      case 'order_delivering':
        return Icons.delivery_dining_rounded;
      case 'order_completed':
        return Icons.done_all_rounded;
      case 'order_cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Lấy color (_getColor): truy xuất và trả kết quả cho lớp gọi.
  Color _getColor(String type) {
    switch (type) {
      case 'promotion':
        return const Color(0xFFF97316);
      case 'new_product':
        return const Color(0xFF22C55E);
      case 'general':
        return const Color(0xFF2563EB);
      case 'order':
      case 'order_success':
      case 'order_confirmed':
      case 'order_completed':
        return const Color(0xFF16A34A);
      case 'order_preparing':
        return const Color(0xFFF59E0B);
      case 'order_delivering':
        return const Color(0xFF0284C7);
      case 'order_cancelled':
        return const Color(0xFF64748B);
      default:
        return AppColors.primary;
    }
  }

  // Xử lý _typeLabel: thực hiện phần nghiệp vụ tương ứng trong màn hình thông báo.
  String _typeLabel(String type) {
    switch (type) {
      case 'promotion':
        return 'Khuyến mãi';
      case 'new_product':
        return 'Sản phẩm mới';
      case 'general':
        return 'Thông báo chung';
      case 'order':
      case 'order_success':
        return 'Đơn hàng';
      case 'order_confirmed':
        return 'Xác nhận đơn';
      case 'order_preparing':
        return 'Chuẩn bị đơn';
      case 'order_delivering':
        return 'Đang giao';
      case 'order_completed':
        return 'Hoàn thành';
      case 'order_cancelled':
        return 'Đã hủy';
      default:
        return 'Thông báo';
    }
  }

  // Kiểm tra điều kiện (_isOrderType): đánh giá trạng thái đơn hàng loại và trả kết quả cho lớp gọi.
  bool _isOrderType(String type) {
    return type == 'order' ||
        type == 'order_success' ||
        type == 'order_confirmed' ||
        type == 'order_preparing' ||
        type == 'order_delivering' ||
        type == 'order_completed' ||
        type == 'order_cancelled';
  }

  // Lọc/tìm thông báo (_filterNotifications): tạo tập dữ liệu phù hợp theo điều kiện đang chọn.
  List<AppNotificationModel> _filterNotifications(
    List<AppNotificationModel> notifications,
  ) {
    switch (selectedFilter) {
      case 'unread':
        return notifications.where((item) => !item.isRead).toList();
      case 'orders':
        return notifications.where((item) => _isOrderType(item.type)).toList();
      case 'promotion':
        return notifications.where((item) => item.type == 'promotion').toList();
      case 'new_product':
        return notifications
            .where((item) => item.type == 'new_product')
            .toList();
      case 'general':
        return notifications.where((item) => item.type == 'general').toList();
      default:
        return notifications;
    }
  }

  // Định dạng thời gian (_formatTime): chuyển dữ liệu thô thành giá trị dễ đọc để hiển thị.
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month/${time.year}';
  }

  // Xử lý tap thông báo (_handleTapNotification): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
  Future<void> _handleTapNotification(
    NotificationProvider provider,
    AppNotificationModel item,
  ) async {
    if (!item.isRead) {
      final success = await provider.markAsRead(item.id);

      if (!success) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Không thể đánh dấu thông báo đã đọc.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    if (_isOrderType(item.type) && item.orderId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.orderDetail,
        arguments: item.orderId,
      );
      return;
    }

    // Khuyến mãi / sản phẩm mới / thông báo chung chỉ cần đánh dấu đã đọc.
    // Không hiển thị cảnh báo "không liên kết với đơn hàng".
  }

  // Tạo giao diện bộ lọc chips (_buildFilterChips): dựng widget con từ dữ liệu hiện tại.
  Widget _buildFilterChips(NotificationProvider provider) {
    final filters = [
      _NotificationFilter('all', 'Tất cả', Icons.notifications_rounded),
      _NotificationFilter(
        'unread',
        'Chưa đọc',
        Icons.mark_email_unread_rounded,
      ),
      _NotificationFilter('orders', 'Đơn hàng', Icons.receipt_long_rounded),
      _NotificationFilter('promotion', 'Khuyến mãi', Icons.local_offer_rounded),
      _NotificationFilter(
        'new_product',
        'Sản phẩm mới',
        Icons.fastfood_rounded,
      ),
      _NotificationFilter('general', 'Chung', Icons.campaign_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children:
            filters.map((filter) {
              final selected = selectedFilter == filter.value;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  avatar: Icon(
                    filter.icon,
                    size: 17,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  label: Text(filter.label),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color:
                        selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (_) {
                    setState(() => selectedFilter = filter.value);
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  // Tạo giao diện top actions (_buildTopActions): dựng widget con từ dữ liệu hiện tại.
  Widget _buildTopActions(NotificationProvider provider) {
    if (provider.notifications.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              provider.hasUnread
                  ? '${provider.unreadCount} thông báo chưa đọc'
                  : 'Tất cả thông báo đã đọc',
              style: AppText.body.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (provider.hasUnread)
            TextButton.icon(
              onPressed: () async {
                final success = await provider.markAllAsRead();

                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'Không thể đánh dấu tất cả thông báo đã đọc.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Đọc tất cả'),
            ),
        ],
      ),
    );
  }

  // Tạo giao diện rỗng trạng thái (_buildEmptyState): dựng widget con từ dữ liệu hiện tại.
  Widget _buildEmptyState(String message) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        Icon(
          Icons.notifications_off_rounded,
          size: 70,
          color: AppColors.textGrey.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.textGrey),
        ),
      ],
    );
  }

  // Xử lý _orderStep: thực hiện phần nghiệp vụ tương ứng trong màn hình thông báo.
  int _orderStep(String type) {
    switch (type) {
      case 'order_success':
        return 1;
      case 'order_confirmed':
        return 2;
      case 'order_preparing':
        return 3;
      case 'order_delivering':
        return 4;
      case 'order_completed':
        return 5;
      default:
        return 0;
    }
  }

  // Tạo giao diện đơn hàng progress (_buildOrderProgress): dựng widget con từ dữ liệu hiện tại.
  Widget _buildOrderProgress(String type, Color color) {
    final currentStep = _orderStep(type);

    if (currentStep == 0 || type == 'order_cancelled') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(5, (index) {
          final step = index + 1;
          final active = step <= currentStep;

          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: index == 4 ? 0 : 5),
              decoration: BoxDecoration(
                color: active ? color : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Xử lý _shortOrderId: thực hiện phần nghiệp vụ tương ứng trong màn hình thông báo.
  String _shortOrderId(String orderId) {
    if (orderId.length <= 8) {
      return orderId.toUpperCase();
    }

    return orderId.substring(0, 8).toUpperCase();
  }

  // Tạo giao diện thông báo mục (_buildNotificationItem): dựng widget con từ dữ liệu hiện tại.
  Widget _buildNotificationItem(
    NotificationProvider provider,
    AppNotificationModel item,
  ) {
    final color = _getColor(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _handleTapNotification(provider, item),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(item.type), color: color, size: 24),
            ),
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
                          style: AppText.productTitle.copyWith(
                            fontWeight:
                                item.isRead ? FontWeight.w700 : FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!item.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.body,
                    style: AppText.body.copyWith(
                      color: AppColors.textGrey,
                      height: 1.35,
                    ),
                  ),
                  if (_isOrderType(item.type))
                    _buildOrderProgress(item.type, color),
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _typeLabel(item.type),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (_isOrderType(item.type) && item.orderId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Đơn #${_shortOrderId(item.orderId)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      Text(
                        _formatTime(item.created),
                        style: AppText.body.copyWith(
                          fontSize: 11,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Xây dựng giao diện (build): dựng cây widget của _NotificationsPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Thông báo',
      showBack: true,
      child: AppBody(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredNotifications = _filterNotifications(
              provider.notifications,
            );

            return RefreshIndicator(
              onRefresh: provider.loadCustomerNotifications,
              child: Column(
                children: [
                  _buildFilterChips(provider),
                  _buildTopActions(provider),
                  Expanded(
                    child:
                        filteredNotifications.isEmpty
                            ? _buildEmptyState(
                              provider.notifications.isEmpty
                                  ? 'Chưa có thông báo nào'
                                  : 'Không có thông báo phù hợp với bộ lọc này',
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                              itemCount: filteredNotifications.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = filteredNotifications[index];
                                return _buildNotificationItem(provider, item);
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Lớp _NotificationFilter: thành phần phục vụ màn hình thông báo.
class _NotificationFilter {
  final String value;
  final String label;
  final IconData icon;

  // Khởi tạo _NotificationFilter: nhận các tham số cần thiết để tạo đối tượng cho màn hình thông báo.
  const _NotificationFilter(this.value, this.label, this.icon);
}
