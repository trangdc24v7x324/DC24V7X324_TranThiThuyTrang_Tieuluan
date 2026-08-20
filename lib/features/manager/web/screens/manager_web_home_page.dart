// FILE HỌC TẬP: lib/features/manager/web/screens/manager_web_home_page.dart
// Vai trò: Màn hình Manager Web quản lý trang chủ.
// Luồng sử dụng: Hiển thị nghiệp vụ quản lý trên trình duyệt và điều phối dữ liệu qua Provider/Service.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_stat_card.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

// Lớp ManagerWebHomePage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerWebHomePage extends StatefulWidget {
  // Khởi tạo ManagerWebHomePage: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const ManagerWebHomePage({super.key});

  // Tạo state (createState): liên kết ManagerWebHomePage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<ManagerWebHomePage> createState() => _ManagerWebHomePageState();
}

// Lớp _ManagerWebHomePageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _ManagerWebHomePageState extends State<ManagerWebHomePage> {
  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  // Tải dữ liệu (_loadData): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> _loadData() async {
    final managerId = pb.authStore.model?.id ?? '';

    final futures = <Future<void>>[
      context.read<OrderProvider>().loadAllOrders(),
      context.read<ProfileProvider>().loadProfile(),
    ];

    if (managerId.isNotEmpty) {
      futures.add(
        context.read<ChatProvider>().loadManagerChatSummary(
          managerId: managerId,
        ),
      );
    }

    await Future.wait(futures);
  }

  // Đăng xuất (_logout): kết thúc phiên, làm sạch state liên quan và đưa người dùng về trang đăng nhập.
  void _logout() {
    pb.authStore.clear();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  // Mở định tuyến (_openRoute): điều hướng hoặc hiển thị thành phần tương ứng từ thao tác người dùng.
  Future<void> _openRoute(String routeName) async {
    await Navigator.pushNamed(context, routeName);

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  // Xây dựng giao diện (build): dựng cây widget của _ManagerWebHomePageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final profile = profileProvider.profile;
    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';
    final avatarUrl = profile?.avatarUrl ?? '';

    return ManagerWebLayout(
      title: 'Tổng quan quản lý',
      currentRoute: AppRoutes.managerHome,
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeBanner(
                    managerName: managerName,
                    pendingOrders: orderProvider.pendingOrderCount,
                    unreadMessages: chatProvider.unreadCount,
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Chỉ số tổng quan',
                    subtitle: 'Dữ liệu được lấy từ hệ thống hiện tại',
                    actionLabel: 'Làm mới',
                    onAction: _loadData,
                  ),
                  const SizedBox(height: 14),
                  _ResponsiveStatsGrid(
                    children: [
                      ManagerStatCard(
                        title: 'Đơn chờ xử lý',
                        value: '${orderProvider.pendingOrderCount}',
                        note: 'Cần kiểm tra',
                        icon: Icons.pending_actions_rounded,
                        accentColor: const Color(0xFFF59E0B),
                        onTap: () {
                          _openRoute(AppRoutes.managerOrders);
                        },
                      ),
                      ManagerStatCard(
                        title: 'Đơn hoàn thành',
                        value: '${orderProvider.completedOrderCount}',
                        note: 'Đã hoàn tất',
                        icon: Icons.check_circle_rounded,
                        accentColor: AppColors.success,
                        onTap: () {
                          _openRoute(AppRoutes.managerOrders);
                        },
                      ),
                      ManagerStatCard(
                        title: 'Tin nhắn chưa đọc',
                        value: '${chatProvider.unreadCount}',
                        note: 'Phản hồi khách hàng',
                        icon: Icons.mark_chat_unread_rounded,
                        accentColor: const Color(0xFF2563EB),
                        onTap: () {
                          _openRoute(AppRoutes.managerChat);
                        },
                      ),
                      ManagerStatCard(
                        title: 'Cuộc trò chuyện',
                        value: '${chatProvider.totalRooms}',
                        note: 'Tổng số khách đã chat',
                        icon: Icons.forum_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        onTap: () {
                          _openRoute(AppRoutes.managerChat);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _SectionHeader(
                    title: 'Chức năng quản lý',
                    subtitle: 'Truy cập nhanh các phân hệ chính',
                  ),
                  const SizedBox(height: 14),
                  _QuickActionGrid(
                    actions: [
                      _QuickAction(
                        title: 'Sản phẩm',
                        subtitle: 'Thêm, sửa, xóa và cập nhật giá bán',
                        icon: Icons.fastfood_rounded,
                        color: AppColors.primary,
                        routeName: AppRoutes.managerProducts,
                      ),
                      _QuickAction(
                        title: 'Danh mục',
                        subtitle: 'Sắp xếp nhóm món ăn và thức uống',
                        icon: Icons.category_rounded,
                        color: const Color(0xFFF97316),
                        routeName: AppRoutes.managerCategories,
                      ),
                      _QuickAction(
                        title: 'Đơn hàng',
                        subtitle: 'Xác nhận và cập nhật trạng thái giao hàng',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF0284C7),
                        routeName: AppRoutes.managerOrders,
                        badge: orderProvider.pendingOrderCount,
                      ),
                      _QuickAction(
                        title: 'Doanh thu',
                        subtitle: 'Theo dõi kết quả bán hàng',
                        icon: Icons.bar_chart_rounded,
                        color: AppColors.success,
                        routeName: AppRoutes.managerRevenue,
                      ),
                      _QuickAction(
                        title: 'Tin nhắn',
                        subtitle: 'Trao đổi trực tiếp với khách hàng',
                        icon: Icons.forum_rounded,
                        color: const Color(0xFF8B5CF6),
                        routeName: AppRoutes.managerChat,
                        badge: chatProvider.unreadCount,
                      ),
                      _QuickAction(
                        title: 'Thông báo',
                        subtitle: 'Gửi nội dung đến người dùng',
                        icon: Icons.notifications_active_rounded,
                        color: const Color(0xFF0F766E),
                        routeName: AppRoutes.managerNotifications,
                      ),
                    ],
                    onOpen: _openRoute,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Lớp _WelcomeBanner: thành phần phục vụ màn hình manager web quản lý trang chủ.
class _WelcomeBanner extends StatelessWidget {
  final String managerName;
  final int pendingOrders;
  final int unreadMessages;

  // Khởi tạo _WelcomeBanner: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const _WelcomeBanner({
    required this.managerName,
    required this.pendingOrders,
    required this.unreadMessages,
  });

  // Xây dựng giao diện (build): dựng cây widget của _WelcomeBanner từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7380), AppColors.primary, Color(0xFFD91F2D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 18,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $managerName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 24 : 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hôm nay hệ thống có $pendingOrders đơn cần xử lý '
                  'và $unreadMessages tin nhắn chưa đọc.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: isCompact ? 14 : 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 65,
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _SectionHeader: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  // Khởi tạo _SectionHeader: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  // Xây dựng giao diện (build): dựng cây widget của _SectionHeader từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

// Lớp _ResponsiveStatsGrid: thành phần phục vụ màn hình manager web quản lý trang chủ.
class _ResponsiveStatsGrid extends StatelessWidget {
  final List<Widget> children;

  // Khởi tạo _ResponsiveStatsGrid: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const _ResponsiveStatsGrid({required this.children});

  // Xây dựng giao diện (build): dựng cây widget của _ResponsiveStatsGrid từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 1180) {
          columns = 4;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        }

        const spacing = 14.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              children
                  .map((child) => SizedBox(width: itemWidth, child: child))
                  .toList(),
        );
      },
    );
  }
}

// Lớp _QuickActionGrid: thành phần phục vụ màn hình manager web quản lý trang chủ.
class _QuickActionGrid extends StatelessWidget {
  final List<_QuickAction> actions;
  final ValueChanged<String> onOpen;

  // Khởi tạo _QuickActionGrid: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const _QuickActionGrid({required this.actions, required this.onOpen});

  // Xây dựng giao diện (build): dựng cây widget của _QuickActionGrid từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 1100) {
          columns = 3;
        } else if (constraints.maxWidth >= 680) {
          columns = 2;
        }

        const spacing = 14.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              actions.map((action) {
                return SizedBox(
                  width: itemWidth,
                  child: _QuickActionCard(
                    action: action,
                    onTap: () {
                      onOpen(action.routeName);
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

// Lớp _QuickActionCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;

  // Khởi tạo _QuickActionCard: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const _QuickActionCard({required this.action, required this.onTap});

  // Xây dựng giao diện (build): dựng cây widget của _QuickActionCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(action.icon, color: action.color, size: 28),
                  ),
                  if (action.badge > 0)
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          action.badge > 99 ? '99+' : '${action.badge}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textGrey,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lớp _QuickAction: thành phần phục vụ màn hình manager web quản lý trang chủ.
class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String routeName;
  final int badge;

  // Khởi tạo _QuickAction: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager web quản lý trang chủ.
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.routeName,
    this.badge = 0,
  });
}
