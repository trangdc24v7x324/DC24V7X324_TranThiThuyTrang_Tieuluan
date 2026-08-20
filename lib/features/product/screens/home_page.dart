// FILE HỌC TẬP: lib/features/product/screens/home_page.dart
// Vai trò: Màn hình trang chủ.
// Luồng sử dụng: Phục vụ luồng mua hàng: xem món, giỏ hàng, đặt đơn, thanh toán hoặc theo dõi đơn.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/product/widgets/food_list.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/providers/notification_provider.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/widgets/category_selector.dart';
import 'package:project_trangdc24v7x324/shared/widgets/nav_icon.dart';

// Lớp HomePage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class HomePage extends StatefulWidget {
  // Khởi tạo HomePage: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const HomePage({super.key});

  // Tạo state (createState): liên kết HomePage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<HomePage> createState() => _HomePageState();
}

// Lớp AppColors: thành phần phục vụ màn hình trang chủ.
class AppColors {
  static const pink = Color(0xffFF939B);
  static const red = Color(0xffEF2A39);

  static const bg = Color(0xFFF7F7F7);

  // Gradient giống splash
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xffFF8A95), // hồng sáng
      Color(0xffFF3D4F), // đỏ tươi
      Color(0xffD91F2D), // đỏ đậm
    ],
    stops: [0.0, 0.45, 1.0],
  );
}

