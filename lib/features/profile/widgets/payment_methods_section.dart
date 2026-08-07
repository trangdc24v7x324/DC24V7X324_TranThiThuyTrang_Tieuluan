import 'package:CT466_project_trangdc24v7x324/models/payment_method_model.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/section_card.dart';

class PaymentMethodsSection extends StatefulWidget {
  final List<PaymentMethodModel> methods;
  final bool isEditing;
  final VoidCallback onEdit;
  final Future<void> Function(List<PaymentMethodModel> updatedMethods) onSave;

  const PaymentMethodsSection({
    super.key,
    required this.methods,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
  });

  @override
  State<PaymentMethodsSection> createState() => _PaymentMethodsSectionState();
}

class _PaymentMethodsSectionState extends State<PaymentMethodsSection> {
  bool _isSaving = false;

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

  Future<void> _setDefault(PaymentMethodModel selectedMethod) async {
    final updatedMethods =
        widget.methods.map((method) {
          return method.copyWith(isDefault: method.id == selectedMethod.id);
        }).toList();

    await _saveMethods(updatedMethods);
  }

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
              : Column(
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
                                  groupValue: defaultMethodId,
                                  onChanged:
                                      _isSaving
                                          ? null
                                          : (_) => _setDefault(method),
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
    );
  }
}
