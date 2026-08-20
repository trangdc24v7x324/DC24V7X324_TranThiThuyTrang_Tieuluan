// FILE HỌC TẬP: lib/features/manager/entry/manager_notifications_entry_page.dart
// Vai trò: Điểm điều phối Manager cho quản lý thông báo.
// Luồng sử dụng: Chọn giao diện Manager phù hợp nền tảng rồi chuyển vào màn hình App hoặc Web.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/notification/manager_notifications_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_notifications_page.dart';

// Lớp ManagerNotificationsEntryPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerNotificationsEntryPage extends StatelessWidget {
  // Khởi tạo ManagerNotificationsEntryPage: nhận các tham số cần thiết để tạo đối tượng cho điểm điều phối manager cho quản lý
  // thông báo.
  const ManagerNotificationsEntryPage({super.key});

  // Xây dựng giao diện (build): dựng cây widget của ManagerNotificationsEntryPage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebNotificationsPage();
    }

    return const ManagerNotificationsPage();
  }
}
