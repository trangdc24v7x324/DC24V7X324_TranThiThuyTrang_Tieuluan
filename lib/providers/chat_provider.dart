
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/chat_message_model.dart';
import 'package:project_trangdc24v7x324/services/chat_service.dart';

class ChatRoomSummary {
  final String userId;
  final String fullName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime? lastTime;
  final int unreadCount;

  const ChatRoomSummary({
    required this.userId,
    required this.fullName,
    this.avatarUrl = '',
    this.lastMessage = '',
    this.lastTime,
    this.unreadCount = 0,
  });

  ChatRoomSummary copyWith({
    String? userId,
    String? fullName,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastTime,
    int? unreadCount,
  }) {
    return ChatRoomSummary(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  final List<ChatMessageModel> _messages = [];
  final List<ChatRoomSummary> _rooms = [];

  bool _isLoading = false;
  bool _isSending = false;

  int _unreadCount = 0;
  int _totalRooms = 0;

  String? _errorMessage;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  List<ChatRoomSummary> get rooms => List.unmodifiable(_rooms);

  bool get isLoading => _isLoading;

  bool get isSending => _isSending;

  int get unreadCount => _unreadCount;

  int get totalRooms => _totalRooms;

  String? get errorMessage => _errorMessage;

  bool get hasUnread => _unreadCount > 0;

  Future<void> loadMessages({
    required String currentUserId,
    required String otherUserId,
    bool markRead = true,
  }) async {
    if (currentUserId.trim().isEmpty || otherUserId.trim().isEmpty) {
      _errorMessage = 'Thiếu thông tin người gửi hoặc người nhận';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _chatService.getMessages(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      _messages
        ..clear()
        ..addAll(result);

      _sortMessages();

      if (markRead) {
        await _markConversationAsRead(
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          reloadSummary: false,
        );
      }
    } catch (e) {
      _errorMessage = 'Không thể tải tin nhắn: $e';
      debugPrint('loadMessages error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final text = content.trim();

    if (senderId.trim().isEmpty || receiverId.trim().isEmpty) {
      _errorMessage = 'Thiếu người gửi hoặc người nhận';
      notifyListeners();
      return false;
    }

    if (text.isEmpty) {
      _errorMessage = 'Nội dung tin nhắn đang trống';
      notifyListeners();
      return false;
    }

    if (_isSending) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _chatService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: text,
      );

      final exists = _messages.any((item) => item.id == message.id);

      if (!exists) {
        _messages.add(message);
        _sortMessages();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gửi tin nhắn thất bại: $e';
      debugPrint('sendMessage error: $e');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> subscribeMessages({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.trim().isEmpty || otherUserId.trim().isEmpty) {
      return;
    }

    await _chatService.unsubscribeMessages();

    await _chatService.subscribeMessages(
      onMessage: (event) async {
        final record = event.record;

        if (record == null) return;

        final senderId = record.data['sender']?.toString() ?? '';

        final receiverId = record.data['receiver']?.toString() ?? '';

        final isRelated =
            (senderId == currentUserId && receiverId == otherUserId) ||
            (senderId == otherUserId && receiverId == currentUserId);

        if (!isRelated) return;

        if (event.action == 'delete') {
          _messages.removeWhere((message) => message.id == record.id);
          notifyListeners();
          return;
        }

        final message = ChatMessageModel.fromJson({
          'id': record.id,
          ...record.data,
          'created': record.created,
          'updated': record.updated,
        });

        final index = _messages.indexWhere((item) => item.id == message.id);

        if (index == -1) {
          _messages.add(message);
        } else {
          _messages[index] = message;
        }

        _sortMessages();

        if (message.receiverId == currentUserId && !message.isRead) {
          await markAsRead(message.id);
        }

        notifyListeners();
      },
    );
  }

  Future<void> unsubscribe() async {
    await _chatService.unsubscribeMessages();
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _chatService.markAsRead(messageId);

      final index = _messages.indexWhere((message) => message.id == messageId);

      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    await _markConversationAsRead(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      reloadSummary: true,
    );
  }

  Future<void> _markConversationAsRead({
    required String currentUserId,
    required String otherUserId,
    required bool reloadSummary,
  }) async {
    try {
      await _chatService.markAllAsRead(
        senderId: otherUserId,
        receiverId: currentUserId,
      );

      for (int i = 0; i < _messages.length; i++) {
        final item = _messages[i];

        if (item.senderId == otherUserId &&
            item.receiverId == currentUserId &&
            !item.isRead) {
          _messages[i] = item.copyWith(isRead: true);
        }
      }

      if (reloadSummary) {
        await loadChatSummary(userId: currentUserId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('markConversationAsRead error: $e');
    }
  }

  Future<void> loadCustomerChatSummary({required String customerId}) async {
    await loadChatSummary(userId: customerId);
  }

  Future<void> loadManagerChatSummary({required String managerId}) async {
    await loadChatSummary(userId: managerId);
  }

  Future<void> loadChatSummary({required String userId}) async {
    if (userId.trim().isEmpty) {
      clearRooms();
      return;
    }

    try {
      final records = await _chatService.getUserChatRecords(userId: userId);

      final Map<String, ChatRoomSummary> groupedRooms = {};

      int unread = 0;

      for (final record in records) {
        final senderId = record.data['sender']?.toString() ?? '';

        final receiverId = record.data['receiver']?.toString() ?? '';

        if (senderId.isEmpty || receiverId.isEmpty) {
          continue;
        }

        final otherUserId = senderId == userId ? receiverId : senderId;

        if (otherUserId.isEmpty || otherUserId == userId) {
          continue;
        }

        final isUnreadForMe =
            receiverId == userId && record.data['isRead'] == false;

        if (isUnreadForMe) {
          unread++;
        }

        final created = DateTime.tryParse(record.created)?.toLocal();

        final content = record.data['content']?.toString() ?? '';

        final userInfo = _extractOtherUserInfo(
          record: record,
          otherUserId: otherUserId,
        );

        final oldRoom = groupedRooms[otherUserId];

        if (oldRoom == null) {
          groupedRooms[otherUserId] = ChatRoomSummary(
            userId: otherUserId,
            fullName: userInfo['fullName'] ?? 'Người dùng',
            avatarUrl: userInfo['avatarUrl'] ?? '',
            lastMessage: content,
            lastTime: created,
            unreadCount: isUnreadForMe ? 1 : 0,
          );
          continue;
        }

        final oldTime =
            oldRoom.lastTime ?? DateTime.fromMillisecondsSinceEpoch(0);

        final newTime = created ?? DateTime.fromMillisecondsSinceEpoch(0);

        final shouldReplace = newTime.isAfter(oldTime);

        groupedRooms[otherUserId] = oldRoom.copyWith(
          fullName: userInfo['fullName'] ?? oldRoom.fullName,
          avatarUrl: userInfo['avatarUrl'] ?? oldRoom.avatarUrl,
          lastMessage: shouldReplace ? content : oldRoom.lastMessage,
          lastTime: shouldReplace ? created : oldRoom.lastTime,
          unreadCount: oldRoom.unreadCount + (isUnreadForMe ? 1 : 0),
        );
      }

      _rooms
        ..clear()
        ..addAll(groupedRooms.values);

      _rooms.sort((a, b) {
        final aTime = a.lastTime ?? DateTime.fromMillisecondsSinceEpoch(0);

        final bTime = b.lastTime ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bTime.compareTo(aTime);
      });

      _unreadCount = unread;
      _totalRooms = _rooms.length;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách trò chuyện: $e';
      debugPrint('loadChatSummary error: $e');
      notifyListeners();
    }
  }

  Future<String?> getManagerId() async {
    try {
      _errorMessage = null;

      final managerId = await _chatService.getManagerId();

      if (managerId == null || managerId.trim().isEmpty) {
        _errorMessage = 'Không tìm thấy tài khoản quản lý';
      }

      return managerId;
    } catch (e) {
      _errorMessage = 'Không thể tìm tài khoản quản lý: $e';
      debugPrint('getManagerId error: $e');
      notifyListeners();
      return null;
    }
  }

  String getMessageStatusText({
    required ChatMessageModel message,
    required String currentUserId,
  }) {
    if (message.senderId != currentUserId) {
      return '';
    }

    return message.isRead ? 'Đã xem' : 'Đã gửi';
  }

  bool isMessageMine({
    required ChatMessageModel message,
    required String currentUserId,
  }) {
    return message.senderId == currentUserId;
  }

  bool isMessageUnreadForMe({
    required ChatMessageModel message,
    required String currentUserId,
  }) {
    return message.receiverId == currentUserId && !message.isRead;
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void clearRooms() {
    _rooms.clear();
    _unreadCount = 0;
    _totalRooms = 0;
    notifyListeners();
  }

  void clearAll() {
    _messages.clear();
    _rooms.clear();
    _unreadCount = 0;
    _totalRooms = 0;
    _errorMessage = null;
    notifyListeners();
  }

  void _sortMessages() {
    _messages.sort((a, b) => a.created.compareTo(b.created));
  }

  Map<String, String> _extractOtherUserInfo({
    required RecordModel record,
    required String otherUserId,
  }) {
    try {
      final expand = record.expand;
      RecordModel? userRecord;

      final senderId = record.data['sender']?.toString() ?? '';

      final receiverId = record.data['receiver']?.toString() ?? '';

      if (senderId == otherUserId &&
          expand['sender'] != null &&
          expand['sender']!.isNotEmpty) {
        userRecord = expand['sender']!.first;
      } else if (receiverId == otherUserId &&
          expand['receiver'] != null &&
          expand['receiver']!.isNotEmpty) {
        userRecord = expand['receiver']!.first;
      }

      if (userRecord == null) {
        return {'fullName': 'Người dùng', 'avatarUrl': ''};
      }

      final data = userRecord.data;

      final fullName = data['fullName']?.toString().trim() ?? '';

      final avatarFile = data['avatar']?.toString().trim() ?? '';

      String avatarUrl = '';

      if (avatarFile.isNotEmpty) {
        avatarUrl =
            '${pb.baseUrl}/api/files/users/'
            '${userRecord.id}/$avatarFile';
      }

      return {
        'fullName': fullName.isEmpty ? 'Người dùng' : fullName,
        'avatarUrl': avatarUrl,
      };
    } catch (_) {
      return {'fullName': 'Người dùng', 'avatarUrl': ''};
    }
  }
}
