// FILE HỌC TẬP: lib/features/manager/web/widgets/manager_invoice_print_web.dart
// Vai trò: Widget Web dùng cho hóa đơn in web.
// Luồng sử dụng: Đóng gói thành phần giao diện hoặc tiện ích dùng lại trong khu vực Manager Web.

import 'dart:convert';
import 'dart:js_interop';

import 'package:project_trangdc24v7x324/models/order_model.dart';

@JS('window.open')
external JSAny? _openBrowserWindow(String url, String target);

// In hóa đơn (printManagerInvoice): dựng nội dung hóa đơn và gọi cơ chế in phù hợp nền tảng.
void printManagerInvoice({required OrderModel order}) {
  final htmlContent = _buildInvoiceHtml(order);

  final uri = Uri.dataFromString(
    htmlContent,
    mimeType: 'text/html',
    encoding: utf8,
  );

  // Mở hóa đơn ở cửa sổ riêng. Script trong trang sẽ tự mở hộp thoại in.
  _openBrowserWindow(uri.toString(), '_blank');
}

// Tạo giao diện hóa đơn html (_buildInvoiceHtml): dựng widget con từ dữ liệu hiện tại.
String _buildInvoiceHtml(OrderModel order) {
  final rows =
      order.items.map((item) {
        return '''
      <tr>
        <td>
          <strong>${_escape(item.productName)}</strong>
          ${item.note.trim().isEmpty ? '' : '<div class="note">Ghi chú: ${_escape(item.note)}</div>'}
        </td>
        <td class="center">${item.quantity}</td>
        <td class="right">${_money(item.unitPrice)}</td>
        <td class="right">${_money(item.subtotal)}</td>
      </tr>
    ''';
      }).join();

  return '''
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Hóa đơn ${_escape(_shortId(order.id))}</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #f4f6f8;
      color: #111827;
      font-family: Arial, Helvetica, sans-serif;
    }
    .sheet {
      width: min(860px, calc(100% - 32px));
      margin: 28px auto;
      padding: 34px;
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 18px;
      box-shadow: 0 12px 40px rgba(15, 23, 42, .08);
    }
    .header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 24px;
      padding-bottom: 22px;
      border-bottom: 2px solid #111827;
    }
    .brand { font-size: 28px; font-weight: 900; color: #ff3d4f; }
    .subtitle { margin-top: 6px; color: #64748b; }
    .invoice-title { text-align: right; }
    .invoice-title h1 { margin: 0 0 6px; font-size: 25px; }
    .invoice-title div { color: #64748b; line-height: 1.55; }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 22px;
      margin: 24px 0;
    }
    .box {
      padding: 16px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 14px;
      line-height: 1.65;
    }
    .box h3 { margin: 0 0 8px; font-size: 14px; text-transform: uppercase; color: #475569; }
    table { width: 100%; border-collapse: collapse; }
    th {
      padding: 12px 10px;
      background: #f1f5f9;
      color: #475569;
      font-size: 12px;
      text-align: left;
      border-bottom: 1px solid #cbd5e1;
    }
    td {
      padding: 13px 10px;
      border-bottom: 1px solid #e5e7eb;
      vertical-align: top;
    }
    .right { text-align: right; white-space: nowrap; }
    .center { text-align: center; }
    .note { margin-top: 5px; color: #64748b; font-size: 12px; }
    .totals {
      width: min(390px, 100%);
      margin: 22px 0 0 auto;
    }
    .total-row {
      display: flex;
      justify-content: space-between;
      gap: 18px;
      padding: 7px 0;
    }
    .grand {
      margin-top: 8px;
      padding-top: 13px;
      border-top: 2px solid #111827;
      font-size: 20px;
      font-weight: 900;
      color: #dc2626;
    }
    .footer {
      margin-top: 34px;
      padding-top: 18px;
      border-top: 1px dashed #94a3b8;
      color: #64748b;
      text-align: center;
      line-height: 1.6;
    }
    .badge {
      display: inline-block;
      padding: 5px 9px;
      border-radius: 999px;
      background: #ecfdf5;
      color: #047857;
      font-size: 12px;
      font-weight: 700;
    }
    @media (max-width: 640px) {
      .sheet { width: 100%; margin: 0; border-radius: 0; padding: 20px; }
      .header, .grid { display: block; }
      .invoice-title { text-align: left; margin-top: 18px; }
      .box + .box { margin-top: 12px; }
    }
    @media print {
      body { background: #fff; }
      .sheet {
        width: 100%;
        margin: 0;
        padding: 0;
        border: 0;
        border-radius: 0;
        box-shadow: none;
      }
      @page { size: A4; margin: 14mm; }
    }
  </style>
</head>
<body>
  <main class="sheet">
    <section class="header">
      <div>
        <div class="brand">YourFood</div>
        <div class="subtitle">Hệ thống đặt món và quản lý đơn hàng</div>
      </div>
      <div class="invoice-title">
        <h1>HÓA ĐƠN BÁN HÀNG</h1>
        <div>Mã đơn: <strong>#${_escape(_shortId(order.id))}</strong></div>
        <div>Ngày lập: ${_date(order.orderDate)}</div>
      </div>
    </section>

    <section class="grid">
      <div class="box">
        <h3>Thông tin khách hàng</h3>
        <div><strong>${_escape(order.receiverName.isEmpty ? 'Khách hàng' : order.receiverName)}</strong></div>
        <div>Điện thoại: ${_escape(order.receiverPhone)}</div>
        <div>Địa chỉ: ${_escape(order.deliveryAddress)}</div>
      </div>
      <div class="box">
        <h3>Thông tin đơn hàng</h3>
        <div>Phương thức: ${_escape(order.paymentMethod)}</div>
        <div>Thanh toán: <span class="badge">${_escape(_paymentLabel(order.paymentStatus))}</span></div>
        <div>Trạng thái: ${_escape(_statusLabel(order.orderStatus))}</div>
      </div>
    </section>

    <table>
      <thead>
        <tr>
          <th>Sản phẩm</th>
          <th class="center">SL</th>
          <th class="right">Đơn giá</th>
          <th class="right">Thành tiền</th>
        </tr>
      </thead>
      <tbody>
        $rows
      </tbody>
    </table>

    <section class="totals">
      <div class="total-row"><span>Tạm tính</span><strong>${_money(order.subtotal)}</strong></div>
      <div class="total-row"><span>Giảm giá</span><strong>-${_money(order.discountAmount)}</strong></div>
      <div class="total-row"><span>Phí giao hàng</span><strong>${_money(order.deliveryFee)}</strong></div>
      <div class="total-row grand"><span>Tổng cộng</span><span>${_money(order.totalAmount)}</span></div>
    </section>

    ${order.note.trim().isEmpty ? '' : '''
      <section class="box" style="margin-top:24px">
        <h3>Ghi chú đơn hàng</h3>
        <div>${_escape(order.note)}</div>
      </section>
    '''}

    <footer class="footer">
      Đây là hóa đơn mô phỏng phục vụ trình diễn chức năng của hệ thống YourFood.<br>
      Cảm ơn quý khách đã sử dụng dịch vụ.
    </footer>
  </main>
  <script>
    window.addEventListener('load', function () {
      setTimeout(function () { window.print(); }, 350);
    });
  </script>
</body>
</html>
''';
}

