// FILE HỌC TẬP: lib/features/manager/web/widgets/manager_stat_card.dart
// Vai trò: Widget Web dùng cho thống kê thẻ.
// Luồng sử dụng: Đóng gói thành phần giao diện hoặc tiện ích dùng lại trong khu vực Manager Web.

import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';

// Lớp ManagerStatCard: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class ManagerStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? note;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  // Khởi tạo ManagerStatCard: nhận các tham số cần thiết để tạo đối tượng cho widget web dùng cho thống kê thẻ.
  const ManagerStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.note,
    this.onTap,
  });

  // Xây dựng giao diện (build): dựng cây widget của ManagerStatCard từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 27),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note != null && note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
