// FILE HỌC TẬP: lib/shared/widgets/section_card.dart
// Vai trò: Widget dùng chung cho khu vực thẻ.
// Luồng sử dụng: Đóng gói bố cục/giao diện lặp lại để tái sử dụng trong nhiều màn hình.

import 'package:flutter/material.dart';

// Lớp SectionCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  // Khởi tạo SectionCard: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho khu vực thẻ.
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  // Xây dựng giao diện (build): dựng cây widget của SectionCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3C2F2F),
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
