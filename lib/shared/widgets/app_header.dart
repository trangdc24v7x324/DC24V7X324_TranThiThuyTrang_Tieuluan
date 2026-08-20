// FILE HỌC TẬP: lib/shared/widgets/app_header.dart
// Vai trò: Widget dùng chung cho ứng dụng phần đầu.
// Luồng sử dụng: Đóng gói bố cục/giao diện lặp lại để tái sử dụng trong nhiều màn hình.

import 'package:flutter/material.dart';

// Lớp AppHeader: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class AppHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  final List<Widget>? actions;

  // Khởi tạo AppHeader: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho ứng dụng phần đầu.
  const AppHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffFF8A95), Color(0xffFF3D4F), Color(0xffD91F2D)],
    stops: [0.0, 0.45, 1.0],
  );

  // Xây dựng giao diện (build): dựng cây widget của AppHeader từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 380;

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(gradient: gradient),
        padding: EdgeInsets.fromLTRB(
          isSmall ? 16 : 18,
          12,
          isSmall ? 16 : 18,
          20,
        ),
        child: Row(
          children: [
            if (showBack) ...[
              _BackButton(onTap: onBack ?? () => Navigator.pop(context)),
              const SizedBox(width: 10),
            ],

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

// Lớp _BackButton: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  // Khởi tạo _BackButton: nhận các tham số cần thiết để tạo đối tượng cho widget dùng chung cho ứng dụng phần đầu.
  const _BackButton({required this.onTap});

  // Xây dựng giao diện (build): dựng cây widget của _BackButton từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
