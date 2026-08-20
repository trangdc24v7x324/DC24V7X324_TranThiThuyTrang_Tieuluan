// FILE HỌC TẬP: lib/features/manager/entry/manager_categories_entry_page.dart
// Vai trò: Điểm điều phối Manager cho quản lý danh mục.
// Luồng sử dụng: Chọn giao diện Manager phù hợp nền tảng rồi chuyển vào màn hình App hoặc Web.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_categories_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_categories_page.dart';

/// Chọn giao diện quản lý danh mục theo nền tảng.
///
/// - Flutter Web: dùng ManagerWebCategoriesPage.
/// - Android/iOS: giữ nguyên ManagerCategoriesPage hiện tại.
// Lớp ManagerCategoriesEntryPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ManagerCategoriesEntryPage extends StatelessWidget {
  // Khởi tạo ManagerCategoriesEntryPage: nhận các tham số cần thiết để tạo đối tượng cho điểm điều phối manager cho quản lý danh
  // mục.
  const ManagerCategoriesEntryPage({super.key});

  // Xây dựng giao diện (build): dựng cây widget của ManagerCategoriesEntryPage từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebCategoriesPage();
    }

    return const ManagerCategoriesPage();
  }
}
