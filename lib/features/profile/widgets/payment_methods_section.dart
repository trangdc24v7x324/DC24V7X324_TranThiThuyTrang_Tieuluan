// FILE HỌC TẬP: lib/features/profile/widgets/payment_methods_section.dart
// Vai trò: Widget hồ sơ cho phần phương thức thanh toán.
// Luồng sử dụng: Hiển thị/chỉnh sửa một phần hồ sơ và trả sự kiện về màn hình Profile.

import 'package:project_trangdc24v7x324/models/payment_method_model.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/section_card.dart';

// Lớp PaymentMethodsSection: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class PaymentMethodsSection extends StatefulWidget {
  final List<PaymentMethodModel> methods;
  final bool isEditing;
  final VoidCallback onEdit;
  final Future<void> Function(List<PaymentMethodModel> updatedMethods) onSave;

  // Khởi tạo PaymentMethodsSection: nhận các tham số cần thiết để tạo đối tượng cho widget hồ sơ cho phần phương thức thanh toán.
  const PaymentMethodsSection({
    super.key,
    required this.methods,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
  });

  // Tạo state (createState): liên kết PaymentMethodsSection với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<PaymentMethodsSection> createState() => _PaymentMethodsSectionState();
}

// Lớp _PaymentMethodsSectionState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _PaymentMethodsSectionState extends State<PaymentMethodsSection> {
  bool _isSaving = false;

  // Lấy biểu tượng (_getIcon): truy xuất và trả kết quả cho lớp gọi.
  IconData _getIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments_outlined;
      case 'momo':
        return Icons.account_balance_wallet_outlined;
      case 'visa':
      case 'bank':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  // Xử lý _defaultMethods: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho phần phương thức thanh toán.
  List<PaymentMethodModel> _defaultMethods() {
    return const [
      PaymentMethodModel(
        id: 'cash',
        userId: '',
        type: 'cash',
        displayName: 'Tiền mặt',
        provider: 'Thanh toán khi nhận hàng',
        accountNumber: '',
        isDefault: true,
      ),
      PaymentMethodModel(
        id: 'momo',
        userId: '',
        type: 'momo',
        displayName: 'MoMo',
        provider: 'Ví điện tử MoMo',
        accountNumber: '',
        isDefault: false,
      ),
      PaymentMethodModel(
        id: 'visa',
        userId: '',
        type: 'visa',
        displayName: 'Visa/Mastercard',
        provider: 'Thẻ Visa/Mastercard',
        accountNumber: '',
        isDefault: false,
      ),
    ];
  }

  // Lưu phương thức (_saveMethods): kiểm tra dữ liệu, ghi thay đổi và đồng bộ state sau khi thành công.
  Future<void> _saveMethods(List<PaymentMethodModel> updatedMethods) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave(updatedMethods);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Cập nhật mặc định (_setDefault): gán state nội bộ và thông báo lại cho UI khi cần.
  Future<void> _setDefault(PaymentMethodModel selectedMethod) async {
    final updatedMethods =
        widget.methods.map((method) {
          return method.copyWith(isDefault: method.id == selectedMethod.id);
        }).toList();

    await _saveMethods(updatedMethods);
  }

  // Xây dựng giao diện (build): dựng cây widget của _PaymentMethodsSectionState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final defaultMethodId =
        widget.methods.isEmpty
            ? null
            : widget.methods
                .firstWhere(
                  (method) => method.isDefault,
                  orElse: () => widget.methods.first,
                )
                .id;

    return SectionCard(
      title: 'Phương thức thanh toán',
      action: IconButton(
        onPressed: _isSaving ? null : widget.onEdit,
        icon:
            _isSaving
                ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(
                  widget.isEditing ? Icons.check : Icons.edit_outlined,
                  color: const Color(0xFFEF2A39),
                ),
      ),
      child:
          widget.methods.isEmpty
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chưa có phương thức thanh toán',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isSaving
                                ? null
                                : () => _saveMethods(_defaultMethods()),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm phương thức mặc định'),
                      ),
                    ),
                  ],
                ],
              )
              : RadioGroup<String>(
                groupValue: defaultMethodId,
                onChanged: (value) {
                  if (!widget.isEditing || _isSaving || value == null) return;

                  for (final method in widget.methods) {
                    if (method.id == value) {
                      _setDefault(method);
                      break;
                    }
                  }
                },
                child: Column(
                  children:
                      widget.methods.map((method) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_getIcon(method.type)),
                          title: Text(
                            method.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(method.subtitle),
                          trailing:
                              widget.isEditing
                                  ? Radio<String>(
                                    value: method.id,
                                    enabled: !_isSaving,
                                  )
                                  : method.isDefault
                                  ? const Text(
                                    'Mặc định',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                  : null,
                        );
                      }).toList(),
                ),
              ),
    );
  }
}
