import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:CT466_project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:CT466_project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:CT466_project_trangdc24v7x324/routes/app_routes.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_layout.dart';

class ManagerChatListPage extends StatefulWidget {
  const ManagerChatListPage({super.key});

  @override
  State<ManagerChatListPage> createState() => _ManagerChatListPageState();
}

class _ManagerChatListPageState extends State<ManagerChatListPage> {
  late final String managerId;

  @override
  void initState() {
    super.initState();

    managerId = pb.authStore.model?.id ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatList();
    });
  }

  Future<void> _loadChatList() async {
    if (managerId.isEmpty) return;

    await context.read<ChatProvider>().loadManagerChatSummary(
      managerId: managerId,
    );
  }

  Future<void> _openChat({
    required String customerId,
    required String customerName,
  }) async {
    if (managerId.isEmpty || customerId.isEmpty) return;

    await Navigator.pushNamed(
      context,
      AppRoutes.managerChatDetail,
      arguments: {'otherUserId': customerId, 'otherUserName': customerName},
    );

    if (!mounted) return;

    await _loadChatList();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Tin nhắn khách hàng',
      showBack: true,
      child: AppBody(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            final items = chatProvider.rooms;

            if (chatProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (chatProvider.errorMessage != null && items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _loadChatList,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 130),
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 52,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        chatProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: AppColors.textGrey),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _loadChatList,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _loadChatList,
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(height: 420, child: _EmptyManagerChat()),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadChatList,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final room = items[index];

                  return _ChatUserTile(
                    item: room,
                    onTap:
                        () => _openChat(
                          customerId: room.userId,
                          customerName: room.fullName,
                        ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatUserTile extends StatelessWidget {
  final ChatRoomSummary item;
  final VoidCallback onTap;

  const _ChatUserTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = item.unreadCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  hasUnread
                      ? Colors.red.withOpacity(0.25)
                      : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    item.avatarUrl.isNotEmpty
                        ? NetworkImage(item.avatarUrl)
                        : null,
                child:
                    item.avatarUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        fontWeight:
                            hasUnread ? FontWeight.w800 : FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.lastMessage.isEmpty
                          ? 'Chưa có nội dung tin nhắn'
                          : item.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        color:
                            hasUnread ? AppColors.textDark : AppColors.textGrey,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.lastTime != null)
                    Text(
                      _formatTime(item.lastTime!),
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (hasUnread) _UnreadBadge(count: item.unreadCount),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();

    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (isToday) {
      return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
    }

    return '${twoDigits(time.day)}/${twoDigits(time.month)}';
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyManagerChat extends StatelessWidget {
  const _EmptyManagerChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Chưa có khách hàng nào nhắn tin.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.textGrey),
        ),
      ),
    );
  }
}
