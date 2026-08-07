import 'dart:typed_data';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/category_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ManagerWebProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const ManagerWebProductFormPage({super.key, this.product});

  @override
  State<ManagerWebProductFormPage> createState() =>
      _ManagerWebProductFormPageState();
}

class _ManagerWebProductFormPageState extends State<ManagerWebProductFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _deliveryTimeController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;

  String? _selectedCategoryId;

  bool _isAvailable = true;
  bool _isOnSale = false;
  bool _isSubmitting = false;
  bool _isLoadingInitialData = true;

  DateTime? _saleStartAt;
  DateTime? _saleEndAt;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  String? _localError;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _titleController = TextEditingController(text: product?.title ?? '');
    _subtitleController = TextEditingController(text: product?.subtitle ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _deliveryTimeController = TextEditingController(
      text:
          product?.deliveryTime.trim().isNotEmpty == true
              ? product!.deliveryTime
              : '20-30 phút',
    );
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    _salePriceController = TextEditingController(
      text:
          product != null && product.salePrice > 0
              ? product.salePrice.toStringAsFixed(0)
              : '',
    );

    _selectedCategoryId =
        product?.categoryId.trim().isNotEmpty == true
            ? product!.categoryId
            : null;
    _isAvailable = product?.isAvailable ?? true;
    _isOnSale = product?.isOnSale ?? false;
    _saleStartAt = product?.saleStartAt;
    _saleEndAt = product?.saleEndAt;

    _titleController.addListener(_refreshPreview);
    _subtitleController.addListener(_refreshPreview);
    _priceController.addListener(_refreshPreview);
    _salePriceController.addListener(_refreshPreview);

    Future.microtask(_loadInitialData);
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshPreview);
    _subtitleController.removeListener(_refreshPreview);
    _priceController.removeListener(_refreshPreview);
    _salePriceController.removeListener(_refreshPreview);

    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _deliveryTimeController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();

    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitialData = true;
      _localError = null;
    });

    try {
      await Future.wait([
        context.read<ProductProvider>().loadCategories(),
        context.read<ProfileProvider>().loadProfile(forceReload: true),
      ]);

      if (!mounted) return;

      final categories = context.read<ProductProvider>().categories;

      final selectedExists =
          _selectedCategoryId != null &&
          categories.any((category) => category.id == _selectedCategoryId);

      setState(() {
        if (!selectedExists && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }

        _isLoadingInitialData = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingInitialData = false;
        _localError = 'Không thể tải dữ liệu biểu mẫu: $error';
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isSubmitting) return;

    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );

      if (result == null) return;

      final bytes = await result.readAsBytes();

      if (!mounted) return;

      if (bytes.isEmpty) {
        _showMessage('Không đọc được dữ liệu ảnh');
        return;
      }

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _showMessage('Ảnh không được vượt quá 5 MB');
        return;
      }

      setState(() {
        _selectedImage = result;
        _selectedImageBytes = bytes;
        _localError = null;
      });
    } catch (error) {
      _showMessage('Không thể chọn ảnh: $error');
    }
  }

  void _removeSelectedImage() {
    if (_isSubmitting) return;

    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _pickSaleStartDate() async {
    if (_isSubmitting) return;

    final result = await showDatePicker(
      context: context,
      initialDate: _saleStartAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày bắt đầu khuyến mãi',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (result == null || !mounted) return;

    setState(() {
      _saleStartAt = DateTime(result.year, result.month, result.day);

      if (_saleEndAt != null && _saleEndAt!.isBefore(_saleStartAt!)) {
        _saleEndAt = DateTime(
          result.year,
          result.month,
          result.day,
          23,
          59,
          59,
          999,
        );
      }
    });
  }

  Future<void> _pickSaleEndDate() async {
    if (_isSubmitting) return;

    final initial = _saleEndAt ?? _saleStartAt ?? DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _saleStartAt ?? DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày kết thúc khuyến mãi',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (result == null || !mounted) return;

    setState(() {
      _saleEndAt = DateTime(
        result.year,
        result.month,
        result.day,
        23,
        59,
        59,
        999,
      );
    });
  }

  CategoryModel? _selectedCategory(ProductProvider provider) {
    final categoryId = _selectedCategoryId;

    if (categoryId == null || categoryId.isEmpty) {
      return null;
    }

    try {
      return provider.categories.firstWhere(
        (category) => category.id == categoryId,
      );
    } catch (_) {
      return null;
    }
  }

  double? _parseMoney(String value) {
    final normalized = value
        .trim()
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '');

    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _localError = 'Vui lòng kiểm tra lại các trường được đánh dấu.';
      });
      return;
    }

    final provider = context.read<ProductProvider>();
    final category = _selectedCategory(provider);

    if (category == null) {
      setState(() {
        _localError = 'Vui lòng chọn danh mục sản phẩm.';
      });
      return;
    }

    final price = _parseMoney(_priceController.text);

    if (price == null || price <= 0) {
      setState(() {
        _localError = 'Giá gốc không hợp lệ.';
      });
      return;
    }

    double salePrice = 0;

    if (_isOnSale) {
      final parsedSalePrice = _parseMoney(_salePriceController.text);

      if (parsedSalePrice == null || parsedSalePrice <= 0) {
        setState(() {
          _localError = 'Giá khuyến mãi không hợp lệ.';
        });
        return;
      }

      if (parsedSalePrice >= price) {
        setState(() {
          _localError = 'Giá khuyến mãi phải nhỏ hơn giá gốc.';
        });
        return;
      }

      if (_saleStartAt != null &&
          _saleEndAt != null &&
          _saleEndAt!.isBefore(_saleStartAt!)) {
        setState(() {
          _localError = 'Ngày kết thúc phải sau ngày bắt đầu.';
        });
        return;
      }

      salePrice = parsedSalePrice;
    }

    final hasCurrentImage = (widget.product?.image ?? '').trim().isNotEmpty;

    if (!_isEdit && _selectedImageBytes == null && !hasCurrentImage) {
      setState(() {
        _localError = 'Vui lòng chọn ảnh sản phẩm.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final oldProduct = widget.product;

    final product = ProductModel(
      id: oldProduct?.id ?? '',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      rating: oldProduct?.rating ?? 0,
      reviewCount: oldProduct?.reviewCount ?? 0,
      image: oldProduct?.image ?? '',
      description: _descriptionController.text.trim(),
      deliveryTime: _deliveryTimeController.text.trim(),
      price: price,
      salePrice: salePrice,
      isOnSale: _isOnSale,
      saleStartAt: _isOnSale ? _saleStartAt : null,
      saleEndAt: _isOnSale ? _saleEndAt : null,
      categoryId: category.id,
      categoryTitle: category.title,
      categorySlug: category.slug,
      isAvailable: _isAvailable,
      created: oldProduct?.created,
      updated: oldProduct?.updated,
    );

    final success =
        _isEdit
            ? await provider.updateProduct(
              oldProduct!.id,
              product,
              imageBytes: _selectedImageBytes,
              imageName: _selectedImage?.name,
            )
            : await provider.addProduct(
              product,
              imageBytes: _selectedImageBytes,
              imageName: _selectedImage?.name,
            );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      setState(() {
        _localError = provider.errorMessage ?? 'Lưu sản phẩm thất bại.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm'),
      ),
    );

    Navigator.pop(context, true);
  }

  void _cancel() {
    if (_isSubmitting) return;
    Navigator.pop(context, false);
  }

  void _logout() {
    pb.authStore.clear();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';

    final avatarUrl = profile?.avatarUrl ?? '';

    return PopScope(
      canPop: !_isSubmitting,
      child: ManagerWebLayout(
        title: _isEdit ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm',
        currentRoute: AppRoutes.managerProducts,
        managerName: managerName,
        avatarUrl: avatarUrl,
        onLogout: _logout,
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _cancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Đóng'),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon:
                _isSubmitting
                    ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.save_rounded),
            label: Text(
              _isSubmitting
                  ? 'Đang lưu...'
                  : _isEdit
                  ? 'Lưu thay đổi'
                  : 'Thêm sản phẩm',
            ),
          ),
        ],
        child:
            _isLoadingInitialData
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth >= 1100
                            ? 24.0
                            : constraints.maxWidth >= 700
                            ? 18.0
                            : 12.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1320),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPageIntro(),
                                if (_localError != null) ...[
                                  const SizedBox(height: 14),
                                  _ErrorBanner(
                                    message: _localError!,
                                    onClose: () {
                                      setState(() {
                                        _localError = null;
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    final useTwoColumns =
                                        innerConstraints.maxWidth >= 920;

                                    final mainForm = _buildMainForm(
                                      productProvider,
                                    );

                                    final previewColumn = Column(
                                      children: [
                                        _buildImageCard(),
                                        const SizedBox(height: 16),
                                        _buildPreviewCard(productProvider),
                                        const SizedBox(height: 16),
                                        _buildStatusCard(),
                                      ],
                                    );

                                    if (!useTwoColumns) {
                                      return Column(
                                        children: [
                                          previewColumn,
                                          const SizedBox(height: 16),
                                          mainForm,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 7, child: mainForm),
                                        const SizedBox(width: 18),
                                        Expanded(flex: 4, child: previewColumn),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                _buildBottomActions(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildPageIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.10), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              _isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded,
              color: AppColors.primary,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Cập nhật thông tin sản phẩm' : 'Tạo sản phẩm mới',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEdit
                      ? 'Chỉnh sửa nội dung, giá bán, khuyến mãi và trạng thái hiển thị.'
                      : 'Nhập đầy đủ thông tin để sản phẩm có thể hiển thị chính xác cho khách hàng.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm(ProductProvider provider) {
    return Column(
      children: [
        _FormSection(
          title: 'Thông tin cơ bản',
          subtitle: 'Tên, nội dung mô tả và thời gian giao dự kiến.',
          icon: Icons.description_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 650;
              final itemWidth =
                  twoColumns
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: TextFormField(
                      controller: _titleController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Tên sản phẩm',
                        icon: Icons.fastfood_rounded,
                        hint: 'Ví dụ: Cơm gà xối mỡ',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';

                        if (text.isEmpty) {
                          return 'Vui lòng nhập tên sản phẩm';
                        }

                        if (text.length < 2) {
                          return 'Tên sản phẩm quá ngắn';
                        }

                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Danh mục',
                        icon: Icons.category_outlined,
                      ),
                      items:
                          provider.categories
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(
                                    category.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _isSubmitting
                              ? null
                              : (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn danh mục';
                        }

                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: TextFormField(
                      controller: _subtitleController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Mô tả ngắn',
                        icon: Icons.short_text_rounded,
                        hint: 'Nội dung hiển thị trên thẻ sản phẩm',
                      ),
                      validator: (value) {
                        if ((value?.trim().length ?? 0) > 160) {
                          return 'Mô tả ngắn tối đa 160 ký tự';
                        }

                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: TextFormField(
                      controller: _deliveryTimeController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Thời gian giao',
                        icon: Icons.schedule_rounded,
                        hint: '20-30 phút',
                      ),
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return 'Vui lòng nhập thời gian giao';
                        }

                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: TextFormField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      minLines: 5,
                      maxLines: 8,
                      decoration: _inputDecoration(
                        label: 'Mô tả chi tiết',
                        icon: Icons.notes_rounded,
                        hint:
                            'Mô tả thành phần, khẩu phần hoặc điểm nổi bật của món...',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _FormSection(
          title: 'Giá bán',
          subtitle: 'Thiết lập giá gốc và chương trình khuyến mãi.',
          icon: Icons.payments_outlined,
          child: Column(
            children: [
              TextFormField(
                controller: _priceController,
                enabled: !_isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                decoration: _inputDecoration(
                  label: 'Giá gốc',
                  icon: Icons.monetization_on_outlined,
                  suffix: 'đ',
                  hint: 'Ví dụ: 50000',
                ),
                validator: (value) {
                  final price = _parseMoney(value ?? '');

                  if (price == null || price <= 0) {
                    return 'Giá gốc phải lớn hơn 0';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      _isOnSale
                          ? const Color(0xFFFFF7F7)
                          : AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _isOnSale
                            ? AppColors.primary.withOpacity(0.22)
                            : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Áp dụng khuyến mãi',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        _isOnSale
                            ? 'Giá ưu đãi sẽ được dùng khi còn trong thời gian hiệu lực.'
                            : 'Sản phẩm đang bán theo giá gốc.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: _isOnSale,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged:
                          _isSubmitting
                              ? null
                              : (value) {
                                setState(() {
                                  _isOnSale = value;

                                  if (!value) {
                                    _saleStartAt = null;
                                    _saleEndAt = null;
                                  }
                                });
                              },
                    ),
                    if (_isOnSale) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _salePriceController,
                        enabled: !_isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: _inputDecoration(
                          label: 'Giá khuyến mãi',
                          icon: Icons.local_offer_outlined,
                          suffix: 'đ',
                        ),
                        validator: (value) {
                          if (!_isOnSale) return null;

                          final salePrice = _parseMoney(value ?? '');
                          final price = _parseMoney(_priceController.text);

                          if (salePrice == null || salePrice <= 0) {
                            return 'Giá khuyến mãi phải lớn hơn 0';
                          }

                          if (price != null && salePrice >= price) {
                            return 'Giá khuyến mãi phải nhỏ hơn giá gốc';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoColumns = constraints.maxWidth >= 520;

                          final fieldWidth =
                              twoColumns
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: fieldWidth,
                                child: _DateField(
                                  title: 'Ngày bắt đầu',
                                  value: _saleStartAt,
                                  enabled: !_isSubmitting,
                                  onTap: _pickSaleStartDate,
                                  onClear: () {
                                    setState(() {
                                      _saleStartAt = null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _DateField(
                                  title: 'Ngày kết thúc',
                                  value: _saleEndAt,
                                  enabled: !_isSubmitting,
                                  onTap: _pickSaleEndDate,
                                  onClear: () {
                                    setState(() {
                                      _saleEndAt = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 9),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Có thể để trống một hoặc cả hai mốc ngày nếu chương trình không giới hạn thời gian.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard() {
    final currentImage = widget.product?.image.trim() ?? '';

    Widget image;

    if (_selectedImageBytes != null) {
      image = Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (currentImage.isNotEmpty) {
      image = Image.network(
        currentImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    } else {
      image = _imagePlaceholder();
    }

    return _SideCard(
      title: 'Ảnh sản phẩm',
      subtitle: 'Định dạng JPG/PNG/WebP, tối đa 5 MB.',
      icon: Icons.image_outlined,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: AppColors.backgroundSecondary,
                child: image,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _isSubmitting ? null : _pickImage,
              icon: const Icon(Icons.upload_rounded),
              label: Text(
                _selectedImageBytes == null && currentImage.isEmpty
                    ? 'Chọn ảnh'
                    : 'Thay ảnh',
              ),
            ),
          ),
          if (_selectedImageBytes != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isSubmitting ? null : _removeSelectedImage,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Dùng lại ảnh hiện tại'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ProductProvider provider) {
    final title =
        _titleController.text.trim().isEmpty
            ? 'Tên sản phẩm'
            : _titleController.text.trim();

    final subtitle =
        _subtitleController.text.trim().isEmpty
            ? 'Mô tả ngắn của sản phẩm'
            : _subtitleController.text.trim();

    final category = _selectedCategory(provider)?.title ?? 'Chưa chọn danh mục';

    final price = _parseMoney(_priceController.text) ?? 0;
    final salePrice = _parseMoney(_salePriceController.text) ?? 0;

    final validSale =
        _isOnSale && price > 0 && salePrice > 0 && salePrice < price;

    final discount =
        validSale ? (((price - salePrice) / price) * 100).round() : 0;

    return _SideCard(
      title: 'Xem trước',
      subtitle: 'Mô phỏng thông tin hiển thị cho khách hàng.',
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),
          if (validSale) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  _formatMoney(salePrice),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatMoney(price),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ] else
            Text(
              price > 0 ? _formatMoney(price) : 'Chưa nhập giá',
              style: TextStyle(
                color: price > 0 ? AppColors.primary : AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return _SideCard(
      title: 'Trạng thái bán',
      subtitle: 'Quản lý khả năng hiển thị và đặt món.',
      icon: Icons.toggle_on_outlined,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _isAvailable ? 'Đang bán' : 'Ngừng bán',
          style: TextStyle(
            color: _isAvailable ? AppColors.success : Colors.red,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          _isAvailable
              ? 'Khách hàng có thể thấy và đặt sản phẩm.'
              : 'Sản phẩm được lưu nhưng không thể đặt.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        value: _isAvailable,
        activeColor: Colors.white,
        activeTrackColor: AppColors.success,
        onChanged:
            _isSubmitting
                ? null
                : (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final cancelButton = OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _cancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Hủy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            ),
          );

          final saveButton = FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            icon:
                _isSubmitting
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.save_rounded),
            label: Text(
              _isSubmitting
                  ? 'Đang lưu...'
                  : _isEdit
                  ? 'Cập nhật sản phẩm'
                  : 'Thêm sản phẩm',
            ),
          );

          if (compact) {
            return Column(
              children: [
                SizedBox(width: double.infinity, child: saveButton),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: cancelButton),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [cancelButton, const SizedBox(width: 10), saveButton],
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.textGrey,
            size: 52,
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có ảnh sản phẩm',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SideCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String title;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(13, 8, 5, 8),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateValue(value),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                IconButton(
                  tooltip: 'Xóa ngày',
                  onPressed: enabled ? onClear : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

String _formatDateValue(DateTime? value) {
  if (value == null) {
    return 'Không giới hạn';
  }

  String two(int number) => number.toString().padLeft(2, '0');

  return '${two(value.day)}/${two(value.month)}/${value.year}';
}

String _formatMoney(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    buffer.write(digits[index]);

    final remaining = digits.length - index - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
  }

  return '${buffer}đ';
}
