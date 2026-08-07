import 'package:flutter/material.dart';

class OrderStatusHelper {
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
