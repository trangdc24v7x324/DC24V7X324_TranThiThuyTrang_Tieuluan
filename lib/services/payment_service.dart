import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/payment_record_model.dart';

class PaymentService {
  static const String collectionName = 'payments';

  // =========================================================
  // METHOD
  // =========================================================

  bool isCashMethod(String method) {
    final value = method.toLowerCase().trim();

    return value == 'cash' ||
        value == 'cod' ||
        value.contains('tiền mặt') ||
        value.contains('tien mat') ||
        value.contains('nhận hàng') ||
        value.contains('nhan hang') ||
        value.contains('cash');
  }

  String initialStatusForMethod(String method) {
    return isCashMethod(method) ? 'unpaid' : 'pending';
  }

  // =========================================================
  // CREATE
  // =========================================================

  Future<PaymentRecordModel> ensureInitialPayment({
    required String orderId,
    required String method,
    required double amount,
  }) async {
    final normalizedOrderId = orderId.trim();
    final normalizedMethod = method.trim();

    if (normalizedOrderId.isEmpty) {
      throw Exception('Thiếu orderId để tạo payment.');
    }

    if (normalizedMethod.isEmpty) {
      throw Exception('Thiếu phương thức thanh toán.');
    }

    if (amount <= 0) {
      throw Exception('Số tiền thanh toán không hợp lệ.');
    }

    // Mỗi order chỉ dùng một payment record trong MVP.
    final existing = await fetchByOrderId(normalizedOrderId);

    if (existing != null) {
      return existing;
    }

    final status = initialStatusForMethod(normalizedMethod);

    final prefix = isCashMethod(normalizedMethod) ? 'COD' : 'QRDEMO';

    final transactionCode = '$prefix-${DateTime.now().millisecondsSinceEpoch}';

    final record = await pb
        .collection(collectionName)
        .create(
          body: {
            // Khớp DB hiện tại.
            'order': normalizedOrderId,
            'method': normalizedMethod,
            'amount': amount,
            'status': status,
            'transactionCode': transactionCode,
            'rawResponse': <String, dynamic>{
              'source': 'yourfood_mvp',
              'mode': isCashMethod(normalizedMethod) ? 'cod' : 'qr_demo',
              'createdAt': DateTime.now().toIso8601String(),
            },
          },
        );

    return _fromRecord(record);
  }

