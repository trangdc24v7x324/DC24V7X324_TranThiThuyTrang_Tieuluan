// FILE HỌC TẬP: lib/features/chat/screens/manager_chat_list_page.dart
// Vai trò: Màn hình quản lý trò chuyện danh sách.
// Luồng sử dụng: Hiển thị hội thoại hoặc danh sách chat và phối hợp ChatProvider để tải/gửi tin nhắn.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';

// Lớp ManagerChatListPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerChatListPage extends StatefulWidget {
  // Khởi tạo ManagerChatListPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình quản lý trò chuyện danh sách.
  const ManagerChatListPage({super.key});

  // Tạo state (createState): liên kết ManagerChatListPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<ManagerChatListPage> createState() => _ManagerChatListPageState();
}

// Lớp _ManagerChatListPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _ManagerChatListPageState extends State<ManagerChatListPage> {
  late final String managerId;

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();

    managerId = pb.authStore.model?.id ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatList();
    });
  }

  // Tải trò chuyện danh sách (_loadChatList): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> _loadChatList() async {
    if (managerId.isEmpty) return;

    await context.read<ChatProvider>().loadManagerChatSummary(
      managerId: managerId,
    );
  }

  // Mở trò chuyện (_openChat): điều hướng hoặc hiển thị thành phần tương ứng từ thao tác người dùng.
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

  // Xây dựng giao diện (build): dựng cây widget của _ManagerChatListPageState từ dữ liệu và state hiện tại.
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

// Lớp _ChatUserTile: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _ChatUserTile extends StatelessWidget {
  final ChatRoomSummary item;
  final VoidCallback onTap;

  // Khởi tạo _ChatUserTile: nhận các tham số cần thiết để tạo đối tượng cho màn hình quản lý trò chuyện danh sách.
  const _ChatUserTile({required this.item, required this.onTap});

  // Xây dựng giao diện (build): dựng cây widget của _ChatUserTile từ dữ liệu và state hiện tại.
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
                      ? Colors.red.withValues(alpha: 0.25)
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

  // Định dạng thời gian (_formatTime): chuyển dữ liệu thô thành giá trị dễ đọc để hiển thị.
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

// Lớp _UnreadBadge: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _UnreadBadge extends StatelessWidget {
  final int count;

  // Khởi tạo _UnreadBadge: nhận các tham số cần thiết để tạo đối tượng cho màn hình quản lý trò chuyện danh sách.
  const _UnreadBadge({required this.count});

  // Xây dựng giao diện (build): dựng cây widget của _UnreadBadge từ dữ liệu và state hiện tại.
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

// Lớp _EmptyManagerChat: thành phần phục vụ màn hình quản lý trò chuyện danh sách.
class _EmptyManagerChat extends StatelessWidget {
  // Khởi tạo _EmptyManagerChat: nhận các tham số cần thiết để tạo đối tượng cho màn hình quản lý trò chuyện danh sách.
  const _EmptyManagerChat();

  // Xây dựng giao diện (build): dựng cây widget của _EmptyManagerChat từ dữ liệu và state hiện tại.
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
