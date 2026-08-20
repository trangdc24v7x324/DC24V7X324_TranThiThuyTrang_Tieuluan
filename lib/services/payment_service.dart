// FILE HỌC TẬP: lib/services/payment_service.dart
// Vai trò: Service nghiệp vụ thanh toán.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/payment_record_model.dart';

// Lớp PaymentService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class PaymentService {
  static const String collectionName = 'payments';

  // =========================================================
  // METHOD
  // =========================================================

  // Kiểm tra điều kiện (isCashMethod): đánh giá trạng thái cash phương thức và trả kết quả cho lớp gọi.
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

  // Xử lý initialStatusForMethod: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ thanh toán.
  String initialStatusForMethod(String method) {
    return isCashMethod(method) ? 'unpaid' : 'pending';
  }

  // =========================================================
  // CREATE
  // =========================================================

  // Xử lý ban đầu thanh toán (ensureInitialPayment): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
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
  // Lấy or create for đơn hàng (fetchOrCreateForOrder): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

  // Lấy by đơn hàng mã (fetchByOrderId): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

  // Tải payment theo nhiều đơn: một request rồi lấy record mới nhất của từng order.
  // Lấy latest by đơn hàng các mã (fetchLatestByOrderIds): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
  Future<Map<String, PaymentRecordModel>> fetchLatestByOrderIds(
    Iterable<String> orderIds,
  ) async {
    final wanted =
        orderIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();

    if (wanted.isEmpty) {
      return <String, PaymentRecordModel>{};
    }

    final records = await pb
        .collection(collectionName)
        .getFullList(sort: '-updated');

    final result = <String, PaymentRecordModel>{};

    for (final record in records) {
      final orderId = (record.data['order'] ?? '').toString().trim();

      if (!wanted.contains(orderId) || result.containsKey(orderId)) {
        continue;
      }

      result[orderId] = _fromRecord(record);

      if (result.length == wanted.length) {
        break;
      }
    }

    return result;
  }

  // Lấy by mã (fetchById): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

  // Xử lý thanh toán (_resolvePayment): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
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

  // Đánh dấu demo đã thanh toán (markDemoPaid): cập nhật cờ trạng thái của dữ liệu và đồng bộ giao diện.
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

  // Đánh dấu demo failed (markDemoFailed): cập nhật cờ trạng thái của dữ liệu và đồng bộ giao diện.
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

  // Nghiệp vụ retryDemoPayment: truy vấn/cập nhật PocketBase và trả dữ liệu cho service nghiệp vụ thanh toán.
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

  // Tạo giao diện demo qr payload (buildDemoQrPayload): dựng widget con từ dữ liệu hiện tại.
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

  // Xử lý _fromRecord: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ thanh toán.
  PaymentRecordModel _fromRecord(dynamic record) {
    return PaymentRecordModel.fromJson({
      'id': record.id,
      ...record.data,
      'created': record.created,
      'updated': record.updated,
    });
  }

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ thanh toán.
  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
