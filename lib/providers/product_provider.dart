import 'dart:typed_data';

import 'package:CT466_project_trangdc24v7x324/models/category_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/product_model.dart';
import 'package:CT466_project_trangdc24v7x324/services/product_service.dart';
import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  final List<ProductModel> _products = [];
  final List<CategoryModel> _categories = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String _selectedCategorySlug = 'all';
  String _searchKeyword = '';

  String? _errorMessage;

  List<ProductModel> get products => List.unmodifiable(_products);

  List<CategoryModel> get categories => List.unmodifiable(_categories);

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String get selectedCategorySlug => _selectedCategorySlug;

  String get searchKeyword => _searchKeyword;

  String? get errorMessage => _errorMessage;

  List<ProductModel> get availableProducts {
    return _products.where((product) => product.isAvailable).toList();
  }

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

  List<ProductModel> get filteredAvailableProducts {
    return filteredProducts.where((product) => product.isAvailable).toList();
  }

  Future<void> loadInitialData() async {
    _setLoading(true);
    _clearError();

    try {
      final results = await Future.wait([
        _productService.getCategories(),
        _productService.getProducts(),
      ]);

      _categories
        ..clear()
        ..addAll(results[0] as List<CategoryModel>);

      _products
        ..clear()
        ..addAll(results[1] as List<ProductModel>);
    } catch (error) {
      _setError('Không thể tải dữ liệu sản phẩm');
      debugPrint('loadInitialData error: $error');
    } finally {
      _setLoading(false);
    }
  }

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

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _productService.getProducts();

      _products
        ..clear()
        ..addAll(result);
    } catch (error) {
      _setError('Không thể tải sản phẩm');
      debugPrint('loadProducts error: $error');
    } finally {
      _setLoading(false);
    }
  }

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
  Future<void> refreshProductRating(String productId) async {
    final normalizedId = productId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _clearError();

    try {
      final refreshedProduct = await _productService.getProductById(
        normalizedId,
      );

      final index = _products.indexWhere(
        (product) => product.id == normalizedId,
      );

      if (index >= 0) {
        _products[index] = refreshedProduct;
      } else {
        _products.add(refreshedProduct);
      }

      notifyListeners();
    } catch (error) {
      _setError('Không thể cập nhật điểm đánh giá sản phẩm');
      debugPrint('refreshProductRating error: $error');
    }
  }

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

  void selectCategory(String slug) {
    _selectedCategorySlug = slug;
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategorySlug = 'all';
    notifyListeners();
  }

  void searchProducts(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  void clearSearch() {
    _searchKeyword = '';
    notifyListeners();
  }

  ProductModel? findProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? findCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? findCategoryBySlug(String slug) {
    try {
      return _categories.firstWhere((category) => category.slug == slug);
    } catch (_) {
      return null;
    }
  }

  void clearData() {
    _products.clear();
    _categories.clear();
    _selectedCategorySlug = 'all';
    _searchKeyword = '';
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
