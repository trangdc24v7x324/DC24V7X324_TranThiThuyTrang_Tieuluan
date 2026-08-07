class CategoryModel {
  final String id;
  final String title;
  final String slug;
  final String icon;
  final int sortOrder;
  final bool isActive;
  final DateTime? created;
  final DateTime? updated;

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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'icon': icon,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

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
