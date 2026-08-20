// FILE HỌC TẬP: lib/shared/widgets/app_body.dart
// Vai trò: Widget dùng chung cho ứng dụng nội dung.
// Luồng sử dụng: Đóng gói bố cục/giao diện lặp lại để tái sử dụng trong nhiều màn hình.

import 'package:flutter/material.dart';

// Lớp AppBody: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class AppBody extends StatelessWidget {
  final Widget child;

  // Khởi tạo AppBody: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho ứng dụng nội dung.
  const AppBody({super.key, required this.child});

  // Xây dựng giao diện (build): dựng cây widget của AppBody từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: child,
    );
  }
}
