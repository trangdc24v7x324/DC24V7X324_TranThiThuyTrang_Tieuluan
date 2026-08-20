// FILE HỌC TẬP: lib/services/product_service.dart
// Vai trò: Service nghiệp vụ sản phẩm.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/category_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';

// Lớp ProductService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class ProductService {
  // Lấy danh mục (getCategories): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final records = await pb
          .collection('categories')
          .getFullList(sort: 'sortOrder', filter: 'isActive = true');

      return records.map((record) {
        return CategoryModel.fromJson({
          'id': record.id,
          ...record.data,
          'created': record.created,
          'updated': record.updated,
        });
      }).toList();
    } catch (error) {
      debugPrint('GET CATEGORIES ERROR: $error');
      rethrow;
    }
  }

  // Lấy sản phẩm (getProducts): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<List<ProductModel>> getProducts() async {
    try {
      final records = await pb
          .collection('products')
          .getFullList(sort: '-created', expand: 'category');

      return records.map(_mapProductRecord).toList();
    } catch (error) {
      debugPrint('GET PRODUCTS ERROR: $error');
      rethrow;
    }
  }

  // Lấy sản phẩm by mã (getProductById): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<ProductModel> getProductById(String id) async {
    try {
      final record = await pb
          .collection('products')
          .getOne(id, expand: 'category');

      return _mapProductRecord(record);
    } catch (error) {
      debugPrint('GET PRODUCT BY ID ERROR: $error');
      rethrow;
    }
  }

  // Thêm sản phẩm (addProduct): đưa mục mới vào state/backend và cập nhật giao diện.
  Future<void> addProduct(
    ProductModel product, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final categoryId = await _resolveCategoryId(product);
      final body = _buildBody(product, categoryId);

      await pb
          .collection('products')
          .create(
            body: body,
            files: _buildImageFiles(
              imageBytes: imageBytes,
              imageName: imageName,
            ),
          );
    } catch (error) {
      debugPrint('ADD PRODUCT ERROR: $error');
      rethrow;
    }
  }

  // Cập nhật sản phẩm (updateProduct): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<void> updateProduct(
    String id,
    ProductModel product, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      final categoryId = await _resolveCategoryId(product);
      final body = _buildBody(product, categoryId);

      await pb
          .collection('products')
          .update(
            id,
            body: body,
            files: _buildImageFiles(
              imageBytes: imageBytes,
              imageName: imageName,
            ),
          );
    } catch (error) {
      debugPrint('UPDATE PRODUCT ERROR: $error');
      rethrow;
    }
  }

  // Xóa sản phẩm (deleteProduct): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  Future<void> deleteProduct(String productId) async {
    await pb
        .collection('products')
        .update(productId, body: {'isAvailable': false});
  }

  // Tạo giao diện nội dung (_buildBody): dựng widget con từ dữ liệu hiện tại.
  Map<String, dynamic> _buildBody(ProductModel product, String? categoryId) {
    return {
      'title': product.title.trim(),
      'subtitle': product.subtitle.trim(),
      'rating': product.rating,
      'description': product.description.trim(),
      'deliveryTime': product.deliveryTime.trim(),
      'price': product.price,
      'salePrice': product.salePrice,
      'isOnSale': product.isOnSale,
      'saleStartAt': _dateValue(product.saleStartAt),
      'saleEndAt': _dateValue(product.saleEndAt),
      'category': categoryId,
      'isAvailable': product.isAvailable,
    };
  }

  // Tạo giao diện hình ảnh files (_buildImageFiles): dựng widget con từ dữ liệu hiện tại.
  List<http.MultipartFile> _buildImageFiles({
    required Uint8List? imageBytes,
    required String? imageName,
  }) {
    if (imageBytes == null || imageBytes.isEmpty) {
      return const [];
    }

    final safeName = _safeImageName(imageName);

    return [
      http.MultipartFile.fromBytes('image', imageBytes, filename: safeName),
    ];
  }

  // Xử lý _safeImageName: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ sản phẩm.
  String _safeImageName(String? imageName) {
    final raw = imageName?.trim() ?? '';

    if (raw.isEmpty) {
      return 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }

    final normalized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (normalized.contains('.')) {
      return normalized;
    }

    return '$normalized.jpg';
  }

  // Xử lý _dateValue: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ sản phẩm.
  String? _dateValue(DateTime? value) {
    if (value == null) return null;
    return value.toUtc().toIso8601String();
  }

  // Ánh xạ sản phẩm bản ghi (_mapProductRecord): chuyển dữ liệu thô thành cấu trúc ứng dụng sử dụng.
  ProductModel _mapProductRecord(dynamic record) {
    final categoryData = _getCategoryData(record);

    return ProductModel.fromJson({
      'id': record.id,
      ...record.data,
      'image': _buildProductImageUrl(record),
      'category': categoryData['id'],
      'categoryTitle': categoryData['title'],
      'categorySlug': categoryData['slug'],
      'created': record.created,
      'updated': record.updated,
    });
  }

  // Lấy danh mục dữ liệu (_getCategoryData): truy xuất và trả kết quả cho lớp gọi.
  Map<String, String> _getCategoryData(dynamic record) {
    try {
      final expand = record.expand;

      if (expand['category'] != null && expand['category']!.isNotEmpty) {
        final category = expand['category']!.first;

        return {
          'id': category.id,
          'title': category.getStringValue('title'),
          'slug': category.getStringValue('slug'),
        };
      }
    } catch (_) {}

    final rawCategory = record.data['category']?.toString() ?? '';

    return {'id': rawCategory, 'title': 'Khác', 'slug': 'khac'};
  }

  // Tạo giao diện sản phẩm hình ảnh url (_buildProductImageUrl): dựng widget con từ dữ liệu hiện tại.
  String _buildProductImageUrl(dynamic record) {
    final fileName = record.getStringValue('image');

    if (fileName.isEmpty) return '';

    return '${pb.baseUrl}/api/files/products/${record.id}/$fileName';
  }

  // Xử lý danh mục mã (_resolveCategoryId): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
  Future<String?> _resolveCategoryId(ProductModel product) async {
    if (product.categoryId.trim().isNotEmpty) {
      return product.categoryId.trim();
    }

    if (product.categorySlug.trim().isNotEmpty &&
        product.categorySlug.trim() != 'khac') {
      final safeSlug = product.categorySlug.trim().replaceAll('"', r'\"');

      final records = await pb
          .collection('categories')
          .getFullList(filter: 'slug = "$safeSlug"');

      if (records.isNotEmpty) {
        return records.first.id;
      }
    }

    return null;
  }
}
