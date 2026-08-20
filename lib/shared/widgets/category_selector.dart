
import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  final List<dynamic> categories;

  final bool showPromotion;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
    this.showPromotion = false,
  });

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
