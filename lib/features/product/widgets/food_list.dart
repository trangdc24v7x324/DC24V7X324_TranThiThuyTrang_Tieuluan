// FILE HỌC TẬP: lib/features/product/widgets/food_list.dart
// Vai trò: Widget sản phẩm cho món ăn danh sách.
// Luồng sử dụng: Tách giao diện sản phẩm thành thành phần tái sử dụng và nhận dữ liệu từ màn hình cha.

import 'package:project_trangdc24v7x324/features/product/widgets/food_card.dart';
import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Lớp FoodAvailable: thành phần phục vụ widget sản phẩm cho món ăn danh sách.
class FoodAvailable extends StatelessWidget {
  static const double _cardHeight = 240;

  final List<ProductModel> favoritedItems;
  final void Function(ProductModel) onFavoriteToggle;
  final String searchQuery;
  final String selectedCategory;


  // Khởi tạo FoodAvailable: nhận các tham số cần thiết để tạo đối tượng cho widget sản phẩm cho món ăn danh sách.
  const FoodAvailable({
    super.key,
    required this.favoritedItems,
    required this.onFavoriteToggle,
    required this.searchQuery,
    required this.selectedCategory,
  });

  // Kiểm tra điều kiện (isFavorited): đánh giá trạng thái favorited và trả kết quả cho lớp gọi.
  bool isFavorited(ProductModel product) {
    return favoritedItems.any((item) => item.id == product.id);
  }

  // Lấy cross axis số lượng (_getCrossAxisCount): truy xuất và trả kết quả cho lớp gọi.
  int _getCrossAxisCount(double width, int itemCount) {
    if (itemCount == 1) return 1;
    if (width >= 900) return 4;
    if (width >= 650) return 3;
    return 2;
  }

  // Xây dựng giao diện (build): dựng cây widget của FoodAvailable từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final query = searchQuery.toLowerCase().trim();

    if (productProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productProvider.errorMessage != null) {
      return Center(
        child: Text(
          productProvider.errorMessage!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.redAccent,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final filteredItems =
        productProvider.products.where((item) {
          final title = item.title.toLowerCase();
          final subtitle = item.subtitle.toLowerCase();
          final description = item.description.toLowerCase();

          final matchesSearch =
              query.isEmpty ||
              title.contains(query) ||
              subtitle.contains(query) ||
              description.contains(query);

          final bool matchesCategory;

          if (selectedCategory == 'promotion_today') {
            matchesCategory = item.hasActiveSale;
          } else if (selectedCategory == 'all') {
            matchesCategory = true;
          } else {
            matchesCategory = item.categorySlug == selectedCategory;
          }

          return item.isAvailable && matchesSearch && matchesCategory;
        }).toList();

    if (filteredItems.isEmpty) {
      final emptyMessage =
          selectedCategory == 'promotion_today' && query.isEmpty
              ? 'Hôm nay chưa có sản phẩm khuyến mãi'
              : 'Không tìm thấy món ăn';

      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _getCrossAxisCount(width, filteredItems.length);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 14),
          itemCount: filteredItems.length,
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: _cardHeight,
          ),
          itemBuilder: (context, index) {
            final item = filteredItems[index];

            final ratingStats = productProvider.ratingStatsForProduct(item.id);

            return FoodCard(
              product: item,
              isFavorited: isFavorited(item),
              rating: ratingStats.average,
              reviewCount: ratingStats.count,
              onFavoriteToggle: () => onFavoriteToggle(item),
              onAddToCart: () {
                final cart = context.read<CartProvider>();

                cart.addItem(CartItemModel.fromProduct(item, quantity: 1));

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.title} đã thêm vào giỏ hàng'),
                    duration: const Duration(milliseconds: 900),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
