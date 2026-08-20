// FILE HỌC TẬP: lib/shared/widgets/app_card.dart
// Vai trò: Widget dùng chung cho ứng dụng thẻ.
// Luồng sử dụng: Đóng gói bố cục/giao diện lặp lại để tái sử dụng trong nhiều màn hình.

import 'package:flutter/material.dart';

// Lớp AppCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin; 

  // Khởi tạo AppCard: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho ứng dụng thẻ.
  const AppCard({
    super.key,
    required this.child,
    this.margin, 
  });

  // Xây dựng giao diện (build): dựng cây widget của AppCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin, 
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
