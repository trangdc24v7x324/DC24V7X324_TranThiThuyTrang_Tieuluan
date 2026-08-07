import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  //nhận categories từ provider
  final List<dynamic> categories;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  IconData _getIcon(String icon) {
    switch (icon) {
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

          return GestureDetector(
            onTap: () => onCategorySelected(slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color.fromARGB(255, 129, 124, 124)
                        : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
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
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item['title'].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
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
