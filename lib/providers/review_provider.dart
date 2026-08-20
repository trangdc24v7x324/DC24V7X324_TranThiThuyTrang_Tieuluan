
import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/product_review_model.dart';
import 'package:project_trangdc24v7x324/services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  final List<ProductReviewModel> _reviews = [];

  ProductReviewModel? _myReview;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isCheckingEligibility = false;
  bool _canReview = false;

  String? _errorMessage;

  List<ProductReviewModel> get reviews => List.unmodifiable(_reviews);

  ProductReviewModel? get myReview => _myReview;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isCheckingEligibility => _isCheckingEligibility;

  bool get canReview => _canReview;

  String? get errorMessage => _errorMessage;

  int get reviewCount => _reviews.length;

  double get averageRating {
    if (_reviews.isEmpty) {
      return 0;
    }

    final int total = _reviews.fold<int>(0, (sum, item) => sum + item.rating);

    return total / _reviews.length;
  }

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

  Future<bool> _canReviewSafely(String productId) async {
    try {
      return await _service.canCurrentUserReview(productId);
    } catch (error) {
      debugPrint('review eligibility error: $error');
      return false;
    }
  }

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

  void clear() {
    _reviews.clear();
    _myReview = null;
    _canReview = false;
    _isCheckingEligibility = false;
    _errorMessage = null;

    notifyListeners();
  }
}
