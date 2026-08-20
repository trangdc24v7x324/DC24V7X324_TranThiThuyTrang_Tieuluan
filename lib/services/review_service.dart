// FILE HỌC TẬP: lib/services/review_service.dart
// Vai trò: Service nghiệp vụ đánh giá.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/product_review_model.dart';
import 'package:project_trangdc24v7x324/services/order_service.dart';

// Lớp ReviewService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class ReviewService {
  // Đọc pb (_pb): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  PocketBase get _pb => getPocketBase();

  final OrderService _orderService = OrderService();

  // =========================================================
  // GET PRODUCT REVIEWS
  // =========================================================

  // Lấy đánh giá (getReviews): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<List<ProductReviewModel>> getReviews(String productId) async {
    try {
      final records = await _pb
          .collection('product_reviews')
          .getFullList(
            sort: '-created',
            filter: 'product = "$productId" && isVisible = true',
            expand: 'user',
          );

      return records.map((record) {
        String userFullName = 'Khách hàng';

        try {
          final expand = record.expand;

          if (expand['user'] != null && expand['user']!.isNotEmpty) {
            final user = expand['user']!.first;

            final name = user.getStringValue('fullName');

            if (name.trim().isNotEmpty) {
              userFullName = name.trim();
            }
          }
        } catch (_) {}

        return ProductReviewModel.fromJson({
          'id': record.id,
          ...record.data,
          'userFullName': userFullName,
          'created': record.created,
          'updated': record.updated,
        });
      }).toList();
    } catch (error) {
      debugPrint('GET REVIEWS ERROR: $error');

      rethrow;
    }
  }

  // =========================================================
  // CURRENT USER REVIEW
  // =========================================================

  // Lấy của tôi đánh giá (getMyReview): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<ProductReviewModel?> getMyReview(String productId) async {
    final userId = _pb.authStore.model?.id;

    if (userId == null || userId.isEmpty) {
      return null;
    }

    try {
      final result = await _pb
          .collection('product_reviews')
          .getList(
            page: 1,
            perPage: 1,
            filter: 'product = "$productId" && user = "$userId"',
            expand: 'user',
          );

      if (result.items.isEmpty) {
        return null;
      }

      final record = result.items.first;

      String fullName = 'Khách hàng';

      try {
        final expand = record.expand;

        if (expand['user'] != null && expand['user']!.isNotEmpty) {
          fullName = expand['user']!.first.getStringValue('fullName');
        }
      } catch (_) {}

      return ProductReviewModel.fromJson({
        'id': record.id,
        ...record.data,
        'userFullName': fullName,
        'created': record.created,
        'updated': record.updated,
      });
    } catch (error) {
      debugPrint('GET MY REVIEW ERROR: $error');

      return null;
    }
  }

  // =========================================================
  // REVIEW ELIGIBILITY
  // =========================================================

  // Kiểm tra điều kiện (canCurrentUserReview): đánh giá khả năng hiện tại người dùng đánh giá và trả kết quả cho lớp gọi.
  Future<bool> canCurrentUserReview(String productId) async {
    if (!_pb.authStore.isValid) {
      return false;
    }

    final safeProductId = productId.trim();

    if (safeProductId.isEmpty) {
      return false;
    }

    return _orderService.hasCompletedPurchase(safeProductId);
  }

  // =========================================================
  // CREATE / UPDATE REVIEW
  // =========================================================

  // Lưu đánh giá (saveReview): kiểm tra dữ liệu, ghi thay đổi và đồng bộ state sau khi thành công.
  Future<void> saveReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (!_pb.authStore.isValid) {
      throw Exception('Bạn cần đăng nhập để đánh giá.');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Đánh giá phải từ 1 đến 5 sao.');
    }

    final userId = _pb.authStore.model?.id;

    if (userId == null || userId.isEmpty) {
      throw Exception('Không tìm thấy tài khoản.');
    }

    final canReview = await canCurrentUserReview(productId);

    if (!canReview) {
      throw Exception(
        'Bạn chỉ có thể đánh giá sản phẩm đã mua trong '
        'đơn hoàn thành và đã thanh toán.',
      );
    }

    final existing = await getMyReview(productId);

    if (existing != null) {
      await _pb
          .collection('product_reviews')
          .update(
            existing.id,
            body: {'rating': rating, 'comment': comment.trim()},
          );

      return;
    }

    await _pb
        .collection('product_reviews')
        .create(
          body: {
            'product': productId,
            'user': userId,
            'rating': rating,
            'comment': comment.trim(),
            'isVisible': true,
          },
        );
  }

  // =========================================================
  // DELETE REVIEW
  // =========================================================

  // Xóa của tôi đánh giá (deleteMyReview): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<void> deleteMyReview(String productId) async {
    final existing = await getMyReview(productId);

    if (existing == null) {
      return;
    }

    await _pb.collection('product_reviews').delete(existing.id);
  }

  // =========================================================
  // PRODUCT RATING
  // =========================================================

  // Lấy điểm đánh giá thống kê for sản phẩm (getRatingStatsForProduct): truy xuất và trả kết quả cho lớp gọi.
  Future<ProductRatingStats> getRatingStatsForProduct(String productId) async {
    final reviews = await getReviews(productId);

    if (reviews.isEmpty) {
      return const ProductRatingStats();
    }

    final int total = reviews.fold<int>(
      0,
      (sum, review) => sum + review.rating,
    );

    return ProductRatingStats(
      average: total / reviews.length,
      count: reviews.length,
    );
  }

  // =========================================================
  // ALL PRODUCT RATING STATS
  // =========================================================

  // Lấy tất cả điểm đánh giá thống kê (getAllRatingStats): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<Map<String, ProductRatingStats>> getAllRatingStats() async {
    try {
      List<dynamic> records;

      try {
        records = await _pb
            .collection('product_reviews')
            .getFullList(filter: 'isVisible = true');
      } catch (_) {
        // Tương thích collection cũ chưa có trường isVisible.
        records = await _pb.collection('product_reviews').getFullList();
      }

      final Map<String, int> totals = {};

      final Map<String, int> counts = {};

      for (final record in records) {
        final String productId =
            (record.data['product'] ?? record.data['productId'] ?? '')
                .toString()
                .trim();

        if (productId.isEmpty) {
          continue;
        }

        final dynamic rawRating = record.data['rating'];

        final int rating =
            rawRating is num
                ? rawRating.toInt()
                : int.tryParse(rawRating?.toString() ?? '') ?? 0;

        if (rating < 1 || rating > 5) {
          continue;
        }

        totals[productId] = (totals[productId] ?? 0) + rating;

        counts[productId] = (counts[productId] ?? 0) + 1;
      }

      final Map<String, ProductRatingStats> result = {};

      for (final productId in counts.keys) {
        final int count = counts[productId] ?? 0;

        final int total = totals[productId] ?? 0;

        result[productId] = ProductRatingStats(
          average: count == 0 ? 0 : total / count,
          count: count,
        );
      }

      return result;
    } catch (error) {
      debugPrint('GET RATING STATS ERROR: $error');

      rethrow;
    }
  }
}
