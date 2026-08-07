import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';

class FoodCard extends StatefulWidget {
  final ProductModel product;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;

  const FoodCard({
    super.key,
    required this.product,
    required this.isFavorited,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool _isCartAnimating = false;

  // =========================================================
  // ADD TO CART
  // =========================================================

  Future<void> _handleAddToCart() async {
    if (!widget.product.isAvailable) {
      return;
    }

    setState(() {
      _isCartAnimating = true;
    });

    widget.onAddToCart();

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    setState(() {
      _isCartAnimating = false;
    });
  }

  // =========================================================
  // FORMAT PRICE
  // =========================================================

  String formatPrice(double price) {
    final String value = price.round().toString();

    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);

      final int remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  // =========================================================
  // IMAGE
  // =========================================================

  Widget _buildImage() {
    if (widget.product.image.isEmpty) {
      return const Icon(Icons.fastfood_rounded, size: 44, color: Colors.grey);
    }

    final bool isNetwork =
        widget.product.image.startsWith('http://') ||
        widget.product.image.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        widget.product.image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.fastfood_rounded,
            size: 44,
            color: Colors.grey,
          );
        },
      );
    }

    return Image.asset(
      widget.product.image,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.fastfood_rounded, size: 44, color: Colors.grey);
      },
    );
  }

  // =========================================================
  // IMAGE AREA + SALE BADGE
  // =========================================================

  Widget _buildProductImage() {
    return SizedBox(
      height: 95,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildImage(),
              ),
            ),
          ),

          // ===============================================
          // SALE BADGE
          // ===============================================
          if (widget.product.hasActiveSale)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF2A39),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${widget.product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // ===============================================
          // OUT OF STOCK
          // ===============================================
          if (!widget.product.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.60),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Hết hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // PRICE
  // =========================================================

  Widget _buildPrice() {
    // Không có khuyến mãi.
    if (!widget.product.hasActiveSale) {
      return Text(
        formatPrice(widget.product.price),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFFEF2A39),
        ),
      );
    }

    // Có khuyến mãi.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Giá gốc.
        Text(
          formatPrice(widget.product.price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 1),

        // Giá thực tế.
        Text(
          formatPrice(widget.product.effectivePrice),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFFEF2A39),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.product,
            arguments: widget.product,
          );
        },

        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============================================
              // IMAGE
              // =============================================
              _buildProductImage(),

              const SizedBox(height: 8),

              // =============================================
              // TITLE
              // =============================================
              Text(
                widget.product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E2E2E),
                ),
              ),

              const SizedBox(height: 3),

              // =============================================
              // SUBTITLE
              // =============================================
              Text(
                widget.product.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 8),

              // =============================================
              // PRICE
              // =============================================
              _buildPrice(),

              const SizedBox(height: 7),

              // =============================================
              // RATING + ACTION
              // =============================================
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.orange,
                    size: 15,
                  ),

                  const SizedBox(width: 3),

                  Text(
                    widget.product.reviewCount > 0
                        ? '${widget.product.rating.toStringAsFixed(1)} '
                            '(${widget.product.reviewCount})'
                        : 'Chưa có',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const Spacer(),

                  // =========================================
                  // CART
                  // =========================================
                  _ActionIcon(
                    icon: CupertinoIcons.cart_badge_plus,
                    color:
                        widget.product.isAvailable
                            ? const Color(0xFFEF2A39)
                            : Colors.grey,
                    onTap: _handleAddToCart,
                    isAnimating: _isCartAnimating,
                  ),

                  const SizedBox(width: 8),

                  // =========================================
                  // FAVORITE
                  // =========================================
                  _ActionIcon(
                    icon:
                        widget.isFavorited
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                    color:
                        widget.isFavorited
                            ? const Color(0xFFEF2A39)
                            : Colors.grey,
                    onTap: widget.onFavoriteToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// ACTION ICON
// ===========================================================

class _ActionIcon extends StatelessWidget {
  final IconData icon;

  final Color color;

  final VoidCallback onTap;

  final bool isAnimating;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isAnimating ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
