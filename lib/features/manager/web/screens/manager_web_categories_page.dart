import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/category_model.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

class ManagerWebCategoriesPage extends StatefulWidget {
  const ManagerWebCategoriesPage({super.key});

  @override
  State<ManagerWebCategoriesPage> createState() =>
      _ManagerWebCategoriesPageState();
}

class _ManagerWebCategoriesPageState extends State<ManagerWebCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<CategoryModel> _categories = [];

  bool _isLoading = false;
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitialData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
    ]);
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final records = await pb
          .collection('categories')
          .getFullList(sort: 'sortOrder');

      final loadedCategories =
          records.map((record) {
              return CategoryModel.fromJson({
                'id': record.id,
                ...record.data,
                'created': record.created,
                'updated': record.updated,
              });
            }).toList()
            ..sort(
              (first, second) => first.sortOrder.compareTo(second.sortOrder),
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _categories
          ..clear()
          ..addAll(loadedCategories);

        final totalPages =
            math
                .max(1, (_filteredCategories.length / _rowsPerPage).ceil())
                .toInt();

        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }
      });
    } catch (_) {
      _showMessage('Không tải được danh mục');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<CategoryModel> get _filteredCategories {
    final query = _searchController.text.trim().toLowerCase();

    return _categories.where((category) {
        final matchesQuery =
            query.isEmpty ||
            category.title.toLowerCase().contains(query) ||
            category.slug.toLowerCase().contains(query);

        final matchesStatus =
            _selectedStatus == 'Tất cả' ||
            (_selectedStatus == 'Đang hoạt động' && category.isActive) ||
            (_selectedStatus == 'Đã ẩn' && !category.isActive);

        return matchesQuery && matchesStatus;
      }).toList()
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
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

  String _getIconLabel(String icon) {
    switch (icon) {
      case 'restaurant':
        return 'Món ăn';
      case 'local_drink':
        return 'Nước uống';
      case 'fastfood':
        return 'Combo / Fastfood';
      case 'bakery_dining':
        return 'Bánh';
      case 'icecream':
        return 'Tráng miệng';
      case 'ramen_dining':
        return 'Mì / bún';
      default:
        return 'Danh mục';
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
    if (!mounted) {
      return;
    }

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
    bool isSaving = false;
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveCategory() async {
              final title = titleController.text.trim();
              final slug = slugController.text.trim();
              final sortOrder = int.tryParse(sortController.text.trim()) ?? 0;

              if (title.isEmpty || slug.isEmpty) {
                _showMessage('Vui lòng nhập tên và slug');
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

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
              } catch (_) {
                _showMessage(
                  isEdit
                      ? 'Cập nhật danh mục thất bại'
                      : 'Thêm danh mục thất bại',
                );

                if (dialogContext.mounted) {
                  setDialogState(() {
                    isSaving = false;
                  });
                }
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 640,
                  maxHeight: 760,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_rounded : Icons.add_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit
                                      ? 'Chỉnh sửa danh mục'
                                      : 'Thêm danh mục',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isEdit
                                      ? 'Cập nhật thông tin danh mục hiện tại'
                                      : 'Tạo nhóm sản phẩm mới cho hệ thống',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed:
                                isSaving
                                    ? null
                                    : () {
                                      Navigator.pop(dialogContext, false);
                                    },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 520;
                            final fieldWidth =
                                twoColumns
                                    ? (constraints.maxWidth - 14) / 2
                                    : constraints.maxWidth;

                            return Wrap(
                              spacing: 14,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: fieldWidth,
                                  child: TextField(
                                    controller: titleController,
                                    enabled: !isSaving,
                                    decoration: _inputDecoration(
                                      label: 'Tên danh mục',
                                      icon: Icons.title_rounded,
                                    ),
                                    onChanged: (value) {
                                      if (!isEdit) {
                                        slugController.text = _makeSlug(value);
                                        setDialogState(() {});
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: TextField(
                                    controller: slugController,
                                    enabled: !isSaving,
                                    decoration: _inputDecoration(
                                      label: 'Slug',
                                      icon: Icons.link_rounded,
                                      hint: 'vd: food, drink, combos',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: TextField(
                                    controller: sortController,
                                    enabled: !isSaving,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      label: 'Thứ tự hiển thị',
                                      icon: Icons.format_list_numbered_rounded,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: DropdownButtonFormField<String>(
                                    value: selectedIcon,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      label: 'Biểu tượng',
                                      icon: Icons.emoji_symbols_rounded,
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
                                    onChanged:
                                        isSaving
                                            ? null
                                            : (value) {
                                              if (value == null) {
                                                return;
                                              }

                                              setDialogState(() {
                                                selectedIcon = value;
                                              });
                                            },
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundSecondary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text(
                                        'Danh mục đang hoạt động',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Danh mục hoạt động sẽ được hiển thị cho khách hàng.',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: isActive,
                                      activeColor: Colors.white,
                                      activeTrackColor: AppColors.success,
                                      onChanged:
                                          isSaving
                                              ? null
                                              : (value) {
                                                setDialogState(() {
                                                  isActive = value;
                                                });
                                              },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed:
                                isSaving
                                    ? null
                                    : () {
                                      Navigator.pop(dialogContext, false);
                                    },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: isSaving ? null : saveCategory,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon:
                                isSaving
                                    ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Icon(
                                      isEdit
                                          ? Icons.save_rounded
                                          : Icons.add_rounded,
                                      size: 18,
                                    ),
                            label: Text(isEdit ? 'Cập nhật' : 'Thêm danh mục'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Xóa danh mục',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${category.title}" không? '
            'Danh mục đang được sản phẩm sử dụng có thể không xóa được.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Xóa danh mục'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await pb.collection('categories').delete(category.id);
      await _loadCategories();
      _showMessage('Đã xóa danh mục');
    } catch (_) {
      _showMessage(
        'Không thể xóa danh mục. Có thể danh mục đang được sản phẩm sử dụng.',
      );
    }
  }

  void _logout() {
    pb.authStore.clear();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';
    final avatarUrl = profile?.avatarUrl ?? '';

    final filteredCategories = _filteredCategories;
    final totalPages =
        math.max(1, (filteredCategories.length / _rowsPerPage).ceil()).toInt();

    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex =
        math.min(startIndex + _rowsPerPage, filteredCategories.length).toInt();

    final visibleCategories =
        filteredCategories.isEmpty
            ? <CategoryModel>[]
            : filteredCategories.sublist(startIndex, endIndex);

    return ManagerWebLayout(
      title: 'Quản lý danh mục',
      currentRoute: AppRoutes.managerCategories,
      managerName: managerName,
      avatarUrl: avatarUrl,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          onPressed: _loadInitialData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton:
          MediaQuery.sizeOf(context).width < 720
              ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () {
                  _openForm();
                },
                child: const Icon(Icons.add_rounded),
              )
              : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth >= 1100
                  ? 24.0
                  : constraints.maxWidth >= 700
                  ? 18.0
                  : 12.0;

          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoriesSummary(
                        totalCategories: _categories.length,
                        activeCategories:
                            _categories
                                .where((category) => category.isActive)
                                .length,
                        hiddenCategories:
                            _categories
                                .where((category) => !category.isActive)
                                .length,
                      ),
                      const SizedBox(height: 18),
                      _CategoryToolbar(
                        searchController: _searchController,
                        selectedStatus: _selectedStatus,
                        onSearchChanged: (_) {
                          setState(() {
                            _currentPage = 1;
                          });
                        },
                        onStatusChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedStatus = value;
                            _currentPage = 1;
                          });
                        },
                        onReset: () {
                          _searchController.clear();

                          setState(() {
                            _selectedStatus = 'Tất cả';
                            _currentPage = 1;
                          });
                        },
                        onCreate: () {
                          _openForm();
                        },
                      ),
                      const SizedBox(height: 14),
                      _CategoriesPanel(
                        isLoading: _isLoading && _categories.isEmpty,
                        categories: visibleCategories,
                        filteredCount: filteredCategories.length,
                        startIndex: startIndex,
                        getIcon: _getIcon,
                        getIconLabel: _getIconLabel,
                        onEdit: (category) {
                          _openForm(category: category);
                        },
                        onDelete: _confirmDelete,
                      ),
                      if (!_isLoading && filteredCategories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _PaginationBar(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          rowsPerPage: _rowsPerPage,
                          totalItems: filteredCategories.length,
                          startIndex: startIndex,
                          endIndex: endIndex,
                          onRowsPerPageChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _rowsPerPage = value;
                              _currentPage = 1;
                            });
                          },
                          onPrevious:
                              _currentPage > 1
                                  ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                  : null,
                          onNext:
                              _currentPage < totalPages
                                  ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                  : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoriesSummary extends StatelessWidget {
  final int totalCategories;
  final int activeCategories;
  final int hiddenCategories;

  const _CategoriesSummary({
    required this.totalCategories,
    required this.activeCategories,
    required this.hiddenCategories,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryCard(
        title: 'Tổng danh mục',
        value: '$totalCategories',
        icon: Icons.category_rounded,
        color: AppColors.primary,
      ),
      _SummaryCard(
        title: 'Đang hoạt động',
        value: '$activeCategories',
        icon: Icons.visibility_rounded,
        color: AppColors.success,
      ),
      _SummaryCard(
        title: 'Đã ẩn',
        value: '$hiddenCategories',
        icon: Icons.visibility_off_rounded,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 950) {
          columns = 3;
        } else if (constraints.maxWidth >= 560) {
          columns = 2;
        }

        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              items
                  .map((item) => SizedBox(width: itemWidth, child: item))
                  .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onReset;
  final VoidCallback onCreate;

  const _CategoryToolbar({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onReset,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final isMedium = constraints.maxWidth >= 620;

          final searchWidth =
              isWide
                  ? math.max(320.0, constraints.maxWidth - 570).toDouble()
                  : constraints.maxWidth;

          final secondaryWidth =
              isWide
                  ? 190.0
                  : isMedium
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc slug danh mục',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                              tooltip: 'Xóa từ khóa',
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                            : null,
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: secondaryWidth,
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    prefixIcon: const Icon(Icons.visibility_outlined),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                    DropdownMenuItem(
                      value: 'Đang hoạt động',
                      child: Text('Đang hoạt động'),
                    ),
                    DropdownMenuItem(value: 'Đã ẩn', child: Text('Đã ẩn')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: isWide ? 125 : secondaryWidth,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Đặt lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? 175 : secondaryWidth,
                height: 55,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm danh mục'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoriesPanel extends StatelessWidget {
  final bool isLoading;
  final List<CategoryModel> categories;
  final int filteredCount;
  final int startIndex;
  final IconData Function(String) getIcon;
  final String Function(String) getIconLabel;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;

  const _CategoriesPanel({
    required this.isLoading,
    required this.categories,
    required this.filteredCount,
    required this.startIndex,
    required this.getIcon,
    required this.getIconLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách danh mục',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$filteredCount danh mục',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (isLoading)
            const SizedBox(
              height: 340,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (categories.isEmpty)
            const SizedBox(height: 340, child: _EmptyCategories())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return _CategoryCards(
                    categories: categories,
                    getIcon: getIcon,
                    getIconLabel: getIconLabel,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  );
                }

                return _CategoryTable(
                  categories: categories,
                  startIndex: startIndex,
                  getIcon: getIcon,
                  getIconLabel: getIconLabel,
                  onEdit: onEdit,
                  onDelete: onDelete,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  final List<CategoryModel> categories;
  final int startIndex;
  final IconData Function(String) getIcon;
  final String Function(String) getIconLabel;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;

  const _CategoryTable({
    required this.categories,
    required this.startIndex,
    required this.getIcon,
    required this.getIconLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AppColors.backgroundSecondary.withOpacity(0.78),
            ),
            headingTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            dataTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            dividerThickness: 0.8,
            horizontalMargin: 20,
            columnSpacing: 28,
            columns: const [
              DataColumn(label: Text('STT')),
              DataColumn(label: Text('DANH MỤC')),
              DataColumn(label: Text('SLUG')),
              DataColumn(label: Text('THỨ TỰ')),
              DataColumn(label: Text('TRẠNG THÁI')),
              DataColumn(label: Text('THAO TÁC')),
            ],
            rows: List.generate(categories.length, (index) {
              final category = categories[index];

              return DataRow(
                cells: [
                  DataCell(Text('${startIndex + index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          _CategoryIcon(icon: getIcon(category.icon)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  getIconLabel(category.icon),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        category.slug,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${category.sortOrder}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  DataCell(_StatusChip(isActive: category.isActive)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          tooltip: 'Chỉnh sửa',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF4F46E5),
                          onTap: () {
                            onEdit(category);
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          tooltip: 'Xóa',
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red,
                          onTap: () {
                            onDelete(category);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CategoryCards extends StatelessWidget {
  final List<CategoryModel> categories;
  final IconData Function(String) getIcon;
  final String Function(String) getIconLabel;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;

  const _CategoryCards({
    required this.categories,
    required this.getIcon,
    required this.getIconLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 2 : 1;
          const spacing = 11.0;
          final cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children:
                categories.map((category) {
                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _CategoryIcon(icon: getIcon(category.icon)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.slug,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${getIconLabel(category.icon)} • thứ tự ${category.sortOrder}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                _StatusChip(isActive: category.isActive),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              _ActionButton(
                                tooltip: 'Chỉnh sửa',
                                icon: Icons.edit_rounded,
                                color: const Color(0xFF4F46E5),
                                onTap: () {
                                  onEdit(category);
                                },
                              ),
                              const SizedBox(height: 8),
                              _ActionButton(
                                tooltip: 'Xóa',
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red,
                                onTap: () {
                                  onDelete(category);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;

  const _CategoryIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: AppColors.primary, size: 25),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isActive ? 'Đang hoạt động' : 'Đã ẩn',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: color, size: 19),
          ),
        ),
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, color: AppColors.textGrey, size: 58),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy danh mục',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hãy thay đổi từ khóa hoặc trạng thái đang lọc.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final int totalItems;
  final int startIndex;
  final int endIndex;
  final ValueChanged<int?> onRowsPerPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.totalItems,
    required this.startIndex,
    required this.endIndex,
    required this.onRowsPerPageChanged,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          Text(
            'Hiển thị ${startIndex + 1}–$endIndex trong $totalItems danh mục',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Số dòng:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: rowsPerPage,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5')),
                  DropdownMenuItem(value: 8, child: Text('8')),
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                ],
                onChanged: onRowsPerPageChanged,
              ),
              const SizedBox(width: 14),
              Text(
                'Trang $currentPage/$totalPages',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Trang trước',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
