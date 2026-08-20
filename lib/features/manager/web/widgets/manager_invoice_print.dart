// FILE HỌC TẬP: lib/features/manager/web/widgets/manager_invoice_print.dart
// Vai trò: Widget Web dùng cho hóa đơn in.
// Luồng sử dụng: Đóng gói thành phần giao diện hoặc tiện ích dùng lại trong khu vực Manager Web.

export 'manager_invoice_print_stub.dart'
    if (dart.library.html) 'manager_invoice_print_web.dart';
