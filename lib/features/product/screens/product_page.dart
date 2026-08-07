import 'package:CT466_project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:CT466_project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/product_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/product_review_model.dart';
import 'package:CT466_project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:CT466_project_trangdc24v7x324/providers/product_provider.dart';
import 'package:CT466_project_trangdc24v7x324/providers/review_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductReviewsSection extends StatefulWidget {
  final String productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final TextEditingController _commentController = TextEditingController();

  int _rating = 5;

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadReviews);
  }

  Future<void> _loadReviews() async {
    final provider = context.read<ReviewProvider>();

    await provider.loadReviews(widget.productId);

    if (!mounted) return;

    final myReview = provider.myReview;

    if (myReview != null) {
      setState(() {
        _rating = myReview.rating;

        _commentController.text = myReview.comment;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<ReviewProvider>();

    final success = await provider.saveReview(
      productId: widget.productId,
      rating: _rating,
      comment: _commentController.text,
    );

    if (!mounted) return;

    if (success) {
      await context.read<ProductProvider>().refreshProductRating(
        widget.productId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu đánh giá')));
    }
  }

  Future<void> _delete() async {
    final provider = context.read<ReviewProvider>();

    final success = await provider.deleteReview(widget.productId);

    if (!mounted) return;

    if (success) {
      _commentController.clear();

      setState(() {
        _rating = 5;
      });

      await context.read<ProductProvider>().refreshProductRating(
        widget.productId,
      );
    }
  }

  Widget _stars(double value, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < value.round()
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();

    final bool loggedIn = getPocketBase().authStore.isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),

        const SizedBox(height: 18),

        const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Text(
              provider.reviewCount == 0
                  ? '0.0'
                  : provider.averageRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stars(provider.averageRating),
                Text(
                  '${provider.reviewCount} đánh giá',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (loggedIn) ...[
          Text(
            provider.myReview == null
                ? 'Đánh giá của bạn'
                : 'Chỉnh sửa đánh giá',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          Row(
            children: List.generate(5, (index) {
              final value = index + 1;

              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
                onPressed: () {
                  setState(() {
                    _rating = value;
                  });
                },
                icon: Icon(
                  value <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 30,
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Chia sẻ cảm nhận của bạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.isSaving ? null : _submit,
                  child: Text(
                    provider.myReview == null
                        ? 'Gửi đánh giá'
                        : 'Cập nhật đánh giá',
                  ),
                ),
              ),

              if (provider.myReview != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xóa đánh giá',
                  onPressed: provider.isSaving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),
        ] else ...[
          Text(
            'Đăng nhập để đánh giá sản phẩm.',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),
        ],

        const Text(
          'Đánh giá từ khách hàng',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),

        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.reviews.isEmpty)
          Text(
            'Chưa có đánh giá nào.',
            style: TextStyle(color: Colors.grey.shade600),
          )
        else
          ...provider.reviews.map(_buildReview),
      ],
    );
  }

  Widget _buildReview(ProductReviewModel review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.userFullName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 4),

          _stars(review.rating.toDouble(), size: 16),

          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment),
          ],

          if (review.created != null) ...[
            const SizedBox(height: 6),
            Text(
              '${review.created!.day.toString().padLeft(2, '0')}/'
              '${review.created!.month.toString().padLeft(2, '0')}/'
              '${review.created!.year}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int quantity = 1;

  final TextEditingController noteController = TextEditingController();

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
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
  // PRODUCT IMAGE
  // =========================================================

  Widget _buildProductImage(String image) {
    if (image.isEmpty) {
      return const Center(
        child: Icon(Icons.fastfood, size: 60, color: Colors.grey),
      );
    }

    final bool isNetworkImage =
        image.startsWith('http://') || image.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.fastfood, size: 60, color: Colors.grey),
          );
        },
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.fastfood, size: 60, color: Colors.grey),
        );
      },
    );
  }

  // =========================================================
  // PRICE SECTION
  // =========================================================

  Widget _buildPriceSection(ProductModel product) {
    // Không sale.
    if (!product.hasActiveSale) {
      return Text(
        formatPrice(product.price),
        style: GoogleFonts.roboto(
          textStyle: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFFEF2A39),
          ),
        ),
      );
    }

    // Có sale.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ===============================================
            // SALE PRICE
            // ===============================================
            Text(
              formatPrice(product.effectivePrice),
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF2A39),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ===============================================
            // SALE BADGE
            // ===============================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF2A39),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${product.discountPercent}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // =================================================
        // ORIGINAL PRICE
        // =================================================
        Text(
          formatPrice(product.price),
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey.shade500,
            ),
          ),
        ),

        const SizedBox(height: 5),

        // =================================================
        // SAVING
        // =================================================
        Text(
          'Tiết kiệm ${formatPrice(product.discountAmount)}',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
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
    final Object? args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! ProductModel) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không có dữ liệu sản phẩm')),
      );
    }

    final ProductModel routeProduct = args;

    final ProductModel product =
        context.watch<ProductProvider>().findProductById(routeProduct.id) ??
        routeProduct;

    final double unitPrice = product.effectivePrice;

    final double totalPrice = unitPrice * quantity;

    final double totalSaving =
        product.hasActiveSale ? product.discountAmount * quantity : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff3C2F2F)),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // CONTENT
            // =================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================
                    // IMAGE
                    // =========================================
                    Center(
                      child: Container(
                        height: 280,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),

                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildProductImage(product.image),
                            ),

                            // ===============================
                            // SALE BADGE
                            // ===============================
                            if (product.hasActiveSale)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF2A39),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '-${product.discountPercent}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                            // ===============================
                            // OUT OF STOCK
                            // ===============================
                            if (!product.isAvailable)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Tạm hết hàng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // TITLE
                    // =========================================
                    Text(
                      product.title,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff3C2F2F),
                        ),
                      ),
                    ),

                    // =========================================
                    // SUBTITLE
                    // =========================================
                    if (product.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),

                      Text(
                        product.subtitle,
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            color: Color(0xff808080),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // =========================================
                    // RATING + DELIVERY
                    // =========================================
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),

                        const SizedBox(width: 4),

                        Text(
                          product.reviewCount > 0
                              ? '${product.rating.toStringAsFixed(1)} '
                                  '(${product.reviewCount} đánh giá)'
                              : 'Chưa có đánh giá',
                          style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Color(0xff808080),
                            ),
                          ),
                        ),

                        if (product.deliveryTime.isNotEmpty) ...[
                          const SizedBox(width: 8),

                          Text(
                            '• ${product.deliveryTime}',
                            style: GoogleFonts.roboto(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff808080),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 18),

                    // =========================================
                    // PRICE
                    // =========================================
                    _buildPriceSection(product),

                    const SizedBox(height: 22),

                    // =========================================
                    // DESCRIPTION
                    // =========================================
                    Text(
                      product.description.isEmpty
                          ? 'Chưa có mô tả cho sản phẩm này.'
                          : product.description,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: Color(0xff6A6A6A),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // NOTE
                    // =========================================
                    Text(
                      'Ghi chú',
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff3C2F2F),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      enabled: product.isAvailable,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff3C2F2F),
                        ),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: ít đá, không hành, thêm tương...',
                        hintStyle: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            color: Color(0xff9A9A9A),
                            fontSize: 14,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =========================================
                    // QUANTITY
                    // =========================================
                    Row(
                      children: [
                        Text(
                          'Số lượng',
                          style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff3C2F2F),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // =====================================
                        // MINUS
                        // =====================================
                        GestureDetector(
                          onTap:
                              product.isAvailable
                                  ? () {
                                    if (quantity > 1) {
                                      setState(() {
                                        quantity--;
                                      });
                                    }
                                  }
                                  : null,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  product.isAvailable
                                      ? Colors.red
                                      : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.minus,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            quantity.toString(),
                            style: GoogleFonts.roboto(
                              textStyle: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff3C2F2F),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // =====================================
                        // PLUS
                        // =====================================
                        GestureDetector(
                          onTap:
                              product.isAvailable
                                  ? () {
                                    setState(() {
                                      quantity++;
                                    });
                                  }
                                  : null,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  product.isAvailable
                                      ? Colors.red
                                      : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // =========================================
                    // TOTAL SAVING
                    // =========================================
                    if (product.hasActiveSale && quantity > 1) ...[
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Tổng tiết kiệm: '
                          '${formatPrice(totalSaving)}',
                          style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),

                    ProductReviewsSection(productId: product.id),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // =================================================
            // BOTTOM CART AREA
            // =================================================
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),

              child: Row(
                children: [
                  // ===========================================
                  // TOTAL PRICE
                  // ===========================================
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: product.isAvailable ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          formatPrice(totalPrice),
                          style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ===========================================
                  // ADD CART
                  // ===========================================
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed:
                            product.isAvailable
                                ? () {
                                  final CartProvider cart =
                                      context.read<CartProvider>();

                                  cart.addItem(
                                    CartItemModel.fromProduct(
                                      product,
                                      quantity: quantity,
                                      note: noteController.text.trim(),
                                    ),
                                  );

                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        noteController.text.trim().isEmpty
                                            ? 'Đã thêm ${product.title} vào giỏ hàng'
                                            : 'Đã thêm ${product.title} - Ghi chú: ${noteController.text.trim()}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  Navigator.pop(context);
                                }
                                : null,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff3C2F2F),
                          disabledBackgroundColor: Colors.grey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: Text(
                          product.isAvailable ? 'Thêm vào giỏ' : 'Tạm hết hàng',
                          style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
