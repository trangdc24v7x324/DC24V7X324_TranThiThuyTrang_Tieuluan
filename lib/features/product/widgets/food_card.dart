import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';

class FoodCard extends StatefulWidget {
  final ProductModel product;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;

  /// Tăng giá trị này khi màn hình cha muốn ép tải lại rating thật.
  final int ratingRefreshVersion;

  const FoodCard({
    super.key,
    required this.product,
    required this.isFavorited,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    this.ratingRefreshVersion = 0,
  });

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool _isCartAnimating = false;

  double _realRating = 0;
  int _realReviewCount = 0;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRealReviewStats);
  }

  @override
  void didUpdateWidget(covariant FoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.product.id != widget.product.id ||
        oldWidget.ratingRefreshVersion != widget.ratingRefreshVersion) {
      Future.microtask(_loadRealReviewStats);
    }
  }

  Future<void> _loadRealReviewStats() async {
    final productId = widget.product.id.trim();

    if (mounted) {
      setState(() {
        _isLoadingRating = true;
      });
    }

    if (productId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _realRating = 0;
        _realReviewCount = 0;
        _isLoadingRating = false;
      });
      return;
    }

    try {
      List<dynamic> records;

      try {
        records = await pb
            .collection('product_reviews')
            .getFullList(filter: 'product = "$productId"', sort: '-created');
      } catch (_) {
        records = await pb
            .collection('product_reviews')
            .getFullList(filter: 'productId = "$productId"', sort: '-created');
      }

      double total = 0;
      int validCount = 0;

      for (final record in records) {
        final raw = record.data['rating'];

        final double rating;
        if (raw is num) {
          rating = raw.toDouble();
        } else {
          rating = double.tryParse(raw?.toString() ?? '') ?? 0;
        }

        if (rating >= 1 && rating <= 5) {
          total += rating;
          validCount++;
        }
      }

      final average = validCount == 0 ? 0.0 : total / validCount;

      if (!mounted || widget.product.id.trim() != productId) return;

      setState(() {
        _realRating = average;
        _realReviewCount = validCount;
        _isLoadingRating = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD FOOD CARD REVIEW STATS ERROR '
        'product=${widget.product.id}: $e',
      );

      if (!mounted) return;

      // Không fallback về product.rating/reviewCount vì dữ liệu sản phẩm cũ
      // có thể chưa có reviewCount và gây lỗi Null -> int trên Flutter Web.
      setState(() {
        _realRating = 0;
        _realReviewCount = 0;
        _isLoadingRating = false;
      });
    }
  }

  bool get _hasActiveSale {
    final product = widget.product;

    if (!product.isOnSale) return false;

    if (product.price <= 0 ||
        product.salePrice <= 0 ||
        product.salePrice >= product.price) {
      return false;
    }

    final now = DateTime.now();
    final start = product.saleStartAt?.toLocal();
    final end = product.saleEndAt?.toLocal();

    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;

    return true;
  }

  int get _discountPercent {
    if (!_hasActiveSale || widget.product.price <= 0) return 0;

    return (((widget.product.price - widget.product.salePrice) /
                widget.product.price) *
            100)
        .round();
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isCartAnimating = true);

    widget.onAddToCart();

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;
    setState(() => _isCartAnimating = false);
  }

  String formatPrice(double price) {
    final value = price.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      final remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  Widget _buildImage() {
    if (widget.product.image.isEmpty) {
      return const Icon(Icons.fastfood_rounded, size: 44, color: Colors.grey);
    }

    final isNetwork =
        widget.product.image.startsWith('http://') ||
        widget.product.image.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        widget.product.image,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
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
      errorBuilder: (_, __, ___) {
        return const Icon(Icons.fastfood_rounded, size: 44, color: Colors.grey);
      },
    );
  }

  Widget _buildPrice() {
    if (!_hasActiveSale) {
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

    return Row(
      children: [
        Flexible(
          child: Text(
            formatPrice(widget.product.salePrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEF2A39),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            formatPrice(widget.product.price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        if (_discountPercent > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF2A39).withOpacity(0.10),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '-$_discountPercent%',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEF2A39),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.product,
            arguments: widget.product,
          );

          if (!mounted) return;

          // Customer có thể vừa thêm/sửa/xóa đánh giá ở ProductPage.
          // Tải lại trực tiếp từ product_reviews khi quay về Home.
          await _loadRealReviewStats();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 95,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildImage(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
              _buildPrice(),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    _realReviewCount > 0
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color:
                        _realReviewCount > 0
                            ? Colors.orange
                            : Colors.grey.shade400,
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  if (_isLoadingRating)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.grey.shade400,
                      ),
                    )
                  else
                    Text(
                      _realReviewCount > 0
                          ? '${_realRating.toStringAsFixed(1)} '
                              '($_realReviewCount đánh giá)'
                          : 'Chưa có đánh giá',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF555555),
                      ),
                    ),
                  const Spacer(),
                  _ActionIcon(
                    icon: CupertinoIcons.cart_badge_plus,
                    color: const Color(0xFFEF2A39),
                    onTap: _handleAddToCart,
                    isAnimating: _isCartAnimating,
                  ),
                  const SizedBox(width: 8),
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