// Lớp _HomePageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _HomePageState extends State<HomePage> {
  final List<ProductModel> favoritedItems = [];
  String searchQuery = '';
  String selectedCategory = 'all';
  int selectedIndex = 0;


  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    Future.microtask(_initData);
  }

  // Tải dữ liệu trang chủ: chạy các nguồn độc lập song song để giảm thời gian chờ.
  // Xử lý _initData: thực hiện phần nghiệp vụ tương ứng trong màn hình trang chủ.
  Future<void> _initData() async {
    final userId = pb.authStore.model?.id ?? '';

    await Future.wait([
      context.read<ProductProvider>().loadInitialData(),
      context.read<CartProvider>().loadCart(),
      context.read<ProfileProvider>().loadProfile(),
      if (userId.isNotEmpty)
        context.read<ChatProvider>().loadCustomerChatSummary(
          customerId: userId,
        ),
      _loadCustomerNotificationsSafely(),
    ]);
  }

  // Làm mới trang chủ: đồng bộ các dữ liệu chính một lượt, không tách category/product thành hai loading song song.
  // Làm mới dữ liệu (_refreshData): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<void> _refreshData() async {
    final userId = pb.authStore.model?.id ?? '';

    await Future.wait([
      context.read<ProductProvider>().loadInitialData(),
      context.read<CartProvider>().refreshCart(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
      if (userId.isNotEmpty)
        context.read<ChatProvider>().loadCustomerChatSummary(
          customerId: userId,
        ),
      _loadCustomerNotificationsSafely(),
    ]);
  }

  // Tải thông báo: lỗi notification không được chặn việc mở hoặc làm mới Home.
  // Tải khách hàng thông báo an toàn (_loadCustomerNotificationsSafely): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> _loadCustomerNotificationsSafely() async {
    try {
      await context.read<NotificationProvider>().loadCustomerNotifications();
    } catch (error) {
      debugPrint('Load customer notifications error: $error');
    }
  }

  // Bật/tắt yêu thích (toggleFavorite): đảo trạng thái hiện tại theo thao tác người dùng.
  void toggleFavorite(ProductModel item) {
    setState(() {
      final exists = favoritedItems.any((product) => product.id == item.id);
      exists
          ? favoritedItems.removeWhere((product) => product.id == item.id)
          : favoritedItems.add(item);
    });
  }

  // Xử lý tap (_handleTap): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
  Future<void> _handleTap(int index) async {
    setState(() => selectedIndex = index);

    if (index == 1) {
      await Navigator.pushNamed(context, AppRoutes.cart);

      if (!mounted) return;

      try {
        await context.read<NotificationProvider>().loadCustomerNotifications();
      } catch (e) {
        debugPrint('Reload notification after cart error: $e');
      }
    } else if (index == 2) {
      await _openChat();

      if (!mounted) return;

      final customerId = pb.authStore.model?.id ?? '';

      if (customerId.isNotEmpty) {
        await context.read<ChatProvider>().loadCustomerChatSummary(
          customerId: customerId,
        );
      }
    } else if (index == 3) {
      await Navigator.pushNamed(context, AppRoutes.notifications);

      if (!mounted) return;

      // Chỉ load lại sau khi quay về, KHÔNG tự markAllAsRead ở đây.
      try {
        await context.read<NotificationProvider>().loadCustomerNotifications();
      } catch (e) {
        debugPrint('Reload notification after notification page error: $e');
      }
    }

    if (mounted) setState(() => selectedIndex = 0);
  }

  // Mở trò chuyện (_openChat): điều hướng hoặc hiển thị thành phần tương ứng từ thao tác người dùng.
  Future<void> _openChat() async {
    final chatProvider = context.read<ChatProvider>();

    try {
      final managerId = await chatProvider.getManagerId();

      if (!mounted) return;

      if (managerId == null || managerId.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hiện chưa tìm thấy tài khoản quản lý để trò chuyện.',
            ),
          ),
        );
        return;
      }

      await Navigator.pushNamed(
        context,
        AppRoutes.managerChatDetail,
        arguments: {
          'otherUserId': managerId.trim(),
          'otherUserName': 'Hỗ trợ YourFood',
        },
      );

      if (!mounted) return;

      final customerId = pb.authStore.model?.id ?? '';

      if (customerId.isNotEmpty) {
        await chatProvider.loadCustomerChatSummary(customerId: customerId);
      }
    } catch (e) {
      debugPrint('openChat error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chatProvider.errorMessage ??
                'Không thể mở cuộc trò chuyện. Vui lòng thử lại.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Xây dựng giao diện (build): dựng cây widget của _HomePageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final avatarUrl = context.watch<ProfileProvider>().profile?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.pink,
      bottomNavigationBar: _CurvedBottomNavBar(
        selectedIndex: selectedIndex,
        onTap: _handleTap,
        counts: [
          0,
          cart.items.fold<int>(0, (sum, item) => sum + item.quantity),
          context.watch<ChatProvider>().unreadCount,
          context.watch<NotificationProvider>().unreadCount,
        ],
      ),
      body: Column(
        children: [
          _HeaderSection(avatarUrl: avatarUrl),
          Expanded(
            child: _BodyContainer(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      _SearchAndFavoriteSection(
                        favoritedItems: favoritedItems,
                        onSearchChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                      ),

                      const SizedBox(height: 18),

                      CategorySelector(
                        categories: productProvider.categories,
                        selectedCategory: selectedCategory,
                        showPromotion: true,
                        onCategorySelected: (value) {
                          setState(() => selectedCategory = value);
                        },
                      ),

                      const SizedBox(height: 14),

                      Expanded(
                        child: _ProductContent(
                          provider: productProvider,
                          favoritedItems: favoritedItems,
                          searchQuery: searchQuery,
                          selectedCategory: selectedCategory,
                          onFavoriteToggle: toggleFavorite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _BodyContainer: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _BodyContainer extends StatelessWidget {
  final Widget child;

  // Khởi tạo _BodyContainer: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _BodyContainer({required this.child});

  // Xây dựng giao diện (build): dựng cây widget của _BodyContainer từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: child,
    );
  }
}

// Lớp _ProductContent: thành phần phục vụ màn hình trang chủ.
class _ProductContent extends StatelessWidget {
  final ProductProvider provider;
  final List<ProductModel> favoritedItems;
  final String searchQuery;
  final String selectedCategory;
  final ValueChanged<ProductModel> onFavoriteToggle;

  // Khởi tạo _ProductContent: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _ProductContent({
    required this.provider,
    required this.favoritedItems,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onFavoriteToggle,
  });

  // Xây dựng giao diện (build): dựng cây widget của _ProductContent từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    return FoodAvailable(
      favoritedItems: favoritedItems,
      onFavoriteToggle: onFavoriteToggle,
      searchQuery: searchQuery,
      selectedCategory: selectedCategory,
    );
  }
}

// Lớp _CurvedBottomNavBar: thành phần phục vụ màn hình trang chủ.
class _CurvedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Future<void> Function(int index) onTap;
  final List<int> counts;

  // Khởi tạo _CurvedBottomNavBar: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _CurvedBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.counts,
  });

  // Xây dựng giao diện (build): dựng cây widget của _CurvedBottomNavBar từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: _BottomSoftCurveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xffFF3D4F), // đỏ tươi
                      Color(0xffD91F2D), // đỏ đậm
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    return NavIcon(
                      index: index,
                      selectedIndex: selectedIndex,
                      onTap: onTap,
                      badgeCount: counts[index],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _BottomSoftCurveClipper: thành phần phục vụ màn hình trang chủ.
class _BottomSoftCurveClipper extends CustomClipper<Path> {
  // Lấy clip (getClip): truy xuất và trả kết quả cho lớp gọi.
  @override
  Path getClip(Size size) {
    const curveHeight = 18.0;
    const curveWidth = 24.0;

    return Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(0, curveHeight, curveWidth, curveHeight)
      ..lineTo(size.width - curveWidth, curveHeight)
      ..quadraticBezierTo(size.width, curveHeight, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  // Xử lý shouldReclip: thực hiện phần nghiệp vụ tương ứng trong màn hình trang chủ.
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Lớp _HeaderSection: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _HeaderSection extends StatelessWidget {
  final String? avatarUrl;

  // Khởi tạo _HeaderSection: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _HeaderSection({required this.avatarUrl});

  // Xây dựng giao diện (build): dựng cây widget của _HeaderSection từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 380;

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        padding: EdgeInsets.fromLTRB(
          isSmall ? 16 : 18,
          12,
          isSmall ? 16 : 18,
          18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Row(
              children: [
                Expanded(child: _HeaderTitle(isSmall: isSmall)),
                const SizedBox(width: 14),
                _AvatarButton(
                  avatarUrl: avatarUrl,
                  size: isSmall ? 44 : 48,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Lớp _HeaderTitle: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _HeaderTitle extends StatelessWidget {
  final bool isSmall;

  // Khởi tạo _HeaderTitle: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _HeaderTitle({required this.isSmall});

  // Xây dựng giao diện (build): dựng cây widget của _HeaderTitle từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
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
            'Ăn uống theo cách của bạn!',
            style: TextStyle(
              fontSize: isSmall ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _AvatarButton: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _AvatarButton extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final VoidCallback onTap;

  // Khởi tạo _AvatarButton: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _AvatarButton({
    required this.avatarUrl,
    required this.size,
    required this.onTap,
  });

  // Xây dựng giao diện (build): dựng cây widget của _AvatarButton từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final radius = size / 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: _boxDecoration(
          radius: radius,
          color: Colors.white,
          borderColor: Colors.white,
          shadowOpacity: 0.18,
          blurRadius: 10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 2),
          child:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PersonIcon(),
                  )
                  : const _PersonIcon(),
        ),
      ),
    );
  }
}

// Lớp _PersonIcon: thành phần phục vụ màn hình trang chủ.
class _PersonIcon extends StatelessWidget {
  // Khởi tạo _PersonIcon: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _PersonIcon();

  // Xây dựng giao diện (build): dựng cây widget của _PersonIcon từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_outline, color: Colors.grey);
  }
}

// Lớp _SearchAndFavoriteSection: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _SearchAndFavoriteSection extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final List<ProductModel> favoritedItems;

  // Khởi tạo _SearchAndFavoriteSection: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _SearchAndFavoriteSection({
    required this.onSearchChanged,
    required this.favoritedItems,
  });

  // Xây dựng giao diện (build): dựng cây widget của _SearchAndFavoriteSection từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SearchBox(onChanged: onSearchChanged)),
        const SizedBox(width: 10),
        _FavoriteButton(favoritedItems: favoritedItems),
      ],
    );
  }
}

