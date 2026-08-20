// FILE HỌC TẬP: lib/features/manager/app/screens/manager_products_page.dart
// Vai trò: Màn hình Manager App quản lý sản phẩm.
// Luồng sử dụng: Hiển thị nghiệp vụ quản lý trên ứng dụng và gọi Provider/Service tương ứng.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/product_form_page.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';

// Lớp ManagerProductsPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerProductsPage extends StatefulWidget {
  // Khởi tạo ManagerProductsPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý sản phẩm.
  const ManagerProductsPage({super.key});

  // Tạo state (createState): liên kết ManagerProductsPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<ManagerProductsPage> createState() => _ManagerProductsPageState();
}

// Lớp _ManagerProductsPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _ManagerProductsPageState extends State<ManagerProductsPage> {
  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductProvider>().loadInitialData();
    });
  }

  // =========================================================
  // REFRESH
  // =========================================================

  // Làm mới dữ liệu (_refreshData): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<void> _refreshData() async {
    await context.read<ProductProvider>().loadInitialData();
  }

  // =========================================================
  // CREATE PRODUCT
  // =========================================================

  // Mở create trang (_openCreatePage): điều hướng hoặc hiển thị thành phần tương ứng từ thao tác người dùng.
  Future<void> _openCreatePage() async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    );

    if (result != true || !mounted) return;
    await context.read<ProductProvider>().loadProducts();
  }

  // =========================================================
  // EDIT PRODUCT
  // =========================================================

  // Mở chỉnh sửa trang (_openEditPage): điều hướng hoặc hiển thị thành phần tương ứng từ thao tác người dùng.
  Future<void> _openEditPage(ProductModel product) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );

    if (result != true || !mounted) return;
    await context.read<ProductProvider>().loadProducts();
  }

  // =========================================================
  // DELETE PRODUCT
  // =========================================================

  // Xác nhận xóa (_confirmDelete): hiển thị cảnh báo trước khi xóa dữ liệu.
  Future<void> _confirmDelete(ProductModel product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Xóa sản phẩm'),
          content: Text(
            'Bạn có chắc muốn xóa '
            '"${product.title}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    final bool success = await context.read<ProductProvider>().deleteProduct(
      product.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã xóa sản phẩm' : 'Xóa sản phẩm thất bại'),
      ),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  // Tạo giao diện nội dung (_buildBody): dựng widget con từ dữ liệu hiện tại.
  Widget _buildBody(ProductProvider provider) {
    if (provider.isLoading && provider.products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFEF2A39)),
      );
    }

    if (provider.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          children: const [
            SizedBox(height: 220),
            Center(child: Text('Chưa có sản phẩm')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: provider.products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ProductModel product = provider.products[index];

          return _ProductCard(
            product: product,
            categoryTitle:
                product.categoryTitle.trim().isEmpty
                    ? 'Khác'
                    : product.categoryTitle,
            onEdit: () => _openEditPage(product),
            onDelete: () => _confirmDelete(product),
          );
        },
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  // Xây dựng giao diện (build): dựng cây widget của _ManagerProductsPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final ProductProvider provider = context.watch<ProductProvider>();

    return AppLayout(
      title: 'Quản lý sản phẩm',
      showBack: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF2A39),
        onPressed: _openCreatePage,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: AppBody(child: _buildBody(provider)),
    );
  }
}

// ===========================================================
// PRODUCT CARD
// ===========================================================

