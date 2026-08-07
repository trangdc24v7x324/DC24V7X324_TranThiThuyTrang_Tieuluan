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

  bool get isPersonal => targetRole == 'personal';
  bool get isForCustomer => targetRole == 'customer';
  bool get isForManager => targetRole == 'manager';
  bool get isForAll => targetRole == 'all';

  bool get isOrderNotification => type == 'order';
  bool get hasOrder => orderId.isNotEmpty;

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
