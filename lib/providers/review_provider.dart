// FILE HỌC TẬP: lib/providers/review_provider.dart
// Vai trò: Provider quản lý trạng thái đánh giá.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/product_review_model.dart';
import 'package:project_trangdc24v7x324/services/review_service.dart';

// Lớp ReviewProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  final List<ProductReviewModel> _reviews = [];

  ProductReviewModel? _myReview;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isCheckingEligibility = false;
  bool _canReview = false;

  String? _errorMessage;

  // Đọc đánh giá (reviews): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ProductReviewModel> get reviews => List.unmodifiable(_reviews);

  // Đọc của tôi đánh giá (myReview): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  ProductReviewModel? get myReview => _myReview;

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;

  // Đọc trạng thái đang lưu (isSaving): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isSaving => _isSaving;

  // Đọc trạng thái checking điều kiện (isCheckingEligibility): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isCheckingEligibility => _isCheckingEligibility;

  // Đọc khả năng đánh giá (canReview): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get canReview => _canReview;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc đánh giá số lượng (reviewCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get reviewCount => _reviews.length;

  // Đọc trung bình điểm đánh giá (averageRating): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  double get averageRating {
    if (_reviews.isEmpty) {
      return 0;
    }

    final int total = _reviews.fold<int>(0, (sum, item) => sum + item.rating);

    return total / _reviews.length;
  }

  // Kiểm tra đánh giá điều kiện (checkReviewEligibility): xác minh điều kiện/định dạng và trả kết quả cho lớp gọi.
  Future<bool> checkReviewEligibility(String productId) async {
    _isCheckingEligibility = true;
    notifyListeners();

    try {
      _canReview = await _service.canCurrentUserReview(productId);
      return _canReview;
    } catch (error) {
      _canReview = false;
      debugPrint('checkReviewEligibility error: $error');
      return false;
    } finally {
      _isCheckingEligibility = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOAD
  // =========================================================

  // Kiểm tra quyền đánh giá an toàn: lỗi quyền orders/payments chỉ khóa form review.
  // Kiểm tra điều kiện (_canReviewSafely): đánh giá khả năng đánh giá an toàn và trả kết quả cho lớp gọi.
  Future<bool> _canReviewSafely(String productId) async {
    try {
      return await _service.canCurrentUserReview(productId);
    } catch (error) {
      debugPrint('review eligibility error: $error');
      return false;
    }
  }

  // Tải đánh giá: danh sách, review của tôi và quyền đánh giá chạy song song.
  // Tải đánh giá (loadReviews): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadReviews(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getReviews(productId),
        _service.getMyReview(productId),
        _canReviewSafely(productId),
      ]);

      _reviews
        ..clear()
        ..addAll(results[0] as List<ProductReviewModel>);
      _myReview = results[1] as ProductReviewModel?;
      _canReview = results[2] as bool;
    } catch (error) {
      _errorMessage = 'Không thể tải đánh giá';
      debugPrint('loadReviews error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Làm mới nội dung review: không kiểm tra lại điều kiện mua hàng sau mỗi thao tác.
  // Tải đánh giá dữ liệu only (_reloadReviewDataOnly): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> _reloadReviewDataOnly(String productId) async {
    final results = await Future.wait([
      _service.getReviews(productId),
      _service.getMyReview(productId),
    ]);

    _reviews
      ..clear()
      ..addAll(results[0] as List<ProductReviewModel>);
    _myReview = results[1] as ProductReviewModel?;
  }

  // =========================================================
  // SAVE
  // =========================================================

  // Lưu đánh giá (saveReview): kiểm tra dữ liệu, ghi thay đổi và đồng bộ state sau khi thành công.
  Future<bool> saveReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.saveReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );

      await _reloadReviewDataOnly(productId);
      _canReview = true;

      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // =========================================================
  // DELETE
  // =========================================================

  // Xóa đánh giá (deleteReview): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> deleteReview(String productId) async {
    _isSaving = true;

    notifyListeners();

    try {
      await _service.deleteMyReview(productId);

      await _reloadReviewDataOnly(productId);

      return true;
    } catch (error) {
      _errorMessage = 'Không thể xóa đánh giá';

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // Cập nhật state (clear): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  void clear() {
    _reviews.clear();
    _myReview = null;
    _canReview = false;
    _isCheckingEligibility = false;
    _errorMessage = null;

    notifyListeners();
  }
}
