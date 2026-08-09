import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_product_form_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';


bool _hasActivePromotion(ProductModel product) {
  if (!product.isOnSale) return false;

  if (product.price <= 0 ||
      product.salePrice <= 0 ||
      product.salePrice >= product.price) {
    return false;
  }

  final now = DateTime.now();
  final start = product.saleStartAt?.toLocal();
  final end = product.saleEndAt?.toLocal();

  if (start != null && now.isBefore(start)) return false;
  if (end != null && now.isAfter(end)) return false;

  return true;
}

int _discountPercent(ProductModel product) {
  if (!_hasActivePromotion(product) || product.price <= 0) return 0;
  return (((product.price - product.salePrice) / product.price) * 100).round();
}

class ManagerWebProductsPage extends StatefulWidget {
  const ManagerWebProductsPage({super.key});

  @override
  State<ManagerWebProductsPage> createState() => _ManagerWebProductsPageState();
}

class _ManagerWebProductsPageState extends State<ManagerWebProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<ProductProvider>().loadInitialData(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
    ]);
  }

  String _formatPrice(double price) {
    final value = price.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      final remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer}đ';
  }

  List<String> _getCategories(List<ProductModel> products) {
    final categories =
        products
            .map(
              (product) =>
                  product.categoryTitle.trim().isEmpty
                      ? 'Khác'
                      : product.categoryTitle.trim(),
            )
            .toSet()
            .toList()
          ..sort();

    return ['Tất cả', ...categories];
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    final query = _searchController.text.trim().toLowerCase();

    return products.where((product) {
      final category =
          product.categoryTitle.trim().isEmpty
              ? 'Khác'
              : product.categoryTitle.trim();

      final matchesQuery =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'Tất cả' || category == _selectedCategory;

      final matchesStatus =
          _selectedStatus == 'Tất cả' ||
          (_selectedStatus == 'Đang bán' && product.isAvailable) ||
          (_selectedStatus == 'Đang khuyến mãi' &&
              product.isAvailable &&
              _hasActivePromotion(product)) ||
          (_selectedStatus == 'Ngừng bán' && !product.isAvailable);

      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();
  }

  void _resetToFirstPage() {
    if (_currentPage != 1) {
      setState(() {
        _currentPage = 1;
      });
    }
  }

  Future<void> _openCreatePage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ManagerWebProductFormPage()),
    );

    if (result == true && mounted) {
      await context.read<ProductProvider>().loadProducts();
    }
  }

  Future<void> _openEditPage(ProductModel product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerWebProductFormPage(product: product),
      ),
    );

    if (result == true && mounted) {
      await context.read<ProductProvider>().loadProducts();
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Xóa sản phẩm',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Bạn có chắc muốn xóa "${product.title}" không? '
            'Thao tác này không thể hoàn tác.',
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
              label: const Text('Xóa sản phẩm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await context.read<ProductProvider>().deleteProduct(
      product.id,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã xóa sản phẩm' : 'Xóa sản phẩm thất bại'),
      ),
    );
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
    final provider = context.watch<ProductProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';
    final avatarUrl = profile?.avatarUrl ?? '';

    final categories = _getCategories(provider.products);
    final filteredProducts = _filterProducts(provider.products);

    final totalPages =
        math.max(1, (filteredProducts.length / _rowsPerPage).ceil()).toInt();

    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex =
        math.min(startIndex + _rowsPerPage, filteredProducts.length).toInt();

    final visibleProducts =
        filteredProducts.isEmpty
            ? <ProductModel>[]
            : filteredProducts.sublist(startIndex, endIndex);

    return ManagerWebLayout(
      title: 'Quản lý sản phẩm',
      currentRoute: AppRoutes.managerProducts,
      managerName: managerName,
      avatarUrl: avatarUrl,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton:
          MediaQuery.sizeOf(context).width < 720
              ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _openCreatePage,
                child: const Icon(Icons.add_rounded),
              )
              : null,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductsSummary(
                    totalProducts: provider.products.length,
                    availableProducts:
                        provider.products
                            .where((product) => product.isAvailable)
                            .length,
                    promotionProducts:
                        provider.products
                            .where(
                              (product) =>
                                  product.isAvailable &&
                                  _hasActivePromotion(product),
                            )
                            .length,
                    unavailableProducts:
                        provider.products
                            .where((product) => !product.isAvailable)
                            .length,
                  ),
                  const SizedBox(height: 20),
                  _Toolbar(
                    searchController: _searchController,
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    selectedStatus: _selectedStatus,
                    onSearchChanged: (_) {
                      setState(() {
                        _currentPage = 1;
                      });
                    },
                    onCategoryChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedCategory = value;
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
                        _selectedCategory = 'Tất cả';
                        _selectedStatus = 'Tất cả';
                        _currentPage = 1;
                      });
                    },
                    onCreate: _openCreatePage,
                  ),
                  const SizedBox(height: 16),
                  _ProductsPanel(
                    isLoading: provider.isLoading && provider.products.isEmpty,
                    products: visibleProducts,
                    filteredCount: filteredProducts.length,
                    startIndex: startIndex,
                    formatPrice: _formatPrice,
                    onEdit: _openEditPage,
                    onDelete: _confirmDelete,
                  ),
                  if (!provider.isLoading && filteredProducts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _PaginationBar(
                      currentPage: _currentPage,
                      totalPages: totalPages,
                      rowsPerPage: _rowsPerPage,
                      totalItems: filteredProducts.length,
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
      ),
    );
  }
}

