// FILE HỌC TẬP: lib/models/chat_message_model.dart
// Vai trò: Mô hình dữ liệu tin nhắn trò chuyện.
// Luồng sử dụng: Chuẩn hóa dữ liệu giữa PocketBase và Dart, cung cấp ánh xạ và bản sao model.

// Lớp ChatMessageModel: biểu diễn dữ liệu nghiệp vụ và hỗ trợ ánh xạ dữ liệu vào/ra.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime created;
  final DateTime updated;

  // Khởi tạo ChatMessageModel: nhận các tham số cần thiết để tạo đối tượng cho mô hình dữ liệu tin nhắn trò chuyện.
  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    required this.created,
    required this.updated,
  });

  // Kiểm tra điều kiện (isMine): đánh giá trạng thái mine và trả kết quả cho lớp gọi.
  bool isMine(String currentUserId) {
    return senderId == currentUserId;
  }

  // Khởi tạo ChatMessageModel.fromJson: tạo đối tượng ChatMessageModel bằng constructor fromJson từ dữ liệu đầu vào.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender']?.toString() ?? '',
      receiverId: json['receiver']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
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
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
      'isRead': isRead,
    };
  }

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    bool? isRead,
    DateTime? created,
    DateTime? updated,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
