// FILE HỌC TẬP: lib/features/manager/entry/manager_home_entry_page.dart
// Vai trò: Điểm điều phối Manager cho quản lý trang chủ.
// Luồng sử dụng: Chọn giao diện Manager phù hợp nền tảng rồi chuyển vào màn hình App hoặc Web.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_home_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_home_page.dart';

/// Tự chọn giao diện Manager theo nền tảng.
///
/// - Flutter Web: dùng giao diện web mới.
/// - Android/iOS/desktop app: giữ nguyên ManagerHomePage hiện tại.
// Lớp ManagerHomeEntryPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerHomeEntryPage extends StatelessWidget {
  // Khởi tạo ManagerHomeEntryPage: nhận các tham số cần thiết để tạo đối tượng cho điểm điều phối manager cho quản lý trang chủ.
  const ManagerHomeEntryPage({super.key});

  // Xây dựng giao diện (build): dựng cây widget của ManagerHomeEntryPage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebHomePage();
    }

    return const ManagerHomePage();
  }
}
