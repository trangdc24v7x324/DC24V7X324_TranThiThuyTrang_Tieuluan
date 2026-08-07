import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ManagerHomePage extends StatefulWidget {
  const ManagerHomePage({super.key});

  @override
  State<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final managerId = pb.authStore.model?.id ?? '';

    // Không để một API lỗi làm toàn bộ ManagerHome bị crash trên Flutter Web.
    try {
      await context.read<OrderProvider>().loadAllOrders();
    } catch (e, st) {
      debugPrint('MANAGER HOME - ORDER ERROR: $e');
      debugPrintStack(stackTrace: st);
    }

    if (!mounted) return;

    try {
      await context.read<ProfileProvider>().loadProfile(forceReload: true);
    } catch (e, st) {
      debugPrint('MANAGER HOME - PROFILE ERROR: $e');
      debugPrintStack(stackTrace: st);
    }

    if (!mounted || managerId.isEmpty) return;

    try {
      await context.read<ChatProvider>().loadManagerChatSummary(
        managerId: managerId,
      );
    } catch (e, st) {
      debugPrint('MANAGER HOME - CHAT ERROR: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final chat = context.watch<ChatProvider>();
    final profile = context.watch<ProfileProvider>();

    final avatarUrl = profile.profile?.avatarUrl ?? '';

    return Scaffold(
      backgroundColor: const Color(0xffFF8A95),
      bottomNavigationBar: const _BottomRedDecor(),
      body: Column(
        children: [
          _HeaderSection(avatarUrl: avatarUrl),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _DashboardGrid(
                      pending: order.pendingOrderCount,
                      completed: order.completedOrderCount,
                      unread: chat.unreadCount,
                      totalRooms: chat.totalRooms,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Chức năng quản lý',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.category,
                      title: 'Danh mục',
                      subtitle: 'Quản lý danh mục sản phẩm',
                      color: Colors.orange,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.managerCategories,
                        );
                        if (mounted) await _loadData();
                      },
                    ),
                    _ActionCard(
                      icon: Icons.fastfood,
                      title: 'Sản phẩm',
                      subtitle: 'Quản lý sản phẩm',
                      color: Colors.red,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.managerProducts,
                        );
                        if (mounted) await _loadData();
                      },
                    ),
                    _ActionCard(
                      icon: Icons.receipt_long,
                      title: 'Đơn hàng',
                      subtitle: 'Quản lý đơn hàng',
                      badge: order.pendingOrderCount,
                      color: Colors.blue,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.managerOrders,
                        );
                        if (mounted) await _loadData();
                      },
                    ),
                    _ActionCard(
                      icon: Icons.bar_chart,
                      title: 'Doanh thu',
                      subtitle: 'Thống kê doanh thu',
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.managerRevenue,
                        );
                        if (mounted) await _loadData();
                      },
                    ),
                    _ActionCard(
                      icon: Icons.chat_bubble,
                      title: 'Chat khách hàng',
                      subtitle:
                          chat.totalRooms > 0
                              ? '${chat.totalRooms} cuộc trò chuyện'
                              : 'Chưa có cuộc trò chuyện',
                      badge: chat.unreadCount,
                      color: Colors.purple,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.managerChat,
                        );
                        if (mounted) await _loadData();
                      },
                    ),
                    _ActionCard(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: 'Gửi thông báo',
                      color: Colors.teal,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.managerNotifications,
                        );
                        if (mounted) await _loadData();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String avatarUrl;

  const _HeaderSection({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 380;

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffFF8A95), Color(0xffFF3D4F), Color(0xffD91F2D)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          isSmall ? 16 : 18,
          12,
          isSmall ? 16 : 18,
          18,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YourFood',
                    style: GoogleFonts.lobster(
                      fontSize: isSmall ? 28 : 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bảng điều khiển quản lý',
                    style: TextStyle(
                      fontSize: isSmall ? 13 : 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              child: Container(
                width: isSmall ? 44 : 48,
                height: isSmall ? 44 : 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      avatarUrl.isNotEmpty
                          ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                          )
                          : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final int pending;
  final int completed;
  final int unread;
  final int totalRooms;

  const _DashboardGrid({
    required this.pending,
    required this.completed,
    required this.unread,
    required this.totalRooms,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _DashboardItem(
        title: 'Đơn xử lý',
        value: pending,
        color: Colors.orange,
        icon: Icons.pending_actions,
      ),
      _DashboardItem(
        title: 'Hoàn thành',
        value: completed,
        color: Colors.green,
        icon: Icons.check_circle,
      ),
      _DashboardItem(
        title: 'Tin chưa đọc',
        value: unread,
        color: Colors.blue,
        icon: Icons.mark_chat_unread,
      ),
      _DashboardItem(
        title: 'Cuộc chat',
        value: totalRooms,
        color: Colors.purple,
        icon: Icons.chat,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          items.map((item) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 44) / 2,
              child: item,
            );
          }).toList(),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const _DashboardItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (badge > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF2A39),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$badge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomRedDecor extends StatelessWidget {
  const _BottomRedDecor();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0, color: const Color(0xFFEF2A39));
  }
}
