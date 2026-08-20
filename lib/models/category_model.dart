// FILE HỌC TẬP: lib/models/category_model.dart
// Vai trò: Mô hình dữ liệu danh mục.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp CategoryModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class CategoryModel {
  final String id;
  final String title;
  final String slug;
  final String icon;
  final int sortOrder;
  final bool isActive;
  final DateTime? created;
  final DateTime? updated;

  // Khởi tạo CategoryModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu danh mục.
  const CategoryModel({
    required this.id,
    required this.title,
    required this.slug,
    this.icon = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.created,
    this.updated,
  });

  // Khởi tạo CategoryModel.fromJson: tạo đối tượng CategoryModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      sortOrder: ((json['sortOrder'] ?? 0) as num).toInt(),
      isActive: json['isActive'] != false,
      created: DateTime.tryParse(json['created']?.toString() ?? ''),
      updated: DateTime.tryParse(json['updated']?.toString() ?? ''),
    );
  }

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'icon': icon,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  CategoryModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? icon,
    int? sortOrder,
    bool? isActive,
    DateTime? created,
    DateTime? updated,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
