// FILE HỌC TẬP: lib/features/manager/web/widgets/manager_web_layout.dart
// Vai trò: Widget Web dùng cho web bố cục.
// Luồng sử dụng: Đóng gói thành phần giao diện hoặc tiện ích dùng lại trong khu vực Manager Web.

import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

// Lớp ManagerWebLayout: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class ManagerWebLayout extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  final String managerName;
  final String avatarUrl;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final VoidCallback? onLogout;

  // Khởi tạo ManagerWebLayout: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho web bố cục.
  const ManagerWebLayout({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.managerName = 'Manager',
    this.avatarUrl = '',
    this.actions = const [],
    this.floatingActionButton,
    this.onLogout,
  });

  static const double desktopBreakpoint = 900;

  // Điều hướng định tuyến (_goToRoute): chuyển người dùng tới route phù hợp với luồng hiện tại.
  void _goToRoute(BuildContext context, String routeName) {
    if (routeName == currentRoute) {
      return;
    }

    Navigator.pushReplacementNamed(context, routeName);
  }

  // Xây dựng giao diện (build): dựng cây widget của ManagerWebLayout từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            ManagerSidebar(
              currentRoute: currentRoute,
              managerName: managerName,
              avatarUrl: avatarUrl,
              onRouteSelected: (routeName) {
                _goToRoute(context, routeName);
              },
              onLogout: onLogout,
            ),
            Expanded(
              child: Column(
                children: [
                  ManagerTopBar(
                    title: title,
                    managerName: managerName,
                    avatarUrl: avatarUrl,
                    actions: actions,
                    onProfilePressed: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.bg,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          ...actions,
          const SizedBox(width: 4),
          _AvatarButton(
            avatarUrl: avatarUrl,
            size: 38,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        width: 280,
        child: ManagerSidebar(
          currentRoute: currentRoute,
          managerName: managerName,
          avatarUrl: avatarUrl,
          onRouteSelected: (routeName) {
            Navigator.pop(context);
            _goToRoute(context, routeName);
          },
          onLogout: onLogout,
        ),
      ),
      body: child,
    );
  }
}

// Lớp ManagerTopBar: thành phần phục vụ widget web dùng cho web bố cục.
class ManagerTopBar extends StatelessWidget {
  final String title;
  final String managerName;
  final String avatarUrl;
  final List<Widget> actions;
  final VoidCallback onProfilePressed;

  // Khởi tạo ManagerTopBar: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho web bố cục.
  const ManagerTopBar({
    super.key,
    required this.title,
    required this.managerName,
    required this.avatarUrl,
    required this.actions,
    required this.onProfilePressed,
  });

  // Xây dựng giao diện (build): dựng cây widget của ManagerTopBar từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...actions,
          if (actions.isNotEmpty) const SizedBox(width: 14),
          Container(width: 1, height: 34, color: AppColors.border),
          const SizedBox(width: 16),
          Text(
            managerName.trim().isEmpty ? 'Manager' : managerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          _AvatarButton(
            avatarUrl: avatarUrl,
            size: 42,
            onTap: onProfilePressed,
          ),
        ],
      ),
    );
  }
}

// Lớp ManagerSidebar: thành phần phục vụ widget web dùng cho web bố cục.
class ManagerSidebar extends StatelessWidget {
  final String currentRoute;
  final String managerName;
  final String avatarUrl;
  final ValueChanged<String> onRouteSelected;
  final VoidCallback? onLogout;

  // Khởi tạo ManagerSidebar: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho web bố cục.
  const ManagerSidebar({
    super.key,
    required this.currentRoute,
    required this.managerName,
    required this.avatarUrl,
    required this.onRouteSelected,
    this.onLogout,
  });

  static const List<_ManagerMenuItem> _menuItems = [
    _ManagerMenuItem(
      title: 'Tổng quan',
      routeName: AppRoutes.managerHome,
      icon: Icons.dashboard_rounded,
    ),
    _ManagerMenuItem(
      title: 'Sản phẩm',
      routeName: AppRoutes.managerProducts,
      icon: Icons.fastfood_rounded,
    ),
    _ManagerMenuItem(
      title: 'Danh mục',
      routeName: AppRoutes.managerCategories,
      icon: Icons.category_rounded,
    ),
    _ManagerMenuItem(
      title: 'Đơn hàng',
      routeName: AppRoutes.managerOrders,
      icon: Icons.receipt_long_rounded,
    ),
    _ManagerMenuItem(
      title: 'Doanh thu',
      routeName: AppRoutes.managerRevenue,
      icon: Icons.bar_chart_rounded,
    ),
    _ManagerMenuItem(
      title: 'Tin nhắn',
      routeName: AppRoutes.managerChat,
      icon: Icons.forum_rounded,
    ),
    _ManagerMenuItem(
      title: 'Thông báo',
      routeName: AppRoutes.managerNotifications,
      icon: Icons.notifications_rounded,
    ),
  ];

  // Xây dựng giao diện (build): dựng cây widget của ManagerSidebar từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6675), AppColors.primary, Color(0xFFD91F2D)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YourFood',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Manager Web',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.white24, height: 1),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _menuItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final selected = item.routeName == currentRoute;

                  return _SidebarTile(
                    item: item,
                    selected: selected,
                    onTap: () {
                      onRouteSelected(item.routeName);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      children: [
                        _AvatarButton(
                          avatarUrl: avatarUrl,
                          size: 40,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                managerName.trim().isEmpty
                                    ? 'Manager'
                                    : managerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Quản lý hệ thống',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onLogout != null) ...[
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLogout,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Lớp _SidebarTile: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _SidebarTile extends StatelessWidget {
  final _ManagerMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  // Khởi tạo _SidebarTile: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho web bố cục.
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  // Xây dựng giao diện (build): dựng cây widget của _SidebarTile từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 21,
                color: selected ? AppColors.primary : Colors.white70,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: selected ? AppColors.primary : Colors.white,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lớp _AvatarButton: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _AvatarButton extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final VoidCallback onTap;

  // Khởi tạo _AvatarButton: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho web bố cục.
  const _AvatarButton({
    required this.avatarUrl,
    required this.size,
    required this.onTap,
  });

  // Xây dựng giao diện (build): dựng cây widget của _AvatarButton từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(size / 3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child:
              avatarUrl.trim().isEmpty
                  ? const Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                  )
                  : Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                      );
                    },
                  ),
        ),
      ),
    );
  }
}

// Lớp _ManagerMenuItem: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _ManagerMenuItem {
  final String title;
  final String routeName;
  final IconData icon;

  // Khởi tạo _ManagerMenuItem: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho web bố cục.
  const _ManagerMenuItem({
    required this.title,
    required this.routeName,
    required this.icon,
  });
}
