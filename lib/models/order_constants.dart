class OrderStatus {
  static const String placed = 'placed';
  static const String confirmed = 'confirmed';
  static const String preparing = 'preparing';
  static const String delivering = 'delivering';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> values = [
    placed,
    confirmed,
    preparing,
    delivering,
    completed,
    cancelled,
  ];

  static String label(String status) {
    switch (status) {
      case placed:
        return 'Đã đặt hàng';
      case confirmed:
        return 'Đã xác nhận';
      case preparing:
        return 'Đang chuẩn bị';
      case delivering:
        return 'Đang giao';
      case completed:
        return 'Hoàn thành';
      case cancelled:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }
}

class PaymentStatus {
  static const String unpaid = 'unpaid';
  static const String paid = 'paid';
  static const String failed = 'failed';

  static String label(String status) {
    switch (status) {
      case unpaid:
        return 'Chưa thanh toán';
      case paid:
        return 'Đã thanh toán';
      case failed:
        return 'Thanh toán lỗi';
      default:
        return 'Không xác định';
    }
  }
}

class UserRole {
  static const String customer = 'customer';
  static const String manager = 'manager';
}

class NotificationTargetRole {
  static const String customer = 'customer';
  static const String manager = 'manager';
  static const String personal = 'personal';
  static const String all = 'all';
}