// Xử lý _escape: thực hiện phần nghiệp vụ tương ứng trong widget web dùng cho hóa đơn in web.
String _escape(String value) {
  return const HtmlEscape().convert(value);
}

// Xử lý _shortId: thực hiện phần nghiệp vụ tương ứng trong widget web dùng cho hóa đơn in web.
String _shortId(String id) {
  final value = id.trim().toUpperCase();
  return value.length <= 10 ? value : value.substring(0, 10);
}

// Xử lý _date: thực hiện phần nghiệp vụ tương ứng trong widget web dùng cho hóa đơn in web.
String _date(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}

// Xử lý _money: thực hiện phần nghiệp vụ tương ứng trong widget web dùng cho hóa đơn in web.
String _money(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
  }

  return '$bufferđ';
}

// Xử lý _statusLabel: thực hiện phần nghiệp vụ tương ứng trong widget web dùng cho hóa đơn in web.
String _statusLabel(String status) {
  switch (status) {
    case 'placed':
      return 'Chờ xác nhận';
    case 'confirmed':
      return 'Đã xác nhận';
    case 'preparing':
      return 'Đang chuẩn bị';
    case 'delivering':
      return 'Đang giao';
    case 'completed':
      return 'Hoàn thành';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return status;
  }
}

// Xử lý _paymentLabel: thực hiện phần nghiệp vụ tương ứng trong widget web dùng cho hóa đơn in web.
String _paymentLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Đã thanh toán';
    case 'pending':
      return 'Chờ xác nhận';
    case 'failed':
      return 'Thanh toán lỗi';
    default:
      return 'Chưa thanh toán';
  }
}
