// FILE HỌC TẬP: lib/features/notification/manager_notifications_page.dart
// Vai trò: Màn hình quản lý thông báo.
// Luồng sử dụng: Tải, hiển thị và cập nhật trạng thái thông báo theo vai trò người dùng.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/notification_provider.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';

// Lớp ManagerNotificationsPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerNotificationsPage extends StatefulWidget {
  // Khởi tạo ManagerNotificationsPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình quản lý thông báo.
  const ManagerNotificationsPage({super.key});

  // Tạo state (createState): liên kết ManagerNotificationsPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<ManagerNotificationsPage> createState() =>
      _ManagerNotificationsPageState();
}

// Lớp _ManagerNotificationsPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _ManagerNotificationsPageState extends State<ManagerNotificationsPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  String selectedType = 'promotion';
  String? selectedProductId;
  bool isLoading = false;

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final productProvider = context.read<ProductProvider>();
      if (productProvider.products.isEmpty) {
        productProvider.loadProducts();
      }
    });
  }

  // Giải phóng tài nguyên (dispose): hủy controller/listener khi widget bị loại khỏi cây giao diện.
  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  // Hiển thị tin nhắn (_showMessage): mở thông báo/dialog hoặc thành phần hỗ trợ trên giao diện.
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Xử lý _findSelectedProduct: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  ProductModel? _findSelectedProduct(List<ProductModel> products) {
    if (selectedProductId == null || selectedProductId!.isEmpty) return null;

    try {
      return products.firstWhere((product) => product.id == selectedProductId);
    } catch (_) {
      return null;
    }
  }

  // Xử lý _onTypeChanged: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  void _onTypeChanged(String? value) {
    if (value == null) return;

    setState(() {
      selectedType = value;

      if (selectedType != 'new_product') {
        selectedProductId = null;
      }
    });
  }

  // Xử lý _onProductChanged: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  void _onProductChanged(String? productId, List<ProductModel> products) {
    setState(() {
      selectedProductId = productId;
    });

    final product = _findSelectedProduct(products);
    if (product == null) return;

    if (titleController.text.trim().isEmpty ||
        titleController.text.trim() == 'Sản phẩm mới') {
      titleController.text = 'Sản phẩm mới: ${product.title}';
    }

    if (contentController.text.trim().isEmpty) {
      final priceText = _formatMoney(product.price);
      contentController.text =
          '${product.title} vừa được thêm vào thực đơn. Giá chỉ $priceText. Đặt món ngay hôm nay nhé!';
    }
  }

  // Xử lý submit: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  Future<void> submit() async {
    final title = titleController.text.trim();
    final body = contentController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (selectedType == 'new_product' &&
        (selectedProductId == null || selectedProductId!.isEmpty)) {
      _showMessage('Vui lòng chọn sản phẩm mới');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await context
          .read<NotificationProvider>()
          .createCustomerNotification(
            title: title,
            body: body,
            type: selectedType,
          );

      if (!mounted) return;

      if (!success) {
        _showMessage('Gửi thông báo thất bại');
        return;
      }

      titleController.clear();
      contentController.clear();

      setState(() {
        selectedType = 'promotion';
        selectedProductId = null;
      });

      _showMessage('Đã gửi thông báo thành công');
    } catch (e) {
      debugPrint('create notification error: $e');
      _showMessage('Gửi thông báo thất bại');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Xử lý _decoration: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.4),
      ),
    );
  }

  // Xử lý _typeLabel: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  String _typeLabel(String type) {
    switch (type) {
      case 'promotion':
        return 'Khuyến mãi';
      case 'new_product':
        return 'Sản phẩm mới';
      case 'general':
        return 'Thông báo chung';
      default:
        return 'Thông báo';
    }
  }

  // Xử lý _typeIcon: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  IconData _typeIcon(String type) {
    switch (type) {
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'new_product':
        return Icons.fastfood_rounded;
      case 'general':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  // Xử lý _typeColor: thực hiện phần nghiệp vụ tương ứng trong màn hình quản lý thông báo.
  Color _typeColor(String type) {
    switch (type) {
      case 'promotion':
        return const Color(0xFFF97316);
      case 'new_product':
        return const Color(0xFF22C55E);
      case 'general':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  // Định dạng tiền (_formatMoney): chuyển dữ liệu thô thành giá trị dễ đọc để hiển thị.
  String _formatMoney(double value) {
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final position = text.length - i;
      buffer.write(text[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()}đ';
  }

  // Tạo giao diện xem trước thẻ (_buildPreviewCard): dựng widget con từ dữ liệu hiện tại.
  Widget _buildPreviewCard(ProductModel? selectedProduct) {
    final title =
        titleController.text.trim().isEmpty
            ? 'Tiêu đề thông báo'
            : titleController.text.trim();

    final body =
        contentController.text.trim().isEmpty
            ? 'Nội dung thông báo sẽ hiển thị tại đây.'
            : contentController.text.trim();

    final color = _typeColor(selectedType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_typeIcon(selectedType), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(selectedType),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(body),
                if (selectedProduct != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${selectedProduct.title} • ${_formatMoney(selectedProduct.price)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tạo giao diện sản phẩm picker (_buildProductPicker): dựng widget con từ dữ liệu hiện tại.
  Widget _buildProductPicker(List<ProductModel> products) {
    if (selectedType != 'new_product') return const SizedBox.shrink();

    final availableProducts =
        products.where((item) => item.isAvailable).toList();

    if (availableProducts.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: const Text(
          'Chưa có sản phẩm khả dụng để chọn. Hãy kiểm tra lại danh sách sản phẩm.',
          style: TextStyle(
            color: Color(0xFF9A3412),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedProductId,
        isExpanded: true,
        decoration: _decoration(
          label: 'Chọn sản phẩm mới',
          icon: Icons.fastfood_rounded,
        ),
        items:
            availableProducts.map((product) {
              return DropdownMenuItem(
                value: product.id,
                child: Text(
                  '${product.title} • ${_formatMoney(product.price)}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged:
            isLoading
                ? null
                : (value) => _onProductChanged(value, availableProducts),
      ),
    );
  }

  // Tạo giao diện biểu mẫu (_buildForm): dựng widget con từ dữ liệu hiện tại.
  Widget _buildForm() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final selectedProduct = _findSelectedProduct(productProvider.products);

        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 700 ? 24.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      titleController,
                      contentController,
                    ]),
                    builder: (_, __) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Xem trước thông báo',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (productProvider.isLoading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPreviewCard(selectedProduct),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Trang này chỉ dùng để gửi khuyến mãi, '
                                    'sản phẩm mới và thông báo chung. '
                                    'Thông báo trạng thái đơn hàng được hệ thống '
                                    'tự tạo khi Manager xử lý đơn.',
                                    style: TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: _decoration(
                              label: 'Loại thông báo',
                              icon: Icons.category_rounded,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'promotion',
                                child: Text('Khuyến mãi'),
                              ),
                              DropdownMenuItem(
                                value: 'new_product',
                                child: Text('Sản phẩm mới'),
                              ),
                              DropdownMenuItem(
                                value: 'general',
                                child: Text('Thông báo chung'),
                              ),
                            ],
                            onChanged: isLoading ? null : _onTypeChanged,
                          ),

                          _buildProductPicker(productProvider.products),
                          const SizedBox(height: 12),

                          TextField(
                            controller: titleController,
                            enabled: !isLoading,
                            decoration: _decoration(
                              label: 'Tiêu đề',
                              icon: Icons.title_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: contentController,
                            maxLines: 4,
                            enabled: !isLoading,
                            decoration: _decoration(
                              label: 'Nội dung',
                              icon: Icons.notes_rounded,
                            ),
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : submit,
                              icon:
                                  isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.send_rounded),
                              label: Text(
                                isLoading ? 'Đang gửi...' : 'Gửi thông báo',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Xây dựng giao diện (build): dựng cây widget của _ManagerNotificationsPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Tạo thông báo',
      showBack: true,
      child: AppBody(child: _buildForm()),
    );
  }
}
