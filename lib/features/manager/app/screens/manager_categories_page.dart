
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/category_model.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';

class ManagerCategoriesPage extends StatefulWidget {

  const ManagerCategoriesPage({super.key});

  @override
  State<ManagerCategoriesPage> createState() => _ManagerCategoriesPageState();
}

class _ManagerCategoriesPageState extends State<ManagerCategoriesPage> {
  final List<CategoryModel> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final records = await pb
          .collection('categories')
          .getFullList(sort: 'sortOrder');

      _categories
        ..clear()
        ..addAll(
          records.map((record) {
            return CategoryModel.fromJson({
              'id': record.id,
              ...record.data,
              'created': record.created,
              'updated': record.updated,
            });
          }),
        );
    } catch (e) {
      _showMessage('Không tải được danh mục');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'local_drink':
        return Icons.local_drink_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'bakery_dining':
        return Icons.bakery_dining_rounded;
      case 'icecream':
        return Icons.icecream_rounded;
      case 'ramen_dining':
        return Icons.ramen_dining_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _makeSlug(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(' ', '-')
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm({CategoryModel? category}) async {
    final titleController = TextEditingController(text: category?.title ?? '');
    final slugController = TextEditingController(text: category?.slug ?? '');
    final sortController = TextEditingController(
      text: category != null ? category.sortOrder.toString() : '0',
    );

    String selectedIcon = category?.icon ?? 'category';
    bool isActive = category?.isActive ?? true;
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (!isEdit) slugController.text = _makeSlug(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: slugController,
                      decoration: const InputDecoration(
                        labelText: 'Slug',
                        hintText: 'vd: food, drink, combos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự hiển thị',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'category',
                          child: Text('Danh mục'),
                        ),
                        DropdownMenuItem(
                          value: 'restaurant',
                          child: Text('Món ăn'),
                        ),
                        DropdownMenuItem(
                          value: 'local_drink',
                          child: Text('Nước uống'),
                        ),
                        DropdownMenuItem(
                          value: 'fastfood',
                          child: Text('Combo / Fastfood'),
                        ),
                        DropdownMenuItem(
                          value: 'bakery_dining',
                          child: Text('Bánh'),
                        ),
                        DropdownMenuItem(
                          value: 'icecream',
                          child: Text('Tráng miệng'),
                        ),
                        DropdownMenuItem(
                          value: 'ramen_dining',
                          child: Text('Mì / bún'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedIcon = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đang hoạt động'),
                      value: isActive,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green,
                      onChanged:
                          (value) => setDialogState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF2A39),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final slug = slugController.text.trim();
                    final sortOrder =
                        int.tryParse(sortController.text.trim()) ?? 0;

                    if (title.isEmpty || slug.isEmpty) {
                      _showMessage('Vui lòng nhập tên và slug');
                      return;
                    }

                    try {
                      final body = {
                        'title': title,
                        'slug': slug,
                        'icon': selectedIcon,
                        'sortOrder': sortOrder,
                        'isActive': isActive,
                      };

                      if (isEdit) {
                        await pb
                            .collection('categories')
                            .update(category.id, body: body);
                      } else {
                        await pb.collection('categories').create(body: body);
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      _showMessage(
                        isEdit
                            ? 'Cập nhật danh mục thất bại'
                            : 'Thêm danh mục thất bại',
                      );
                    }
                  },
                  child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    slugController.dispose();
    sortController.dispose();

    if (result == true) {
      await _loadCategories();
      _showMessage(isEdit ? 'Đã cập nhật danh mục' : 'Đã thêm danh mục');
    }
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Xóa danh mục'),
          content: Text('Bạn có chắc muốn xóa "${category.title}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await pb.collection('categories').delete(category.id);
      await _loadCategories();
      _showMessage('Đã xóa danh mục');
    } catch (e) {
      _showMessage(
        'Không thể xóa danh mục. Có thể danh mục đang được sản phẩm sử dụng.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Quản lý danh mục',
      showBack: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF2A39),
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: AppBody(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEF2A39)),
                )
                : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child:
                      _categories.isEmpty
                          ? ListView(
                            children: const [
                              SizedBox(height: 220),
                              Center(child: Text('Chưa có danh mục')),
                            ],
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                            itemCount: _categories.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final category = _categories[index];
                              return _CategoryCard(
                                category: category,
                                icon: _getIcon(category.icon),
                                onEdit: () => _openForm(category: category),
                                onDelete: () => _confirmDelete(category),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.isActive ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEF2A39).withValues(alpha: 0.1),
            child: Icon(icon, color: const Color(0xFFEF2A39)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'slug: ${category.slug} • sort: ${category.sortOrder}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  category.isActive ? 'Đang hoạt động' : 'Đã ẩn',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.indigo),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
