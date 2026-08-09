import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/app_notification_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/notification_provider.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:provider/provider.dart';

class ManagerWebNotificationsPage extends StatefulWidget {
  const ManagerWebNotificationsPage({super.key});

  @override
  State<ManagerWebNotificationsPage> createState() =>
      _ManagerWebNotificationsPageState();
}

class _ManagerWebNotificationsPageState
    extends State<ManagerWebNotificationsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _selectedType = 'promotion';
  String? _selectedProductId;
  bool _isSubmitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();

    _titleController.addListener(_refreshPreview);
    _contentController.addListener(_refreshPreview);

    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshPreview);
    _contentController.removeListener(_refreshPreview);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    final productProvider = context.read<ProductProvider>();

    await Future.wait([
      productProvider.loadProducts(),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
      context.read<NotificationProvider>().loadManagerNotifications(),
    ]);
  }

  ProductModel? _selectedProduct(List<ProductModel> products) {
    if (_selectedProductId == null || _selectedProductId!.isEmpty) {
      return null;
    }

    final matches =
        products.where((product) => product.id == _selectedProductId).toList();

    return matches.isEmpty ? null : matches.first;
  }

  void _changeType(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedType = value;
      _localError = null;

      if (value != 'new_product') {
        _selectedProductId = null;
      }
    });
  }

  void _selectProduct(String? productId, List<ProductModel> products) {
    setState(() {
      _selectedProductId = productId;
      _localError = null;
    });

    final product = _selectedProduct(products);

    if (product == null) {
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _titleController.text.trim() == 'Sản phẩm mới') {
      _titleController.text = 'Sản phẩm mới: ${product.title}';
    }

    if (_contentController.text.trim().isEmpty) {
      _contentController.text =
          '${product.title} vừa được thêm vào thực đơn YourFood. '
          'Giá ${_formatMoney(product.price)}. '
          'Khám phá và đặt món ngay hôm nay!';
    }
  }

  void _applyTemplate(_NotificationTemplate template) {
    setState(() {
      _selectedType = template.type;
      _selectedProductId = null;
      _localError = null;
    });

    _titleController.text = template.title;
    _contentController.text = template.body;
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();

    setState(() {
      _selectedType = 'promotion';
      _selectedProductId = null;
      _localError = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _contentController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      setState(() {
        _localError = 'Vui lòng nhập đầy đủ tiêu đề và nội dung.';
      });
      return;
    }

    if (_selectedType == 'new_product' &&
        (_selectedProductId == null || _selectedProductId!.isEmpty)) {
      setState(() {
        _localError = 'Vui lòng chọn sản phẩm mới cần giới thiệu.';
      });
      return;
    }

    if (title.length > 120) {
      setState(() {
        _localError = 'Tiêu đề không nên vượt quá 120 ký tự.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    try {
      final provider = context.read<NotificationProvider>();

      final success = await provider.createCustomerNotification(
        title: title,
        body: body,
        type: _selectedType,
      );

      if (!success) {
        throw Exception(provider.errorMessage ?? 'Gửi thông báo thất bại');
      }

      if (!mounted) {
        return;
      }

      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo đến tất cả khách hàng.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _localError = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
    final productProvider = context.watch<ProductProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';

    final avatarUrl = profile?.avatarUrl ?? '';

    final products =
        productProvider.products
            .where((product) => product.isAvailable)
            .toList();

    products.sort((a, b) => a.title.compareTo(b.title));

    final selectedProduct = _selectedProduct(products);

    final sentNotifications =
        notificationProvider.notifications
            .where(
              (item) =>
                  item.targetRole == 'manager' &&
                  item.orderId.trim().isEmpty &&
                  (item.type == 'promotion' ||
                      item.type == 'new_product' ||
                      item.type == 'general'),
            )
            .toList();

    return ManagerWebLayout(
      title: 'Gửi thông báo',
      currentRoute: AppRoutes.managerNotifications,
      managerName: managerName,
      avatarUrl: avatarUrl,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Làm mới sản phẩm',
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1100
                    ? 24.0
                    : constraints.maxWidth >= 700
                    ? 18.0
                    : 12.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotificationOverview(selectedType: _selectedType),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, inner) {
                          final wide = inner.maxWidth >= 930;

                          final form = _NotificationFormCard(
                            selectedType: _selectedType,
                            selectedProductId: _selectedProductId,
                            products: products,
                            productLoading: productProvider.isLoading,
                            titleController: _titleController,
                            contentController: _contentController,
                            isSubmitting: _isSubmitting,
                            localError: _localError,
                            onTypeChanged: _changeType,
                            onProductChanged: (value) {
                              _selectProduct(value, products);
                            },
                            onSubmit: _submit,
                            onClear: _clearForm,
                          );

                          final preview = Column(
                            children: [
                              _NotificationPreviewCard(
                                type: _selectedType,
                                title: _titleController.text,
                                body: _contentController.text,
                                product: selectedProduct,
                              ),
                              const SizedBox(height: 16),
                              _TemplateCard(onSelected: _applyTemplate),
                              const SizedBox(height: 16),
                              const _UsageTipsCard(),
                            ],
                          );

                          if (!wide) {
                            return Column(
                              children: [
                                form,
                                const SizedBox(height: 16),
                                preview,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: form),
                              const SizedBox(width: 18),
                              Expanded(flex: 5, child: preview),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _SentNotificationsHistoryCard(
                        notifications: sentNotifications,
                        isLoading: notificationProvider.isLoading,
                        onRefresh: _loadData,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SentNotificationsHistoryCard extends StatelessWidget {
  final List<AppNotificationModel> notifications;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _SentNotificationsHistoryCard({
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch sử thông báo đã gửi',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Lưu lại các thông báo do Manager gửi đến Customer.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Làm mới lịch sử',
                  onPressed: isLoading ? null : () => onRefresh(),
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                          : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34, horizontal: 18),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 42,
                      color: AppColors.textGrey,
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Chưa có thông báo nào được lưu',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: notifications.length > 10 ? 10 : notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final color = _typeColor(item.type);

                return Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _typeIcon(item.type),
                          color: color,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatHistoryTime(item.created),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                _typeLabel(item.type),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

String _formatHistoryTime(DateTime time) {
  final local = time.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month ${hour}:$minute';
}

class _NotificationOverview extends StatelessWidget {
  final String selectedType;

  const _NotificationOverview({required this.selectedType});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(selectedType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(_typeIcon(selectedType), color: color, size: 27),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trung tâm thông báo khách hàng',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Soạn nội dung, xem trước và gửi thông báo chung đến toàn bộ Customer.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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

class _NotificationFormCard extends StatelessWidget {
  final String selectedType;
  final String? selectedProductId;
  final List<ProductModel> products;
  final bool productLoading;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isSubmitting;
  final String? localError;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onProductChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _NotificationFormCard({
    required this.selectedType,
    required this.selectedProductId,
    required this.products,
    required this.productLoading,
    required this.titleController,
    required this.contentController,
    required this.isSubmitting,
    required this.localError,
    required this.onTypeChanged,
    required this.onProductChanged,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung thông báo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thông báo sẽ được lưu trên PocketBase và hiển thị trong ứng dụng Customer.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const _AudienceBox(),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: selectedType,
            isExpanded: true,
            decoration: _decoration(
              label: 'Loại thông báo',
              icon: Icons.category_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'promotion', child: Text('Khuyến mãi')),
              DropdownMenuItem(
                value: 'new_product',
                child: Text('Sản phẩm mới'),
              ),
              DropdownMenuItem(
                value: 'general',
                child: Text('Thông báo chung'),
              ),
            ],
            onChanged: isSubmitting ? null : onTypeChanged,
          ),
          if (selectedType == 'new_product') ...[
            const SizedBox(height: 13),
            if (productLoading && products.isEmpty)
              const SizedBox(
                height: 56,
                child: Center(
                  child: LinearProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (products.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Text(
                  'Chưa có sản phẩm đang bán để lựa chọn.',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedProductId,
                isExpanded: true,
                decoration: _decoration(
                  label: 'Sản phẩm cần giới thiệu',
                  icon: Icons.fastfood_rounded,
                ),
                items:
                    products.map((product) {
                      return DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          '${product.title} • ${_formatMoney(product.price)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: isSubmitting ? null : onProductChanged,
              ),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: titleController,
            enabled: !isSubmitting,
            maxLength: 120,
            decoration: _decoration(
              label: 'Tiêu đề',
              icon: Icons.title_rounded,
              hint: 'Ví dụ: Ưu đãi cuối tuần',
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: contentController,
            enabled: !isSubmitting,
            minLines: 6,
            maxLines: 10,
            maxLength: 600,
            decoration: _decoration(
              label: 'Nội dung',
              icon: Icons.notes_rounded,
              hint:
                  'Nhập nội dung rõ ràng, ngắn gọn và có lời kêu gọi hành động.',
            ),
          ),
          if (localError != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;

              final clearButton = OutlinedButton.icon(
                onPressed: isSubmitting ? null : onClear,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Xóa nội dung'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 15,
                  ),
                ),
              );

              final sendButton = FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                icon:
                    isSubmitting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send_rounded),
                label: Text(
                  isSubmitting ? 'Đang gửi...' : 'Gửi đến khách hàng',
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: sendButton),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: clearButton),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [clearButton, const SizedBox(width: 10), sendButton],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AudienceBox extends StatelessWidget {
  const _AudienceBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFDBEAFE),
            child: Icon(Icons.groups_rounded, color: Color(0xFF2563EB)),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tất cả khách hàng',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Đối tượng nhận được cố định là Customer.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _NotificationPreviewCard extends StatelessWidget {
  final String type;
  final String title;
  final String body;
  final ProductModel? product;

  const _NotificationPreviewCard({
    required this.type,
    required this.title,
    required this.body,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);
    final safeTitle = title.trim().isEmpty ? 'Tiêu đề thông báo' : title.trim();
    final safeBody =
        body.trim().isEmpty
            ? 'Nội dung thông báo sẽ hiển thị tại đây.'
            : body.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xem trước trên ứng dụng',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bản xem trước mô phỏng thẻ thông báo Customer nhận được.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.12), AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_typeIcon(type), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel(type),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        safeTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        safeBody,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      if (product != null) ...[
                        const SizedBox(height: 11),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  product!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _formatMoney(product!.price),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        'Vừa xong',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
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

class _TemplateCard extends StatelessWidget {
  final ValueChanged<_NotificationTemplate> onSelected;

  const _TemplateCard({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const templates = [
      _NotificationTemplate(
        type: 'promotion',
        title: 'Ưu đãi cuối tuần',
        body:
            'Đặt món cuối tuần và nhận ưu đãi hấp dẫn từ YourFood. Số lượng có hạn, đặt ngay hôm nay!',
      ),
      _NotificationTemplate(
        type: 'general',
        title: 'YourFood đã sẵn sàng phục vụ',
        body:
            'Thực đơn hôm nay đã được cập nhật. Mở ứng dụng để khám phá các món ăn phù hợp với bạn.',
      ),
      _NotificationTemplate(
        type: 'promotion',
        title: 'Freeship trong khung giờ vàng',
        body:
            'Ưu đãi phí giao hàng đang diễn ra trong thời gian giới hạn. Đặt món ngay để không bỏ lỡ!',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mẫu nội dung nhanh',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn mẫu rồi điều chỉnh lại trước khi gửi.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 13),
          ...templates.map((template) {
            final color = _typeColor(template.type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    onSelected(template);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(_typeIcon(template.type), color: color, size: 21),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            template.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UsageTipsCard extends StatelessWidget {
  const _UsageTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Gợi ý sử dụng',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _TipLine(
            text: 'Tiêu đề nên ngắn, thể hiện rõ lợi ích hoặc nội dung chính.',
          ),
          _TipLine(text: 'Không gửi quá nhiều thông báo trong thời gian ngắn.'),
          _TipLine(
            text:
                'Thông báo trạng thái đơn hàng được hệ thống tự tạo khi Manager xử lý đơn.',
          ),
          _TipLine(text: 'Kiểm tra bản xem trước trước khi bấm gửi.'),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  final String text;

  const _TipLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTemplate {
  final String type;
  final String title;
  final String body;

  const _NotificationTemplate({
    required this.type,
    required this.title,
    required this.body,
  });
}

InputDecoration _decoration({
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

Color _typeColor(String type) {
  switch (type) {
    case 'promotion':
      return const Color(0xFFF97316);
    case 'new_product':
      return AppColors.success;
    case 'general':
      return const Color(0xFF2563EB);
    default:
      return AppColors.textSecondary;
  }
}

String _formatMoney(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);

    final remaining = digits.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
  }

  return '${buffer}đ';
}
