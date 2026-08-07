import 'package:CT466_project_trangdc24v7x324/features/product/widgets/food_card.dart';
import 'package:CT466_project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/product_model.dart';
import 'package:CT466_project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:CT466_project_trangdc24v7x324/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FoodAvailable extends StatelessWidget {
  static const double _cardHeight = 240;

  final List<ProductModel> favoritedItems;
  final void Function(ProductModel) onFavoriteToggle;
  final String searchQuery;
  final String selectedCategory;

  const FoodAvailable({
    super.key,
    required this.favoritedItems,
    required this.onFavoriteToggle,
    required this.searchQuery,
    required this.selectedCategory,
  });

  bool isFavorited(ProductModel product) {
    return favoritedItems.any((item) => item.id == product.id);
  }

  int _getCrossAxisCount(double width, int itemCount) {
    if (itemCount == 1) return 1;
    if (width >= 900) return 4;
    if (width >= 650) return 3;
    return 2;
  }

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

          final matchesCategory =
              selectedCategory == 'all' ||
              item.categorySlug == selectedCategory;

          return item.isAvailable && matchesSearch && matchesCategory;
        }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy món ăn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
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

            return FoodCard(
              product: item,
              isFavorited: isFavorited(item),
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
