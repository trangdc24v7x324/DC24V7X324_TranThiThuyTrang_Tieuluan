import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:CT466_project_trangdc24v7x324/models/payment_record_model.dart';
import 'package:CT466_project_trangdc24v7x324/routes/app_routes.dart';
import 'package:CT466_project_trangdc24v7x324/services/payment_service.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_card.dart';

class PaymentTestPage extends StatefulWidget {
  final String orderId;

  const PaymentTestPage({super.key, required this.orderId});

  @override
  State<PaymentTestPage> createState() => _PaymentTestPageState();
}

class _PaymentTestPageState extends State<PaymentTestPage> {
  final PaymentService _paymentService = PaymentService();

  PaymentRecordModel? _payment;

  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadPayment);
  }

  Future<void> _loadPayment() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payment = await _paymentService.fetchOrCreateForOrder(
        widget.orderId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payment = payment;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _simulateSuccess() async {
    final payment = _payment;

    if (payment == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _paymentService.markDemoPaid(
        paymentId: payment.id,
        orderId: payment.orderId,
      );

      await _reloadAfterMutation();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Mô phỏng thành công')),
              ],
            ),
            content: const Text(
              'Payment demo đã chuyển sang trạng thái paid. '
              'Chi tiết đơn hàng sẽ đọc trạng thái thanh toán '
              'từ payment record.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.orderDetail,
                    arguments: widget.orderId,
                  );
                },
                child: const Text('Xem đơn hàng'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
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

  Future<void> _simulateFailure() async {
    final payment = _payment;

    if (payment == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _paymentService.markDemoFailed(
        paymentId: payment.id,
        orderId: payment.orderId,
        reason: 'Mô phỏng giao dịch thất bại từ PaymentTestPage.',
      );

      await _reloadAfterMutation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
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

  Future<void> _retry() async {
    final payment = _payment;

    if (payment == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _paymentService.retryDemoPayment(
        paymentId: payment.id,
        orderId: payment.orderId,
      );

      await _reloadAfterMutation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
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

  Future<void> _reloadAfterMutation() async {
    final latest = await _paymentService.fetchByOrderId(widget.orderId);

    if (!mounted) {
      return;
    }

    setState(() {
      _payment = latest;
    });
  }

  String _formatPrice(double value) {
    final text = value.round().toString();

    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final position = text.length - i;

      result.write(text[i]);

      if (position > 1 && position % 3 == 1) {
        result.write('.');
      }
    }

    return '${result}đ';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'unpaid':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Thanh toán thử nghiệm',
      showBack: true,
      child: AppBody(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && _payment == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPayment,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final payment = _payment;

    if (payment == null) {
      return const Center(child: Text('Không tìm thấy payment.'));
    }

    final bool isCash = _paymentService.isCashMethod(payment.method);

    final qrPayload = _paymentService.buildDemoQrPayload(payment);

    return RefreshIndicator(
      onRefresh: _loadPayment,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: Colors.orange),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Đây là màn hình thanh toán mô phỏng',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          AppCard(
            child: Column(
              children: [
                _infoRow('Mã đơn', '#${payment.orderId}'),
                _infoRow('Phương thức', payment.method),
                _infoRow('Số tiền', _formatPrice(payment.amount)),
                _infoRow('Mã giao dịch', payment.transactionCode),
                Row(
                  children: [
                    Text('Trạng thái', style: AppText.body),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(payment.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        payment.statusText,
                        style: TextStyle(
                          color: _statusColor(payment.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (isCash)
            AppCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 54,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 10),
                  Text('Thanh toán khi nhận hàng', style: AppText.productTitle),
                  const SizedBox(height: 6),
                  const Text(
                    'COD không cần QR. Payment sẽ giữ trạng thái unpaid '
                    'cho đến khi quy trình giao hàng xác nhận thu tiền.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            AppCard(
              child: Column(
                children: [
                  Text('QR thanh toán demo', style: AppText.productTitle),
                  const SizedBox(height: 6),
                  Text(
                    payment.isPaid
                        ? 'Payment đã được xác nhận.'
                        : 'Quét QR chỉ để minh họa giao diện. '
                            'Dùng nút mô phỏng phía dưới để kiểm thử callback.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    qrPayload,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            if (payment.isPending) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _simulateSuccess,
                  icon: const Icon(Icons.check_circle_outline),
                  label:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Mô phỏng thanh toán thành công'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _simulateFailure,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Mô phỏng giao dịch thất bại'),
                ),
              ),
            ],

            if (payment.isFailed)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử thanh toán lại'),
                ),
              ),

            if (payment.isPaid)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thanh toán đã được xác nhận thành công.',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.orderDetail,
                  arguments: widget.orderId,
                );
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Xem chi tiết đơn hàng'),
            ),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: TextStyle(color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
