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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

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

class _HomePageState extends State<HomePage> {
  final List<ProductModel> favoritedItems = [];
  String searchQuery = '';
  String selectedCategory = 'all';
  int selectedIndex = 0;

  /// Mỗi lần kéo làm mới Home, tăng version để FoodCard
  /// đọc lại số sao và số đánh giá thật từ product_reviews.
  int _ratingRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initData);
  }

  Future<void> _initData() async {
    final productProvider = context.read<ProductProvider>();

    if (!productProvider.isLoading) {
      await productProvider.loadInitialData();
    }

    if (!mounted) return;

    // Khôi phục giỏ hàng active từ PocketBase sau khi user vào Home.
    await context.read<CartProvider>().loadCart();

    if (!mounted) return;
    await context.read<ProfileProvider>().loadProfile();

    if (!mounted) return;
    final userId = pb.authStore.model?.id ?? '';

    await context.read<ChatProvider>().loadCustomerChatSummary(
      customerId: userId,
    );

    try {
      await context.read<NotificationProvider>().loadCustomerNotifications();
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<ProductProvider>().loadCategories(),
      context.read<ProductProvider>().loadProducts(),
      context.read<CartProvider>().refreshCart(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
    ]);

    final userId = pb.authStore.model?.id ?? '';

    await context.read<ChatProvider>().loadCustomerChatSummary(
      customerId: userId,
    );

    try {
      await context.read<NotificationProvider>().loadCustomerNotifications();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _ratingRefreshVersion++;
    });
  }

  void toggleFavorite(ProductModel item) {
    setState(() {
      final exists = favoritedItems.any((product) => product.id == item.id);
      exists
          ? favoritedItems.removeWhere((product) => product.id == item.id)
          : favoritedItems.add(item);
    });
  }

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
                          ratingRefreshVersion: _ratingRefreshVersion,
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

class _BodyContainer extends StatelessWidget {
  final Widget child;

  const _BodyContainer({required this.child});

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

class _ProductContent extends StatelessWidget {
  final ProductProvider provider;
  final List<ProductModel> favoritedItems;
  final String searchQuery;
  final String selectedCategory;
  final int ratingRefreshVersion;
  final ValueChanged<ProductModel> onFavoriteToggle;

  const _ProductContent({
    required this.provider,
    required this.favoritedItems,
    required this.searchQuery,
    required this.selectedCategory,
    required this.ratingRefreshVersion,
    required this.onFavoriteToggle,
  });

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
      ratingRefreshVersion: ratingRefreshVersion,
    );
  }
}

class _CurvedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Future<void> Function(int index) onTap;
  final List<int> counts;

  const _CurvedBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.counts,
  });

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

class _BottomSoftCurveClipper extends CustomClipper<Path> {
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

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeaderSection extends StatelessWidget {
  final String? avatarUrl;

  const _HeaderSection({required this.avatarUrl});

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

class _HeaderTitle extends StatelessWidget {
  final bool isSmall;

  const _HeaderTitle({required this.isSmall});

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
              color: Colors.white.withOpacity(0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final VoidCallback onTap;

  const _AvatarButton({
    required this.avatarUrl,
    required this.size,
    required this.onTap,
  });

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

class _PersonIcon extends StatelessWidget {
  const _PersonIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person_outline, color: Colors.grey);
  }
}

class _SearchAndFavoriteSection extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final List<ProductModel> favoritedItems;

  const _SearchAndFavoriteSection({
    required this.onSearchChanged,
    required this.favoritedItems,
  });

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

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.onChanged});

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

class _FavoriteButton extends StatelessWidget {
  final List<ProductModel> favoritedItems;

  const _FavoriteButton({required this.favoritedItems});

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
        color: shadowColor.withOpacity(shadowOpacity),
        blurRadius: blurRadius,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
