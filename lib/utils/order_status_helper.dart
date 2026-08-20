// FILE HỌC TẬP: lib/utils/order_status_helper.dart
// Vai trò: Tiện ích hỗ trợ trạng thái đơn hàng.
// Luồng sử dụng: Cung cấp hàm thuần để chuẩn hóa/biến đổi dữ liệu dùng ở nhiều lớp.

import 'package:flutter/material.dart';

// Lớp OrderStatusHelper: thành phần phục vụ tiện ích hỗ trợ trạng thái đơn hàng.
class OrderStatusHelper {
  // Lấy văn bản (getText): truy xuất và trả kết quả cho lớp gọi.
  static String getText(String status) {
    switch (status) {
      case 'placed':
        return 'Đặt hàng thành công';
      case 'confirmed':
        return 'Quán xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao hàng';
      case 'completed':
        return 'Giao thành công';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  // Lấy color (getColor): truy xuất và trả kết quả cho lớp gọi.
  static Color getColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
        return Colors.deepOrange;
      case 'delivering':
        return Colors.purple;
      case 'completed':
        return Colors.green; 
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
