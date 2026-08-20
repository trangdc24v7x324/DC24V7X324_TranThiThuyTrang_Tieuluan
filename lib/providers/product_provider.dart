// FILE HỌC TẬP: lib/providers/product_provider.dart
// Vai trò: Provider quản lý trạng thái sản phẩm.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'dart:typed_data';

import 'package:project_trangdc24v7x324/models/category_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/models/product_review_model.dart';
import 'package:project_trangdc24v7x324/services/product_service.dart';
import 'package:project_trangdc24v7x324/services/review_service.dart';
import 'package:flutter/material.dart';

// Lớp ProductProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();

  final List<ProductModel> _products = [];
  final List<CategoryModel> _categories = [];
  final Map<String, ProductRatingStats> _ratingStats = {};

  bool _isLoading = false;
  bool _isSaving = false;

  String _selectedCategorySlug = 'all';
  String _searchKeyword = '';

  String? _errorMessage;

  // Đọc sản phẩm (products): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ProductModel> get products => List.unmodifiable(_products);

  // Đọc danh mục (categories): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<CategoryModel> get categories => List.unmodifiable(_categories);

  // Xử lý ratingStatsForProduct: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái sản phẩm.
  ProductRatingStats ratingStatsForProduct(String productId) {
    return _ratingStats[productId] ?? const ProductRatingStats();
  }

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;

  // Đọc trạng thái đang lưu (isSaving): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isSaving => _isSaving;

  // Đọc đã chọn danh mục slug (selectedCategorySlug): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get selectedCategorySlug => _selectedCategorySlug;

  // Đọc tìm kiếm keyword (searchKeyword): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String get searchKeyword => _searchKeyword;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc khả dụng sản phẩm (availableProducts): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ProductModel> get availableProducts {
    return _products.where((product) => product.isAvailable).toList();
  }

  // Đọc đã lọc sản phẩm (filteredProducts): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ProductModel> get filteredProducts {
    Iterable<ProductModel> result = _products;

    if (_selectedCategorySlug != 'all') {
      result = result.where(
        (product) => product.categorySlug == _selectedCategorySlug,
      );
    }

    if (_searchKeyword.trim().isNotEmpty) {
      final keyword = _searchKeyword.toLowerCase().trim();

      result = result.where((product) {
        return product.title.toLowerCase().contains(keyword) ||
            product.subtitle.toLowerCase().contains(keyword) ||
            product.description.toLowerCase().contains(keyword) ||
            product.categoryTitle.toLowerCase().contains(keyword);
      });
    }

    return result.toList();
  }

  // Đọc đã lọc khả dụng sản phẩm (filteredAvailableProducts): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ProductModel> get filteredAvailableProducts {
    return filteredProducts.where((product) => product.isAvailable).toList();
  }

  // Tải rating: lỗi collection review không được chặn việc hiển thị sản phẩm.
  // Tải điểm đánh giá thống kê an toàn (_loadRatingStatsSafely): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<Map<String, ProductRatingStats>> _loadRatingStatsSafely() async {
    try {
      return await _reviewService.getAllRatingStats();
    } catch (error) {
      debugPrint('loadRatingStats error: $error');
      return <String, ProductRatingStats>{};
    }
  }

  // Tải rating một sản phẩm: trả thống kê rỗng nếu review tạm thời lỗi.
  // Tải điểm đánh giá thống kê for sản phẩm an toàn (_loadRatingStatsForProductSafely): lấy dữ liệu cần cho màn hình và cập nhật
  // state hiển thị.
  Future<ProductRatingStats> _loadRatingStatsForProductSafely(
    String productId,
  ) async {
    try {
      return await _reviewService.getRatingStatsForProduct(productId);
    } catch (error) {
      debugPrint('loadProductRatingStats error: $error');
      return const ProductRatingStats();
    }
  }

  // Tải ban đầu dữ liệu (loadInitialData): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadInitialData() async {
    _setLoading(true);
    _clearError();

    try {
      final results = await Future.wait([
        _productService.getCategories(),
        _productService.getProducts(),
        _loadRatingStatsSafely(),
      ]);

      _categories
        ..clear()
        ..addAll(results[0] as List<CategoryModel>);

      _products
        ..clear()
        ..addAll(results[1] as List<ProductModel>);

      _ratingStats
        ..clear()
        ..addAll(results[2] as Map<String, ProductRatingStats>);
    } catch (error) {
      _setError('Không thể tải dữ liệu sản phẩm');
      debugPrint('loadInitialData error: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Tải danh mục (loadCategories): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _productService.getCategories();

      _categories
        ..clear()
        ..addAll(result);
    } catch (error) {
      _setError('Không thể tải danh mục');
      debugPrint('loadCategories error: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Tải sản phẩm (loadProducts): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final results = await Future.wait([
        _productService.getProducts(),
        _loadRatingStatsSafely(),
      ]);

      _products
        ..clear()
        ..addAll(results[0] as List<ProductModel>);

      _ratingStats
        ..clear()
        ..addAll(results[1] as Map<String, ProductRatingStats>);
    } catch (error) {
      _setError('Không thể tải sản phẩm');
      debugPrint('loadProducts error: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Lấy sản phẩm chi tiết (getProductDetail): truy xuất và trả kết quả cho lớp gọi.
  Future<ProductModel?> getProductDetail(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      return await _productService.getProductById(productId);
    } catch (error) {
      _setError('Không thể tải chi tiết sản phẩm');
      debugPrint('getProductDetail error: $error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // REFRESH PRODUCT RATING
  // =========================================================

  /// Đọc lại một sản phẩm sau khi Customer thêm, sửa hoặc xóa đánh giá.
  ///
  /// Không bật trạng thái loading toàn trang để tránh làm ProductPage
  /// nhấp nháy sau khi lưu review.
  // Làm mới sản phẩm điểm đánh giá (refreshProductRating): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<void> refreshProductRating(String productId) async {
    final normalizedId = productId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _clearError();

    try {
      final results = await Future.wait([
        _productService.getProductById(normalizedId),
        _loadRatingStatsForProductSafely(normalizedId),
      ]);

      final refreshedProduct = results[0] as ProductModel;
      final ratingStats = results[1] as ProductRatingStats;

      final index = _products.indexWhere(
        (product) => product.id == normalizedId,
      );

      if (index >= 0) {
        _products[index] = refreshedProduct;
      } else {
        _products.add(refreshedProduct);
      }

      _ratingStats[normalizedId] = ratingStats;
      notifyListeners();
    } catch (error) {
      _setError('Không thể cập nhật điểm đánh giá sản phẩm');
      debugPrint('refreshProductRating error: $error');
    }
  }

  // Thêm sản phẩm (addProduct): đưa mục mới vào state/backend và cập nhật giao diện.
  Future<bool> addProduct(
    ProductModel product, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _clearError();
    notifyListeners();

    try {
      await _productService.addProduct(
        product,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      await loadProducts();
      return true;
    } catch (error) {
      _setError('Thêm sản phẩm thất bại');
      debugPrint('addProduct error: $error');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Cập nhật sản phẩm (updateProduct): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<bool> updateProduct(
    String id,
    ProductModel product, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _clearError();
    notifyListeners();

    try {
      await _productService.updateProduct(
        id,
        product,
        imageBytes: imageBytes,
        imageName: imageName,
      );

      await loadProducts();
      return true;
    } catch (error) {
      _setError('Cập nhật sản phẩm thất bại');
      debugPrint('updateProduct error: $error');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Xóa sản phẩm (deleteProduct): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<bool> deleteProduct(String productId) async {
    _clearError();

    try {
      await _productService.deleteProduct(productId);

      final index = _products.indexWhere((item) => item.id == productId);

      if (index != -1) {
        _products[index] = _products[index].copyWith(isAvailable: false);
      }

      notifyListeners();
      return true;
    } catch (error) {
      _setError('Không thể ngừng bán sản phẩm');
      debugPrint('deleteProduct error: $error');
      return false;
    }
  }

  // Chọn danh mục (selectCategory): lưu lựa chọn để dùng cho lọc, biểu mẫu hoặc nghiệp vụ tiếp theo.
  void selectCategory(String slug) {
    _selectedCategorySlug = slug;
    notifyListeners();
  }

  // Xóa danh mục bộ lọc (clearCategoryFilter): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearCategoryFilter() {
    _selectedCategorySlug = 'all';
    notifyListeners();
  }

  // Lọc/tìm sản phẩm (searchProducts): tạo tập dữ liệu phù hợp theo điều kiện đang chọn.
  void searchProducts(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  // Xóa tìm kiếm (clearSearch): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearSearch() {
    _searchKeyword = '';
    notifyListeners();
  }

  // Xử lý findProductById: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái sản phẩm.
  ProductModel? findProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  // Xử lý findCategoryById: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái sản phẩm.
  CategoryModel? findCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  // Cập nhật state (findCategoryBySlug): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  CategoryModel? findCategoryBySlug(String slug) {
    try {
      return _categories.firstWhere((category) => category.slug == slug);
    } catch (_) {
      return null;
    }
  }

  // Xóa dữ liệu (clearData): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearData() {
    _products.clear();
    _categories.clear();
    _selectedCategorySlug = 'all';
    _searchKeyword = '';
    _clearError();
    notifyListeners();
  }

  // Cập nhật đang tải (_setLoading): gán state nội bộ và thông báo lại cho UI khi cần.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Cập nhật error (_setError): gán state nội bộ và thông báo lại cho UI khi cần.
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Xóa error (_clearError): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void _clearError() {
    _errorMessage = null;
  }
}
