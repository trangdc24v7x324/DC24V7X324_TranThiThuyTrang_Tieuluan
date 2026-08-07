import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/features/manager/web/widgets/manager_web_layout.dart';
import 'package:project_trangdc24v7x324/models/chat_message_model.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

class ManagerWebChatPage extends StatefulWidget {
  const ManagerWebChatPage({super.key});

  @override
  State<ManagerWebChatPage> createState() => _ManagerWebChatPageState();
}

class _ManagerWebChatPageState extends State<ManagerWebChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ChatProvider _chatProvider;
  bool _providerReady = false;

  String _managerId = '';
  ChatRoomSummary? _selectedRoom;
  bool _loadingRooms = false;
  bool _loadingConversation = false;
  String? _localError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_providerReady) {
      _chatProvider = context.read<ChatProvider>();
      _providerReady = true;

      Future.microtask(_initialize);
    }
  }

  @override
  void dispose() {
    if (_providerReady) {
      _chatProvider.unsubscribe();
    }

    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _managerId = pb.authStore.model?.id ?? '';

    await Future.wait([
      _loadRooms(autoSelect: true),
      context.read<ProfileProvider>().loadProfile(forceReload: true),
    ]);
  }

  Future<void> _loadRooms({bool autoSelect = false}) async {
    if (_managerId.isEmpty) {
      if (mounted) {
        setState(() {
          _localError = 'Không xác định được tài khoản quản lý.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loadingRooms = true;
        _localError = null;
      });
    }

    try {
      await _chatProvider.loadManagerChatSummary(managerId: _managerId);

      if (!mounted) {
        return;
      }

      final rooms = _chatProvider.rooms;

      if (_selectedRoom != null) {
        final refreshed =
            rooms
                .where((room) => room.userId == _selectedRoom!.userId)
                .toList();

        if (refreshed.isNotEmpty) {
          setState(() {
            _selectedRoom = refreshed.first;
          });
        }
      }

      if (autoSelect &&
          _selectedRoom == null &&
          rooms.isNotEmpty &&
          MediaQuery.sizeOf(context).width >= 850) {
        await _selectRoom(rooms.first);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _localError = 'Không thể tải danh sách tin nhắn: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingRooms = false;
        });
      }
    }
  }

  Future<void> _selectRoom(ChatRoomSummary room) async {
    if (_managerId.isEmpty || room.userId.isEmpty) {
      return;
    }

    setState(() {
      _selectedRoom = room;
      _loadingConversation = true;
      _localError = null;
    });

    try {
      await _chatProvider.unsubscribe();

      await _chatProvider.loadMessages(
        currentUserId: _managerId,
        otherUserId: room.userId,
        markRead: true,
      );

      await _chatProvider.subscribeMessages(
        currentUserId: _managerId,
        otherUserId: room.userId,
      );

      await _chatProvider.loadManagerChatSummary(managerId: _managerId);

      _syncSelectedRoom();
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        setState(() {
          _localError = 'Không thể mở cuộc trò chuyện: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingConversation = false;
        });
      }
    }
  }

  void _syncSelectedRoom() {
    if (_selectedRoom == null) {
      return;
    }

    final matches =
        _chatProvider.rooms
            .where((room) => room.userId == _selectedRoom!.userId)
            .toList();

    if (matches.isNotEmpty && mounted) {
      setState(() {
        _selectedRoom = matches.first;
      });
    }
  }

  Future<void> _sendMessage() async {
    final room = _selectedRoom;
    final text = _messageController.text.trim();

    if (room == null ||
        text.isEmpty ||
        _managerId.isEmpty ||
        _chatProvider.isSending) {
      return;
    }

    final success = await _chatProvider.sendMessage(
      senderId: _managerId,
      receiverId: room.userId,
      content: text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _localError = _chatProvider.errorMessage ?? 'Gửi tin nhắn thất bại';
      });
      return;
    }

    _messageController.clear();

    await _chatProvider.loadManagerChatSummary(managerId: _managerId);

    _syncSelectedRoom();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _backToRooms() {
    setState(() {
      _selectedRoom = null;
      _localError = null;
    });

    _chatProvider.clearMessages();
    _chatProvider.unsubscribe();
  }

  void _logout() {
    _chatProvider.unsubscribe();
    pb.authStore.clear();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  List<ChatRoomSummary> _filteredRooms(List<ChatRoomSummary> rooms) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return rooms;
    }

    return rooms.where((room) {
      return room.fullName.toLowerCase().contains(query) ||
          room.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final managerName =
        profile?.fullName.trim().isNotEmpty == true
            ? profile!.fullName
            : 'Manager';

    final avatarUrl = profile?.avatarUrl ?? '';

    final rooms = _filteredRooms(chatProvider.rooms);

    return ManagerWebLayout(
      title: 'Tin nhắn khách hàng',
      currentRoute: AppRoutes.managerChat,
      managerName: managerName,
      avatarUrl: avatarUrl,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Làm mới danh sách',
          onPressed: () {
            _loadRooms();
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 850;

          final availableHeight =
              constraints.hasBoundedHeight ? constraints.maxHeight - 40 : 720.0;

          final panelHeight = availableHeight.clamp(570.0, 920.0).toDouble();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth >= 1100 ? 24 : 12,
              18,
              constraints.maxWidth >= 1100 ? 24 : 12,
              22,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Container(
                  height: panelHeight,
                  constraints: const BoxConstraints(maxHeight: 920),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      desktop
                          ? Row(
                            children: [
                              SizedBox(
                                width: 360,
                                child: _buildRoomPanel(rooms, showHeader: true),
                              ),
                              const VerticalDivider(
                                width: 1,
                                color: AppColors.border,
                              ),
                              Expanded(
                                child: _buildConversationPanel(compact: false),
                              ),
                            ],
                          )
                          : _selectedRoom == null
                          ? _buildRoomPanel(rooms, showHeader: true)
                          : _buildConversationPanel(compact: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomPanel(
    List<ChatRoomSummary> rooms, {
    required bool showHeader,
  }) {
    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hộp thư khách hàng',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (_chatProvider.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_chatProvider.unreadCount} mới',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_chatProvider.totalRooms} cuộc trò chuyện',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 13),
                TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm khách hàng...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                            : null,
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child:
              _loadingRooms && _chatProvider.rooms.isEmpty
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : rooms.isEmpty
                  ? _EmptyRooms(
                    hasSearch: _searchController.text.trim().isNotEmpty,
                    onRefresh: () {
                      _loadRooms();
                    },
                  )
                  : RefreshIndicator(
                    onRefresh: () {
                      return _loadRooms();
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final room = rooms[index];

                        return _RoomTile(
                          room: room,
                          selected: _selectedRoom?.userId == room.userId,
                          onTap: () {
                            _selectRoom(room);
                          },
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildConversationPanel({required bool compact}) {
    final room = _selectedRoom;

    if (room == null) {
      return const _NoConversationSelected();
    }

    return Column(
      children: [
        _ConversationHeader(
          room: room,
          showBack: compact,
          onBack: _backToRooms,
          onRefresh: () {
            _selectRoom(room);
          },
        ),
        const Divider(height: 1, color: AppColors.border),
        if (_loadingConversation)
          const LinearProgressIndicator(minHeight: 3, color: AppColors.primary),
        if (_localError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Colors.red.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _localError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () {
                    setState(() {
                      _localError = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, provider, _) {
              final messages = provider.messages;

              if (_loadingConversation && messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (messages.isEmpty) {
                return const _EmptyConversation();
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];

                  final isMine = provider.isMessageMine(
                    message: message,
                    currentUserId: _managerId,
                  );

                  final status = provider.getMessageStatusText(
                    message: message,
                    currentUserId: _managerId,
                  );

                  return _MessageBubble(
                    message: message,
                    isMine: isMine,
                    statusText: status,
                  );
                },
              );
            },
          ),
        ),
        _MessageComposer(
          controller: _messageController,
          isSending: _chatProvider.isSending,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoomSummary room;
  final bool selected;
  final VoidCallback onTap;

  const _RoomTile({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = room.unreadCount > 0;

    return Material(
      color:
          selected
              ? AppColors.primary.withOpacity(0.08)
              : unread
              ? const Color(0xFFFFF7F7)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? AppColors.primary.withOpacity(0.25)
                      : unread
                      ? Colors.red.withOpacity(0.16)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              _Avatar(url: room.avatarUrl, name: room.fullName, radius: 24),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (room.lastTime != null)
                          Text(
                            _formatRoomTime(room.lastTime!),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage.trim().isEmpty
                                ? 'Chưa có nội dung'
                                : room.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  unread
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              room.unreadCount > 99
                                  ? '99+'
                                  : '${room.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  final ChatRoomSummary room;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _ConversationHeader({
    required this.room,
    required this.showBack,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Quay lại',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          _Avatar(url: room.avatarUrl, name: room.fullName, radius: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Kênh hỗ trợ khách hàng',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tải lại hội thoại',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final String statusText;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final time = _formatMessageTime(message.created);

    final meta = isMine && statusText.isNotEmpty ? '$time • $statusText' : time;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isMine ? AppColors.primary : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17),
                  topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(isMine ? 17 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 17),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.42,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!isSending) {
                  onSend();
                }
              },
              decoration: InputDecoration(
                hintText: 'Nhập nội dung trả lời...',
                filled: true,
                fillColor: AppColors.inputBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: isSending ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  isSending
                      ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double radius;

  const _Avatar({required this.url, required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      backgroundImage: url.trim().isEmpty ? null : NetworkImage(url),
      child:
          url.trim().isEmpty
              ? Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              )
              : null,
    );
  }
}

class _NoConversationSelected extends StatelessWidget {
  const _NoConversationSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, color: AppColors.textGrey, size: 68),
            SizedBox(height: 14),
            Text(
              'Chọn một cuộc trò chuyện',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Nội dung tin nhắn sẽ hiển thị tại khu vực này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_chat_unread_outlined,
              color: AppColors.textGrey,
              size: 56,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có nội dung tin nhắn',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Hãy gửi lời chào để bắt đầu hỗ trợ khách hàng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onRefresh;

  const _EmptyRooms({required this.hasSearch, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    color: AppColors.textGrey,
                    size: 54,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasSearch
                        ? 'Không tìm thấy khách hàng'
                        : 'Chưa có cuộc trò chuyện',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasSearch
                        ? 'Hãy thử một từ khóa khác.'
                        : 'Tin nhắn mới của khách hàng sẽ xuất hiện tại đây.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 13),
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Làm mới'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatRoomTime(DateTime time) {
  final now = DateTime.now();

  final sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;

  String two(int value) => value.toString().padLeft(2, '0');

  if (sameDay) {
    return '${two(time.hour)}:${two(time.minute)}';
  }

  return '${two(time.day)}/${two(time.month)}';
}

String _formatMessageTime(DateTime time) {
  final now = DateTime.now();

  final sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;

  String two(int value) => value.toString().padLeft(2, '0');

  if (sameDay) {
    return '${two(time.hour)}:${two(time.minute)}';
  }

  return '${two(time.hour)}:${two(time.minute)} '
      '${two(time.day)}/${two(time.month)}';
}