// Lớp _SearchBox: thành phần phục vụ màn hình trang chủ.
class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  // Khởi tạo _SearchBox: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _SearchBox({required this.onChanged});

  // Xây dựng giao diện (build): dựng cây widget của _SearchBox từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: _boxDecoration(
        radius: 14,
        color: Colors.white,
        shadowOpacity: 0.06,
        blurRadius: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tìm món ăn...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Lớp _FavoriteButton: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _FavoriteButton extends StatelessWidget {
  final List<ProductModel> favoritedItems;

  // Khởi tạo _FavoriteButton: nhận các tham số cần thiết để tạo đối tượng cho màn hình trang chủ.
  const _FavoriteButton({required this.favoritedItems});

  // Xây dựng giao diện (build): dựng cây widget của _FavoriteButton từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: _boxDecoration(
        radius: 14,
        color: const Color.fromARGB(255, 228, 3, 3),
        shadowColor: const Color.fromARGB(255, 75, 6, 27),
        shadowOpacity: 0.22,
        blurRadius: 10,
      ),
      child: IconButton(
        icon: const Icon(Icons.favorite_border, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.favourite,
            arguments: favoritedItems,
          );
        },
      ),
    );
  }
}

// Xử lý _boxDecoration: thực hiện phần nghiệp vụ tương ứng trong màn hình trang chủ.
BoxDecoration _boxDecoration({
  required double radius,
  required Color color,
  Color? borderColor,
  Color shadowColor = Colors.black,
  double shadowOpacity = 0.08,
  double blurRadius = 8,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border:
        borderColor == null ? null : Border.all(color: borderColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withValues(alpha: shadowOpacity),
        blurRadius: blurRadius,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
