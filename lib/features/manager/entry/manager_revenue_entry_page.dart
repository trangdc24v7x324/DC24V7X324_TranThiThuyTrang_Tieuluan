// FILE HỌC TẬP: lib/features/manager/entry/manager_revenue_entry_page.dart
// Vai trò: Điểm điều phối Manager cho quản lý doanh thu.
// Luồng sử dụng: Chọn giao diện Manager phù hợp nền tảng rồi chuyển vào màn hình App hoặc Web.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_revenue_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_revenue_page.dart';

// Lớp ManagerRevenueEntryPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerRevenueEntryPage extends StatelessWidget {
  // Khởi tạo ManagerRevenueEntryPage: nhận các tham số cần thiết để tạo đối tượng cho điểm điều phối manager cho quản lý doanh
  // thu.
  const ManagerRevenueEntryPage({super.key});

  // Xây dựng giao diện (build): dựng cây widget của ManagerRevenueEntryPage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebRevenuePage();
    }

    return const ManagerRevenuePage();
  }
}
