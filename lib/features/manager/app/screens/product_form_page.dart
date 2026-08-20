
import 'dart:typed_data';

import 'package:project_trangdc24v7x324/models/category_model.dart';
import 'package:project_trangdc24v7x324/models/product_model.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

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

  DateTime? _saleStartAt;
  DateTime? _saleEndAt;

  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    final ProductModel? product = widget.product;

    _titleController = TextEditingController(text: product?.title ?? '');

    _subtitleController = TextEditingController(text: product?.subtitle ?? '');

    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );

    _deliveryTimeController = TextEditingController(
      text: product?.deliveryTime ?? '20-30 phút',
    );

    _priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(0) : '',
    );

    _salePriceController = TextEditingController(
      text:
          product != null && product.salePrice > 0
              ? product.salePrice.toStringAsFixed(0)
              : '',
    );

    _selectedCategoryId =
        product?.categoryId.isNotEmpty == true ? product!.categoryId : null;

    _isAvailable = product?.isAvailable ?? true;

    _isOnSale = product?.isOnSale ?? false;

    _saleStartAt = product?.saleStartAt;

    _saleEndAt = product?.saleEndAt;

    Future.microtask(() async {
      if (!mounted) return;
      final ProductProvider provider = context.read<ProductProvider>();

      await provider.loadCategories();

      if (!mounted) return;

      if (_selectedCategoryId == null && provider.categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = provider.categories.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _deliveryTimeController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();

    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa chọn';
    }

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickImage() async {
    if (_isSubmitting) return;

    final XFile? result = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (result == null) return;

    final Uint8List bytes = await result.readAsBytes();

    if (!mounted) return;

    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      _showMessage('Ảnh không được vượt quá 5 MB');
      return;
    }

    setState(() {
      _selectedImageFile = result;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _pickSaleStartDate() async {
    if (_isSubmitting) return;

    final DateTime initialDate = _saleStartAt ?? DateTime.now();

    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày bắt đầu',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _saleStartAt = DateTime(result.year, result.month, result.day);
    });
  }

  Future<void> _pickSaleEndDate() async {
    if (_isSubmitting) return;

    final DateTime initialDate = _saleEndAt ?? _saleStartAt ?? DateTime.now();

    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày kết thúc',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (result == null || !mounted) {
      return;
    }

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

  void _clearSaleStartDate() {
    setState(() {
      _saleStartAt = null;
    });
  }

  void _clearSaleEndDate() {
    setState(() {
      _saleEndAt = null;
    });
  }

  CategoryModel? _selectedCategory(ProductProvider provider) {
    if (_selectedCategoryId == null) {
      return null;
    }

    try {
      return provider.categories.firstWhere(
        (category) => category.id == _selectedCategoryId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ProductProvider provider = context.read<ProductProvider>();

    final CategoryModel? category = _selectedCategory(provider);

    if (category == null) {
      _showMessage('Vui lòng chọn danh mục');
      return;
    }

    final double? price = double.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      _showMessage('Giá sản phẩm không hợp lệ');
      return;
    }

    double salePrice = 0;

    if (_isOnSale) {
      final double? parsedSalePrice = double.tryParse(
        _salePriceController.text.trim(),
      );

      if (parsedSalePrice == null || parsedSalePrice <= 0) {
        _showMessage('Giá khuyến mãi không hợp lệ');
        return;
      }

      if (parsedSalePrice >= price) {
        _showMessage('Giá khuyến mãi phải nhỏ hơn giá gốc');
        return;
      }

      salePrice = parsedSalePrice;

      if (_saleStartAt != null &&
          _saleEndAt != null &&
          _saleEndAt!.isBefore(_saleStartAt!)) {
        _showMessage('Ngày kết thúc phải sau ngày bắt đầu');
        return;
      }
    } else {
      salePrice = double.tryParse(_salePriceController.text.trim()) ?? 0;
    }

    if (!isEdit && _selectedImageBytes == null) {
      _showMessage('Vui lòng chọn ảnh sản phẩm');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final ProductModel product = ProductModel(
      id: widget.product?.id ?? '',

      title: _titleController.text.trim(),

      subtitle: _subtitleController.text.trim(),

      rating: widget.product?.rating ?? 0,

      reviewCount: widget.product?.reviewCount ?? 0,

      image: widget.product?.image ?? '',

      description: _descriptionController.text.trim(),

      deliveryTime: _deliveryTimeController.text.trim(),

      price: price,

      salePrice: salePrice,

      isOnSale: _isOnSale,

      saleStartAt: _saleStartAt,

      saleEndAt: _saleEndAt,

      categoryId: category.id,

      categoryTitle: category.title,

      categorySlug: category.slug,

      isAvailable: _isAvailable,

      created: widget.product?.created,

      updated: widget.product?.updated,
    );

    final bool success =
        isEdit
            ? await provider.updateProduct(
              widget.product!.id,
              product,
              imageBytes: _selectedImageBytes,
              imageName: _selectedImageFile?.name,
            )
            : await provider.addProduct(
              product,
              imageBytes: _selectedImageBytes,
              imageName: _selectedImageFile?.name,
            );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    _showMessage(provider.errorMessage ?? 'Lưu sản phẩm thất bại');
  }

  Widget _buildImagePreview() {
    if (_selectedImageBytes != null) {
      return _imageBox(
        Image.memory(
          _selectedImageBytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    if ((widget.product?.image ?? '').isNotEmpty) {
      return _imageBox(
        Image.network(
          widget.product!.image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded),
        ),
      );
    }

    return _emptyImageBox();
  }

  Widget _imageBox(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(height: 190, width: double.infinity, child: child),
    );
  }

  Widget _emptyImageBox() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(child: Text('Chưa chọn ảnh')),
    );
  }

  InputDecoration _decoration(
    String label, {
    String? hintText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildDateField({
    required String title,
    required DateTime? date,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBDBDBD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: Color(0xFFEF2A39)),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _isSubmitting ? null : onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (date != null)
            IconButton(
              tooltip: 'Xóa ngày',
              onPressed: _isSubmitting ? null : onClear,
              icon: const Icon(Icons.close, size: 19),
            ),
        ],
      ),
    );
  }

  Widget _buildSaleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Khuyến mãi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _isOnSale
                ? 'Đang bật chương trình khuyến mãi'
                : 'Sản phẩm đang bán theo giá gốc',
          ),
          value: _isOnSale,
          activeThumbColor: const Color(0xFFEF2A39),
          onChanged:
              _isSubmitting
                  ? null
                  : (value) {
                    setState(() {
                      _isOnSale = value;
                    });
                  },
        ),

        if (_isOnSale) ...[
          const SizedBox(height: 10),

          TextFormField(
            controller: _salePriceController,
            enabled: !_isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration('Giá khuyến mãi', suffixText: 'đ'),
            validator: (value) {
              if (!_isOnSale) {
                return null;
              }

              final double? salePrice = double.tryParse(value?.trim() ?? '');

              if (salePrice == null || salePrice <= 0) {
                return 'Giá khuyến mãi không hợp lệ';
              }

              final double? price = double.tryParse(
                _priceController.text.trim(),
              );

              if (price != null && salePrice >= price) {
                return 'Giá khuyến mãi phải nhỏ hơn giá gốc';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          _buildDateField(
            title: 'Ngày bắt đầu',
            date: _saleStartAt,
            onPick: _pickSaleStartDate,
            onClear: _clearSaleStartDate,
          ),

          const SizedBox(height: 10),

          _buildDateField(
            title: 'Ngày kết thúc',
            date: _saleEndAt,
            onPick: _pickSaleEndDate,
            onClear: _clearSaleEndDate,
          ),

          const SizedBox(height: 8),

          Text(
            'Có thể để trống ngày bắt đầu hoặc ngày kết thúc '
            'nếu chương trình không giới hạn thời gian.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForm(ProductProvider provider) {
    final List<CategoryModel> categories = provider.categories;

    if (provider.isLoading && categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFEF2A39)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildImagePreview(),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _pickImage,
          icon: const Icon(Icons.image_rounded),
          label: const Text('Chọn ảnh'),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _titleController,
          enabled: !_isSubmitting,
          decoration: _decoration('Tên sản phẩm'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nhập tên sản phẩm';
            }

            return null;
          },
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: _subtitleController,
          enabled: !_isSubmitting,
          decoration: _decoration('Mô tả ngắn'),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: _priceController,
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration('Giá gốc', suffixText: 'đ'),
          validator: (value) {
            final double? price = double.tryParse(value?.trim() ?? '');

            if (price == null || price <= 0) {
              return 'Giá không hợp lệ';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: _buildSaleSection(),
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _deliveryTimeController,
          enabled: !_isSubmitting,
          decoration: _decoration('Thời gian giao'),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: _descriptionController,
          enabled: !_isSubmitting,
          maxLines: 4,
          decoration: _decoration('Mô tả chi tiết'),
        ),

        const SizedBox(height: 10),

        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: _decoration('Danh mục'),
          items:
              categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.title),
                );
              }).toList(),
          onChanged:
              _isSubmitting
                  ? null
                  : (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'Chọn danh mục' : null,
        ),

        const SizedBox(height: 10),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Đang bán'),
          subtitle: Text(
            _isAvailable
                ? 'Sản phẩm được hiển thị cho khách hàng'
                : 'Sản phẩm tạm ngừng bán',
          ),
          value: _isAvailable,
          activeThumbColor: const Color(0xFFEF2A39),
          onChanged:
              _isSubmitting
                  ? null
                  : (value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF2A39),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(isEdit ? 'Cập nhật' : 'Thêm sản phẩm'),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProductProvider provider = context.watch<ProductProvider>();

    return AppLayout(
      title: isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
      showBack: true,
      child: AppBody(child: Form(key: _formKey, child: _buildForm(provider))),
    );
  }
}
