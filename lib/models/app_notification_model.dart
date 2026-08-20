// FILE HỌC TẬP: lib/models/app_notification_model.dart
// Vai trò: Mô hình dữ liệu thông báo ứng dụng.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp AppNotificationModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String targetRole;
  final String targetUser;
  final String orderId;
  final bool isRead;
  final DateTime created;
  final DateTime updated;

  // Khởi tạo AppNotificationModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu thông báo ứng dụng.
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetRole,
    this.targetUser = '',
    this.orderId = '',
    this.isRead = false,
    required this.created,
    required this.updated,
  });

  // Đọc trạng thái personal (isPersonal): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isPersonal => targetRole == 'personal';
  // Đọc trạng thái for khách hàng (isForCustomer): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isForCustomer => targetRole == 'customer';
  // Đọc trạng thái for quản lý (isForManager): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isForManager => targetRole == 'manager';
  // Đọc trạng thái for tất cả (isForAll): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isForAll => targetRole == 'all';

  // Đọc trạng thái đơn hàng thông báo (isOrderNotification): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isOrderNotification => type == 'order';
  // Đọc trạng thái có đơn hàng (hasOrder): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasOrder => orderId.isNotEmpty;

  // Khởi tạo AppNotificationModel.fromJson: tạo đối tượng AppNotificationModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      targetRole: json['targetRole']?.toString() ?? '',
      targetUser: json['targetUser']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      isRead: json['isRead'] == true,
      created:
          DateTime.tryParse(json['created']?.toString() ?? '') ??
          DateTime.now(),
      updated:
          DateTime.tryParse(json['updated']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  // Chuyển sang JSON (toJson): đóng gói model thành Map để lưu hoặc truyền sang service.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetRole': targetRole,
      if (targetUser.isNotEmpty) 'targetUser': targetUser,
      if (orderId.isNotEmpty) 'orderId': orderId,
      'isRead': isRead,
    };
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? targetRole,
    String? targetUser,
    String? orderId,
    bool? isRead,
    DateTime? created,
    DateTime? updated,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetRole: targetRole ?? this.targetRole,
      targetUser: targetUser ?? this.targetUser,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
