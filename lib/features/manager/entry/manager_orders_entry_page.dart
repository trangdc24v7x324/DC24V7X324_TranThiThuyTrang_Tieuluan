// FILE HỌC TẬP: lib/features/manager/entry/manager_orders_entry_page.dart
// Vai trò: Điểm điều phối Manager cho quản lý đơn hàng.
// Luồng sử dụng: Chọn giao diện Manager phù hợp nền tảng rồi chuyển vào màn hình App hoặc Web.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_orders_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_orders_page.dart';

// Lớp ManagerOrdersEntryPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerOrdersEntryPage extends StatelessWidget {
  // Khởi tạo ManagerOrdersEntryPage: nhận các tham số cần thiết để tạo đối tượng cho điểm điều phối manager cho quản lý đơn hàng.
  const ManagerOrdersEntryPage({super.key});

  // Xây dựng giao diện (build): dựng cây widget của ManagerOrdersEntryPage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebOrdersPage();
    }

    return const ManagerOrdersPage();
  }
}
