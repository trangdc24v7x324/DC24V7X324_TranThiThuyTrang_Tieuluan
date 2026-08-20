// FILE HỌC TẬP: lib/services/chat_service.dart
// Vai trò: Service nghiệp vụ trò chuyện.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/chat_message_model.dart';
import 'package:pocketbase/pocketbase.dart';

// Lớp ChatService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class ChatService {
  // Nghiệp vụ _escapeFilterValue: truy vấn/cập nhật PocketBase và trả dữ liệu cho service nghiệp vụ trò chuyện.
  String _escapeFilterValue(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }

  Future<List<ChatMessageModel>> getMessages({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final currentId = _escapeFilterValue(currentUserId.trim());

    final otherId = _escapeFilterValue(otherUserId.trim());

    if (currentId.isEmpty || otherId.isEmpty) {
      return [];
    }

    final records = await pb
        .collection('messages')
        .getFullList(
          sort: 'created',
          filter:
              '(sender = "$currentId" && receiver = "$otherId") || '
              '(sender = "$otherId" && receiver = "$currentId")',
        );

    return records.map((record) {
      return ChatMessageModel.fromJson({
        'id': record.id,
        ...record.data,
        'created': record.created,
        'updated': record.updated,
      });
    }).toList();
  }

  Future<ChatMessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final safeSenderId = senderId.trim();
    final safeReceiverId = receiverId.trim();
    final text = content.trim();

    if (safeSenderId.isEmpty) {
      throw Exception('Không xác định được người gửi');
    }

    if (safeReceiverId.isEmpty) {
      throw Exception('Không xác định được người nhận');
    }

    if (text.isEmpty) {
      throw Exception('Nội dung tin nhắn đang trống');
    }

    final record = await pb
        .collection('messages')
        .create(
          body: {
            'sender': safeSenderId,
            'receiver': safeReceiverId,
            'content': text,
            'isRead': false,
          },
        );

    return ChatMessageModel.fromJson({
      'id': record.id,
      ...record.data,
      'created': record.created,
      'updated': record.updated,
    });
  }

  Future<void> markAsRead(String messageId) async {
    if (messageId.trim().isEmpty) return;

    await pb.collection('messages').update(messageId, body: {'isRead': true});
  }

  Future<void> markAllAsRead({
    required String senderId,
    required String receiverId,
  }) async {
    final safeSenderId = _escapeFilterValue(senderId.trim());

    final safeReceiverId = _escapeFilterValue(receiverId.trim());

    if (safeSenderId.isEmpty || safeReceiverId.isEmpty) {
      return;
    }

    final records = await pb
        .collection('messages')
        .getFullList(
          filter:
              'sender = "$safeSenderId" && '
              'receiver = "$safeReceiverId" && '
              'isRead = false',
        );

    for (final record in records) {
      await markAsRead(record.id);
    }
  }

  Future<int> countUnreadForUser({required String userId}) async {
    final safeUserId = _escapeFilterValue(userId.trim());

    if (safeUserId.isEmpty) return 0;

    final records = await pb
        .collection('messages')
        .getFullList(
          filter:
              'receiver = "$safeUserId" && '
              'isRead = false',
        );

    return records.length;
  }

  Future<List<RecordModel>> getUserChatRecords({required String userId}) async {
    final safeUserId = _escapeFilterValue(userId.trim());

    if (safeUserId.isEmpty) return [];

    return pb
        .collection('messages')
        .getFullList(
          sort: '-created',
          filter:
              'sender = "$safeUserId" || '
              'receiver = "$safeUserId"',
          expand: 'sender,receiver',
        );
  }

  Future<String?> getManagerId() async {
    try {
      final activeManager = await pb
          .collection('users')
          .getList(
            page: 1,
            perPage: 1,
            filter: 'role = "manager" && isActive = true',
          );

      if (activeManager.items.isNotEmpty) {
        return activeManager.items.first.id;
      }
    } catch (_) {
      // Cho phép schema cũ chưa có trường isActive.
    }

    final result = await pb
        .collection('users')
        .getList(page: 1, perPage: 1, filter: 'role = "manager"');

    if (result.items.isEmpty) {
      return null;
    }

    return result.items.first.id;
  }

  Future<void> subscribeMessages({
    required void Function(RecordSubscriptionEvent event) onMessage,
  }) async {
    await pb.collection('messages').subscribe('*', onMessage);
  }

  Future<void> unsubscribeMessages() async {
    await pb.collection('messages').unsubscribe('*');
  }
}
