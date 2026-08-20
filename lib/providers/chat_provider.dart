// FILE HỌC TẬP: lib/providers/chat_provider.dart
// Vai trò: Provider quản lý trạng thái trò chuyện.
// Luồng sử dụng: Làm cầu nối UI-Service, giữ state/loading/error và thông báo thay đổi bằng notifyListeners().

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/chat_message_model.dart';
import 'package:project_trangdc24v7x324/services/chat_service.dart';

// Lớp ChatRoomSummary: thành phần phục vụ provider quản lý trạng thái trò chuyện.
class ChatRoomSummary {
  final String userId;
  final String fullName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime? lastTime;
  final int unreadCount;

  // Khởi tạo ChatRoomSummary: nhận các tham số cần thiết để tạo đối tượng cho provider quản lý trạng thái trò chuyện.
  const ChatRoomSummary({
    required this.userId,
    required this.fullName,
    this.avatarUrl = '',
    this.lastMessage = '',
    this.lastTime,
    this.unreadCount = 0,
  });

  // Sao chép model (copyWith): tạo bản mới từ dữ liệu hiện tại và thay các trường được truyền vào.
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

// Lớp ChatProvider: giữ state và điều phối dữ liệu giữa giao diện với service.
class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  final List<ChatMessageModel> _messages = [];
  final List<ChatRoomSummary> _rooms = [];

  bool _isLoading = false;
  bool _isSending = false;

  int _unreadCount = 0;
  int _totalRooms = 0;

  String? _errorMessage;

  // Đọc tin nhắn (messages): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  // Đọc phòng chat (rooms): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  List<ChatRoomSummary> get rooms => List.unmodifiable(_rooms);

  // Đọc trạng thái đang tải (isLoading): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isLoading => _isLoading;
  // Đọc trạng thái sending (isSending): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get isSending => _isSending;

  // Đọc số thông báo chưa đọc (unreadCount): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get unreadCount => _unreadCount;
  // Đọc tổng phòng chat (totalRooms): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  int get totalRooms => _totalRooms;

  // Đọc thông báo lỗi (errorMessage): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  String? get errorMessage => _errorMessage;

  // Đọc trạng thái có chưa đọc (hasUnread): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  bool get hasUnread => _unreadCount > 0;

  // Tải tin nhắn (loadMessages): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
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

  // Gửi tin nhắn (sendMessage): kiểm tra nội dung rồi chuyển tới service/backend và xử lý kết quả.
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

  // Xử lý subscribeMessages: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái trò chuyện.
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

  // Cập nhật state (unsubscribe): thay đổi dữ liệu nội bộ rồi gọi notifyListeners() để UI nhận state mới.
  Future<void> unsubscribe() async {
    await _chatService.unsubscribeMessages();
  }

  // Đánh dấu đã đọc (markAsRead): cập nhật một thông báo thành đã đọc và đồng bộ state.
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

  // Đánh dấu tất cả đã đọc (markAllAsRead): cập nhật toàn bộ thông báo chưa đọc của người dùng.
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

  // Đánh dấu hội thoại as đã đọc (_markConversationAsRead): cập nhật cờ trạng thái của dữ liệu và đồng bộ giao diện.
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

  // Tải khách hàng trò chuyện tổng hợp (loadCustomerChatSummary): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadCustomerChatSummary({required String customerId}) async {
    await loadChatSummary(userId: customerId);
  }

  // Tải quản lý trò chuyện tổng hợp (loadManagerChatSummary): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> loadManagerChatSummary({required String managerId}) async {
    await loadChatSummary(userId: managerId);
  }

  // Tải trò chuyện tổng hợp (loadChatSummary): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
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

  // Lấy quản lý mã (getManagerId): truy xuất và trả kết quả cho lớp gọi.
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

  // Lấy tin nhắn trạng thái văn bản (getMessageStatusText): truy xuất và trả kết quả cho lớp gọi.
  String getMessageStatusText({
    required ChatMessageModel message,
    required String currentUserId,
  }) {
    if (message.senderId != currentUserId) {
      return '';
    }

    return message.isRead ? 'Đã xem' : 'Đã gửi';
  }

  // Kiểm tra điều kiện (isMessageMine): đánh giá trạng thái tin nhắn mine và trả kết quả cho lớp gọi.
  bool isMessageMine({
    required ChatMessageModel message,
    required String currentUserId,
  }) {
    return message.senderId == currentUserId;
  }

  // Kiểm tra điều kiện (isMessageUnreadForMe): đánh giá trạng thái tin nhắn chưa đọc for me và trả kết quả cho lớp gọi.
  bool isMessageUnreadForMe({
    required ChatMessageModel message,
    required String currentUserId,
  }) {
    return message.receiverId == currentUserId && !message.isRead;
  }

  // Xóa tin nhắn (clearMessages): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Xóa phòng chat (clearRooms): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearRooms() {
    _rooms.clear();
    _unreadCount = 0;
    _totalRooms = 0;
    notifyListeners();
  }

  // Xóa tất cả (clearAll): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void clearAll() {
    _messages.clear();
    _rooms.clear();
    _unreadCount = 0;
    _totalRooms = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // Lọc/tìm tin nhắn (_sortMessages): tạo tập dữ liệu phù hợp theo điều kiện đang chọn.
  void _sortMessages() {
    _messages.sort((a, b) => a.created.compareTo(b.created));
  }

  // Xử lý _extractOtherUserInfo: thực hiện phần nghiệp vụ tương ứng trong provider quản lý trạng thái trò chuyện.
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
