import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:project_trangdc24v7x324/features/product/widgets/food_card.dart';

import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites =
        (ModalRoute.of(context)?.settings.arguments as List<ProductModel>?) ??
        [];

    return AppLayout(
      title: 'Yêu thích',
      showBack: true,
      child: AppBody(
        child:
            favorites.isEmpty
                ? const _EmptyFavourite()
                : _FavouriteGrid(favorites: favorites),
      ),
    );
  }
}

class _EmptyFavourite extends StatelessWidget {
  const _EmptyFavourite();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Chưa có món yêu thích nào!',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.textGrey),
        ),
      ),
    );
  }
}

class _FavouriteGrid extends StatelessWidget {
  final List<ProductModel> favorites;

  const _FavouriteGrid({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 500 ? 2 : 3;

        final ratio =
            width < 380
                ? 0.75
                : width < 500
                ? 0.72
                : 0.80;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
          itemCount: favorites.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: favorites.length == 1 ? 1 : crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: favorites.length == 1 ? 0.9 : ratio,
          ),
          itemBuilder: (context, index) {
            final item = favorites[index];

            return FoodCard(
              product: item,
              isFavorited: true,
              onFavoriteToggle: () {},
              onAddToCart: () {
                final cart = context.read<CartProvider>();

                cart.addItem(
                  CartItemModel(
                    productId: item.id,
                    title: item.title,
                    image: item.image,
                    price: item.price,
                    quantity: 1,
                    categoryId: item.categoryId,
                    categoryTitle: item.categoryTitle,
                    categorySlug: item.categorySlug,
                  ),
                );

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