// Lớp _ProductCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _ProductCard extends StatelessWidget {
  final ProductModel product;

  final String categoryTitle;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Khởi tạo _ProductCard: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý sản phẩm.
  const _ProductCard({
    required this.product,
    required this.categoryTitle,
    required this.onEdit,
    required this.onDelete,
  });

  // =========================================================
  // FORMAT PRICE
  // =========================================================

  // Định dạng price (_formatPrice): chuyển dữ liệu thô thành giá trị dễ đọc để hiển thị.
  String _formatPrice(double price) {
    final String value = price.round().toString();

    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);

      final int remaining = value.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '$bufferđ';
  }

  // =========================================================
  // PRICE UI
  // =========================================================

  // Tạo giao diện price (_buildPrice): dựng widget con từ dữ liệu hiện tại.
  Widget _buildPrice() {
    if (!product.hasActiveSale) {
      return Text(
        _formatPrice(product.price),
        style: const TextStyle(
          color: Color(0xFFEF2A39),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _formatPrice(product.effectivePrice),
                style: const TextStyle(
                  color: Color(0xFFEF2A39),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF2A39),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '-${product.discountPercent}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        Text(
          _formatPrice(product.price),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  // Xây dựng giao diện (build): dựng cây widget của _ProductCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.sizeOf(context).width < 380;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
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
          // ===============================================
          // IMAGE
          // ===============================================
          _ProductImage(
            imageUrl: product.image,
            size: isSmall ? 72 : 84,
            discountPercent:
                product.hasActiveSale ? product.discountPercent : null,
          ),

          const SizedBox(width: 12),

          // ===============================================
          // INFORMATION
          // ===============================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 4),

                Text(categoryTitle, style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 6),

                // =========================
                // PRICE
                // =========================
                _buildPrice(),

                const SizedBox(height: 7),

                // =========================
                // SALE STATUS
                // =========================
                if (product.hasActiveSale) ...[
                  const _SaleChip(),

                  const SizedBox(height: 6),
                ],

                // =========================
                // AVAILABILITY
                // =========================
                _StatusChip(isAvailable: product.isAvailable),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ===============================================
          // ACTION
          // ===============================================
          Column(
            children: [
              _CircleIconButton(
                icon: Icons.edit,
                color: Colors.indigo,
                onTap: onEdit,
              ),

              const SizedBox(height: 8),

              _CircleIconButton(
                icon: Icons.delete,
                color: Colors.red,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// PRODUCT IMAGE
// ===========================================================

// Lớp _ProductImage: thành phần phục vụ màn hình manager app quản lý sản phẩm.
class _ProductImage extends StatelessWidget {
  final String imageUrl;

  final double size;

  final int? discountPercent;

  // Khởi tạo _ProductImage: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý sản phẩm.
  const _ProductImage({
    required this.imageUrl,
    required this.size,
    this.discountPercent,
  });

  // Xây dựng giao diện (build): dựng cây widget của _ProductImage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  imageUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const Icon(Icons.fastfood_rounded),
                        ),
                      )
                      : const Icon(Icons.fastfood_rounded),
            ),
          ),

          if (discountPercent != null)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF2A39),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-$discountPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================
// SALE CHIP
// ===========================================================

// Lớp _SaleChip: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _SaleChip extends StatelessWidget {
  // Khởi tạo _SaleChip: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý sản phẩm.
  const _SaleChip();

  // Xây dựng giao diện (build): dựng cây widget của _SaleChip từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 13, color: Color(0xFFF57C00)),

          SizedBox(width: 4),

          Text(
            'Đang khuyến mãi',
            style: TextStyle(
              color: Color(0xFFF57C00),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// AVAILABILITY STATUS
// ===========================================================

// Lớp _StatusChip: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _StatusChip extends StatelessWidget {
  final bool isAvailable;

  // Khởi tạo _StatusChip: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý sản phẩm.
  const _StatusChip({required this.isAvailable});

  // Xây dựng giao diện (build): dựng cây widget của _StatusChip từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final Color color = isAvailable ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isAvailable ? 'Đang bán' : 'Ngừng bán',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

// ===========================================================
// ACTION BUTTON
// ===========================================================

// Lớp _CircleIconButton: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  // Khởi tạo _CircleIconButton: nhận các tham số cần thiết để tạo đối tượng cho màn hình manager app quản lý sản phẩm.
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  // Xây dựng giao diện (build): dựng cây widget của _CircleIconButton từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
