// FILE HỌC TẬP: lib/shared/widgets/app_layout.dart
// Vai trò: Widget dùng chung cho ứng dụng bố cục.
// Luồng sử dụng: Đóng gói bố cục/giao diện lặp lại để tái sử dụng trong nhiều màn hình.

import 'package:flutter/material.dart';
import 'app_header.dart';

// Lớp AppLayout: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class AppLayout extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget child;

  final List<Widget>? actions; 
  final Widget? floatingActionButton;

  // Khởi tạo AppLayout: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho ứng dụng bố cục.
  const AppLayout({
    super.key,
    required this.title,
    this.showBack = false,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  // Xây dựng giao diện (build): dựng cây widget của AppLayout từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppHeader.gradient),
        child: Column(
          children: [
            AppHeader(
              title: title,
              showBack: showBack,
              actions: actions,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
