import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/product_review_model.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/providers/review_provider.dart';

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