class _ProductsSummary extends StatelessWidget {
  final int totalProducts;
  final int availableProducts;
  final int promotionProducts;
  final int unavailableProducts;

  const _ProductsSummary({
    required this.totalProducts,
    required this.availableProducts,
    required this.promotionProducts,
    required this.unavailableProducts,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final items = [
          _SummaryItem(
            title: 'Tổng sản phẩm',
            value: '$totalProducts',
            icon: Icons.inventory_2_rounded,
            color: AppColors.primary,
          ),
          _SummaryItem(
            title: 'Đang bán',
            value: '$availableProducts',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          _SummaryItem(
            title: 'Đang khuyến mãi',
            value: '$promotionProducts',
            icon: Icons.local_offer_rounded,
            color: const Color(0xFFEF4444),
          ),
          _SummaryItem(
            title: 'Ngừng bán',
            value: '$unavailableProducts',
            icon: Icons.pause_circle_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ];

        if (compact) {
          return Column(
            children:
                items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: item,
                      ),
                    )
                    .toList(),
          );
        }

        return Row(
          children: [
            for (int index = 0; index < items.length; index++) ...[
              Expanded(child: items[index]),
              if (index < items.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
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

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onReset;
  final VoidCallback onCreate;

  const _Toolbar({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onReset,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;

          final searchField = TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên sản phẩm hoặc danh mục',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final categoryField = DropdownButtonFormField<String>(
            value: selectedCategory,
            isExpanded: true,
            decoration: _filterDecoration(
              label: 'Danh mục',
              icon: Icons.category_outlined,
            ),
            items:
                categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged: onCategoryChanged,
          );

          final statusField = DropdownButtonFormField<String>(
            value: selectedStatus,
            isExpanded: true,
            decoration: _filterDecoration(
              label: 'Trạng thái',
              icon: Icons.toggle_on_outlined,
            ),
            items: const [
              DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
              DropdownMenuItem(value: 'Đang bán', child: Text('Đang bán')),
              DropdownMenuItem(
                value: 'Đang khuyến mãi',
                child: Text('Đang khuyến mãi'),
              ),
              DropdownMenuItem(value: 'Ngừng bán', child: Text('Ngừng bán')),
            ],
            onChanged: onStatusChanged,
          );

          final resetButton = OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Đặt lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          final createButton = FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm sản phẩm'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (desktop) {
            return Row(
              children: [
                Expanded(flex: 4, child: searchField),
                const SizedBox(width: 12),
                SizedBox(width: 210, child: categoryField),
                const SizedBox(width: 12),
                SizedBox(width: 180, child: statusField),
                const SizedBox(width: 12),
                resetButton,
                const SizedBox(width: 10),
                createButton,
              ],
            );
          }

          return Column(
            children: [
              searchField,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: categoryField),
                  const SizedBox(width: 10),
                  Expanded(child: statusField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: resetButton),
                  const SizedBox(width: 10),
                  Expanded(child: createButton),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _filterDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _ProductsPanel extends StatelessWidget {
  final bool isLoading;
  final List<ProductModel> products;
  final int filteredCount;
  final int startIndex;
  final String Function(double) formatPrice;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;

  const _ProductsPanel({
    required this.isLoading,
    required this.products,
    required this.filteredCount,
    required this.startIndex,
    required this.formatPrice,
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
                    'Danh sách sản phẩm',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$filteredCount sản phẩm',
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
              height: 360,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (products.isEmpty)
            const SizedBox(height: 360, child: _EmptyProducts())
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return _ProductCards(
                    products: products,
                    formatPrice: formatPrice,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  );
                }

                return _ProductTable(
                  products: products,
                  startIndex: startIndex,
                  formatPrice: formatPrice,
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

class _ProductTable extends StatelessWidget {
  final List<ProductModel> products;
  final int startIndex;
  final String Function(double) formatPrice;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;

  const _ProductTable({
    required this.products,
    required this.startIndex,
    required this.formatPrice,
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
          constraints: const BoxConstraints(minWidth: 930),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              AppColors.backgroundSecondary.withOpacity(0.75),
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
              DataColumn(label: Text('SẢN PHẨM')),
              DataColumn(label: Text('DANH MỤC')),
              DataColumn(label: Text('GIÁ BÁN')),
              DataColumn(label: Text('TRẠNG THÁI')),
              DataColumn(label: Text('THAO TÁC')),
            ],
            rows: List.generate(products.length, (index) {
              final product = products[index];
              final category =
                  product.categoryTitle.trim().isEmpty
                      ? 'Khác'
                      : product.categoryTitle;

              return DataRow(
                cells: [
                  DataCell(Text('${startIndex + index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 280,
                      child: Row(
                        children: [
                          _ProductImage(imageUrl: product.image, size: 54),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    _ProductPrice(
                      product: product,
                      formatPrice: formatPrice,
                    ),
                  ),
                  DataCell(
                    _ProductStatus(
                      product: product,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          tooltip: 'Chỉnh sửa',
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF4F46E5),
                          onTap: () {
                            onEdit(product);
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          tooltip: 'Xóa',
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red,
                          onTap: () {
                            onDelete(product);
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

class _ProductCards extends StatelessWidget {
  final List<ProductModel> products;
  final String Function(double) formatPrice;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;

  const _ProductCards({
    required this.products,
    required this.formatPrice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        final category =
            product.categoryTitle.trim().isEmpty
                ? 'Khác'
                : product.categoryTitle;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _ProductImage(imageUrl: product.image, size: 68),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _ProductPrice(
                      product: product,
                      formatPrice: formatPrice,
                    ),
                    const SizedBox(height: 7),
                    _ProductStatus(product: product),
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
                      onEdit(product);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    tooltip: 'Xóa',
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red,
                    onTap: () {
                      onDelete(product);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _ProductImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.backgroundSecondary,
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood_rounded, color: AppColors.textSecondary),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child:
            imageUrl.trim().isEmpty
                ? placeholder
                : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                ),
      ),
    );
  }
}

class _ProductPrice extends StatelessWidget {
  final ProductModel product;
  final String Function(double) formatPrice;

  const _ProductPrice({
    required this.product,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final activeSale = _hasActivePromotion(product);

    if (!activeSale) {
      return Text(
        formatPrice(product.price),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    final percent = _discountPercent(product);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatPrice(product.salePrice),
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
              ),
            ),
            if (percent > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '-$percent%',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          formatPrice(product.price),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}

class _ProductStatus extends StatelessWidget {
  final ProductModel product;

  const _ProductStatus({required this.product});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      children: [
        _StatusChip(isAvailable: product.isAvailable),
        if (product.isAvailable && _hasActivePromotion(product))
          const _SaleChip(),
      ],
    );
  }
}

class _SaleChip extends StatelessWidget {
  const _SaleChip();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Khuyến mãi',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAvailable;

  const _StatusChip({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.success : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isAvailable ? 'Đang bán' : 'Ngừng bán',
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

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.textGrey, size: 58),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hãy thay đổi từ khóa hoặc bộ lọc đang chọn.',
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
            'Hiển thị ${startIndex + 1}–$endIndex trong $totalItems sản phẩm',
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
              const SizedBox(width: 16),
              Text(
                'Trang $currentPage/$totalPages',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
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
