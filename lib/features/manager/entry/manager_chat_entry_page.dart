// FILE HỌC TẬP: lib/features/manager/entry/manager_chat_entry_page.dart
// Vai trò: Điểm điều phối Manager cho quản lý trò chuyện.
// Luồng sử dụng: Chọn giao diện Manager phù hợp nền tảng rồi chuyển vào màn hình App hoặc Web.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/chat/screens/manager_chat_list_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_chat_page.dart';

// Lớp ManagerChatEntryPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerChatEntryPage extends StatelessWidget {
  // Khởi tạo ManagerChatEntryPage: nhận các tham số cần thiết để tạo đối tượng cho điểm điều phối manager cho quản lý trò chuyện.
  const ManagerChatEntryPage({super.key});

  // Xây dựng giao diện (build): dựng cây widget của ManagerChatEntryPage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebChatPage();
    }

    return const ManagerChatListPage();
  }
}
