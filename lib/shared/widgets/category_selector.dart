// FILE HỌC TẬP: lib/shared/widgets/category_selector.dart
// Vai trò: Widget dùng chung cho danh mục bộ chọn.
// Luồng sử dụng: Đóng gói bố cục/giao diện lặp lại để tái sử dụng trong nhiều màn hình.

import 'package:flutter/material.dart';

// Lớp CategorySelector: thành phần phục vụ widget dùng chung cho danh mục bộ chọn.
class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  // Nhận categories từ provider.
  final List<dynamic> categories;

  // Chỉ HomePage bật tùy chọn này để thêm tab khuyến mãi ảo.
  final bool showPromotion;

  // Khởi tạo CategorySelector: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho danh mục bộ chọn.
  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
    this.showPromotion = false,
  });

  // Lấy biểu tượng (_getIcon): truy xuất và trả kết quả cho lớp gọi.
  IconData _getIcon(String icon) {
    switch (icon) {
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'local_drink':
        return Icons.local_drink_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Xây dựng giao diện (build): dựng cây widget của CategorySelector từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final items = [
      if (showPromotion)
        {
          'slug': 'promotion_today',
          'title': 'Khuyến mãi hôm nay',
          'icon': 'promotion',
        },
      {'slug': 'all', 'title': 'Tất cả', 'icon': 'category'},
      ...categories.map(
        (cat) => {'slug': cat.slug, 'title': cat.title, 'icon': cat.icon},
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final slug = item['slug'].toString();
          final isSelected = slug == selectedCategory;
          final isPromotion = slug == 'promotion_today';

          return GestureDetector(
            onTap: () => onCategorySelected(slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? (isPromotion
                            ? const Color(0xFFEF2A39)
                            : const Color.fromARGB(255, 129, 124, 124))
                        : (isPromotion
                            ? const Color(0xFFFFECEE)
                            : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(14),
                border:
                    isPromotion && !isSelected
                        ? Border.all(color: const Color(0xFFFFC8CD))
                        : null,
                boxShadow:
                    isSelected
                        ? const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ]
                        : [],
              ),
              child: Row(
                children: [
                  Icon(
                    _getIcon(item['icon'].toString()),
                    size: 18,
                    color:
                        isSelected
                            ? Colors.white
                            : (isPromotion
                                ? const Color(0xFFEF2A39)
                                : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item['title'].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? Colors.white
                              : (isPromotion
                                  ? const Color(0xFFEF2A39)
                                  : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