  /// Khi quay lại từ lịch sử đơn hàng:
  /// - có payment => đọc đúng record cũ
  /// - thiếu payment => dựng lại từ order hiện có
  Future<PaymentRecordModel> fetchOrCreateForOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      throw Exception('orderId không hợp lệ.');
    }

    final existing = await fetchByOrderId(normalizedOrderId);

    if (existing != null) {
      return existing;
    }

    final order = await pb.collection('orders').getOne(normalizedOrderId);

    final method = (order.data['payment_method'] ?? '').toString().trim();

    final amount = _toDouble(order.data['total_amount']);

    if (method.isEmpty) {
      throw Exception('Đơn hàng chưa có phương thức thanh toán.');
    }

    return ensureInitialPayment(
      orderId: normalizedOrderId,
      method: method,
      amount: amount,
    );
  }

  // =========================================================
  // READ
  // =========================================================

  Future<PaymentRecordModel?> fetchByOrderId(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      return null;
    }

    final records = await pb
        .collection(collectionName)
        .getFullList(filter: 'order = "$normalizedOrderId"', sort: '-updated');

    if (records.isEmpty) {
      return null;
    }

    return _fromRecord(records.first);
  }

  Future<PaymentRecordModel> fetchById(String paymentId) async {
    final normalizedPaymentId = paymentId.trim();

    if (normalizedPaymentId.isEmpty) {
      throw Exception('paymentId không hợp lệ.');
    }

    final records = await pb
        .collection(collectionName)
        .getFullList(filter: 'id = "$normalizedPaymentId"', sort: '-updated');

    if (records.isEmpty) {
      throw Exception('Không tìm thấy payment hiện tại.');
    }

    return _fromRecord(records.first);
  }

  Future<PaymentRecordModel> _resolvePayment({
    required String paymentId,
    required String orderId,
  }) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      throw Exception('orderId không hợp lệ.');
    }

    final byOrder = await fetchByOrderId(normalizedOrderId);

    if (byOrder != null) {
      return byOrder;
    }

    return fetchOrCreateForOrder(normalizedOrderId);
  }

  // =========================================================
  // DEMO STATUS
  // Existing DB statuses only:
  // unpaid / pending / paid / failed
  // =========================================================

  Future<void> markDemoPaid({
    required String paymentId,
    required String orderId,
    String providerCode = '',
  }) async {
    final payment = await _resolvePayment(
      paymentId: paymentId,
      orderId: orderId,
    );

    if (payment.status == 'paid') {
      return;
    }

    final code =
        providerCode.trim().isNotEmpty
            ? providerCode.trim()
            : 'DEMO-PAID-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await pb
          .collection(collectionName)
          .update(
            payment.id,
            body: {
              'status': 'paid',
              'transactionCode': code,
              'rawResponse': <String, dynamic>{
                'source': 'yourfood_demo',
                'result': 'success',
                'confirmedAt': DateTime.now().toIso8601String(),
              },
            },
          );
    } catch (e) {
      throw Exception(
        'Không thể cập nhật payment sang paid. '
        'Hãy kiểm tra Update rule của collection payments. Chi tiết: $e',
      );
    }
  }

  Future<void> markDemoFailed({
    required String paymentId,
    required String orderId,
    String reason = '',
  }) async {
    final payment = await _resolvePayment(
      paymentId: paymentId,
      orderId: orderId,
    );

    if (payment.status == 'paid') {
      throw Exception(
        'Payment đã thanh toán thành công, '
        'không thể chuyển sang thất bại.',
      );
    }

    try {
      await pb
          .collection(collectionName)
          .update(
            payment.id,
            body: {
              'status': 'failed',
              'rawResponse': <String, dynamic>{
                'source': 'yourfood_demo',
                'result': 'failed',
                'reason':
                    reason.trim().isEmpty
                        ? 'Mô phỏng giao dịch thất bại'
                        : reason.trim(),
                'failedAt': DateTime.now().toIso8601String(),
              },
            },
          );
    } catch (e) {
      throw Exception(
        'Không thể cập nhật payment sang failed. '
        'Hãy kiểm tra Update rule của collection payments. Chi tiết: $e',
      );
    }
  }

  Future<void> retryDemoPayment({
    required String paymentId,
    required String orderId,
  }) async {
    final payment = await _resolvePayment(
      paymentId: paymentId,
      orderId: orderId,
    );

    if (payment.status == 'paid') {
      return;
    }

    try {
      await pb
          .collection(collectionName)
          .update(
            payment.id,
            body: {
              'status': 'pending',
              'rawResponse': <String, dynamic>{
                'source': 'yourfood_demo_retry',
                'result': 'pending',
                'retriedAt': DateTime.now().toIso8601String(),
              },
            },
          );
    } catch (e) {
      throw Exception(
        'Không thể đưa payment về pending. '
        'Hãy kiểm tra Update rule của collection payments. Chi tiết: $e',
      );
    }
  }

  // =========================================================
  // QR DEMO
  // =========================================================

  String buildDemoQrPayload(PaymentRecordModel payment) {
    return [
      'YOURFOOD',
      'PAYMENT_DEMO',
      'ORDER=${payment.orderId}',
      'AMOUNT=${payment.amount.round()}',
      'TX=${payment.transactionCode}',
    ].join('|');
  }

  // =========================================================
  // INTERNAL
  // =========================================================

  PaymentRecordModel _fromRecord(dynamic record) {
    return PaymentRecordModel.fromJson({
      'id': record.id,
      ...record.data,
      'created': record.created,
      'updated': record.updated,
    });
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
