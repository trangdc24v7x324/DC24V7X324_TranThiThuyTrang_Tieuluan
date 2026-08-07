import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/chat_message_model.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.otherUserId,
    this.otherUserName = 'Người dùng',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  late final String currentUserId;
  late final ChatProvider _chatProvider;

  bool _isOpening = true;

  @override
  void initState() {
    super.initState();

    currentUserId = pb.authStore.model?.id ?? '';
    _chatProvider = context.read<ChatProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openConversation();
    });
  }

  Future<void> _openConversation() async {
    if (currentUserId.isEmpty || widget.otherUserId.trim().isEmpty) {
      if (mounted) {
        setState(() => _isOpening = false);
      }
      return;
    }

    try {
      await _chatProvider.loadMessages(
        currentUserId: currentUserId,
        otherUserId: widget.otherUserId,
        markRead: true,
      );

      if (!mounted) return;

      await _chatProvider.subscribeMessages(
        currentUserId: currentUserId,
        otherUserId: widget.otherUserId,
      );

      _scrollToBottom(jump: true);
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  @override
  void dispose() {
    _chatProvider.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty ||
        currentUserId.isEmpty ||
        widget.otherUserId.trim().isEmpty ||
        _chatProvider.isSending) {
      return;
    }

    final success = await _chatProvider.sendMessage(
      senderId: currentUserId,
      receiverId: widget.otherUserId,
      content: text,
    );

    if (!mounted) return;

    if (success) {
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_chatProvider.errorMessage ?? 'Gửi tin nhắn thất bại.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final target = _scrollController.position.maxScrollExtent;

      if (jump) {
        _scrollController.jumpTo(target);
        return;
      }

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title:
          widget.otherUserName.trim().isEmpty
              ? 'Trò chuyện'
              : widget.otherUserName,
      showBack: true,
      child: AppBody(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (_isOpening && provider.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (currentUserId.isEmpty) {
                    return const _ChatError(
                      message: 'Bạn cần đăng nhập để sử dụng trò chuyện.',
                    );
                  }

                  if (widget.otherUserId.trim().isEmpty) {
                    return const _ChatError(
                      message: 'Không tìm thấy người nhận tin nhắn.',
                    );
                  }

                  if (provider.errorMessage != null &&
                      provider.messages.isEmpty) {
                    return _ChatError(
                      message: provider.errorMessage!,
                      onRetry: _openConversation,
                    );
                  }

                  final messages = provider.messages;

                  if (messages.isEmpty) {
                    return const _EmptyChat();
                  }

                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      final isMe = provider.isMessageMine(
                        message: message,
                        currentUserId: currentUserId,
                      );

                      final statusText = provider.getMessageStatusText(
                        message: message,
                        currentUserId: currentUserId,
                      );

                      return _ChatBubble(
                        message: message,
                        isMe: isMe,
                        statusText: statusText,
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return _ChatInput(
                  controller: _messageController,
                  isSending: provider.isSending,
                  enabled:
                      currentUserId.isNotEmpty &&
                      widget.otherUserId.trim().isNotEmpty,
                  onSend: _sendMessage,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _ChatError({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textGrey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 62,
              color: AppColors.textGrey.withOpacity(0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có tin nhắn nào.\n'
              'Hãy gửi lời nhắn để bắt đầu trò chuyện!',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String statusText;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.statusText,
  });

  String _formatMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final localTime = time.toLocal();

    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');

    final isToday =
        now.year == localTime.year &&
        now.month == localTime.month &&
        now.day == localTime.day;

    if (isToday) {
      return '$hour:$minute';
    }

    final day = localTime.day.toString().padLeft(2, '0');
    final month = localTime.month.toString().padLeft(2, '0');

    return '$hour:$minute $day/$month';
  }

  String _buildMetaText() {
    final timeText = _formatMessageTime(message.created);

    if (isMe) {
      if (timeText.isNotEmpty && statusText.isNotEmpty) {
        return '$timeText • $statusText';
      }

      return timeText.isNotEmpty ? timeText : statusText;
    }

    return timeText;
  }

  @override
  Widget build(BuildContext context) {
    final metaText = _buildMetaText();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17),
                  topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(isMe ? 17 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 17),
                ),
              ),
              child: Text(
                message.content,
                style: AppText.body.copyWith(
                  color: isMe ? Colors.white : AppColors.textDark,
                  height: 1.35,
                ),
              ),
            ),
            if (metaText.isNotEmpty) ...[
              const SizedBox(height: 3),
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 4,
                  right: isMe ? 4 : 0,
                ),
                child: Text(
                  metaText,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool enabled;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = enabled && !isSending;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: canUse,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText:
                      enabled ? 'Nhập tin nhắn...' : 'Không thể gửi tin nhắn',
                  hintStyle: AppText.body.copyWith(color: AppColors.textGrey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            InkWell(
              onTap: canUse ? onSend : null,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: canUse ? AppColors.primary : Colors.grey,
                  borderRadius: BorderRadius.circular(24),
                ),
                child:
                    isSending
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
