// FILE HỌC TẬP: lib/shared/theme/app_colors.dart
// Vai trò: Cấu hình giao diện dùng chung cho ứng dụng màu sắc.
// Luồng sử dụng: Tập trung hằng số giao diện để các màn hình sử dụng thống nhất.

import 'package:flutter/material.dart';

// Lớp AppColors: thành phần phục vụ cấu hình giao diện dùng chung cho ứng dụng màu sắc.
class AppColors {
  static const primary = Color(0xffFF3D4F);

  // thêm màu nhạt của primary
  static const primaryLight = Color(
    0xFFFFCDD2,
  ); // đỏ nhạt, bạn chọn mã hex phù hợp

  // thêm màu nền phụ
  static const backgroundSecondary = Color(0xFFF1F5F9); // nền xám nhạt

  // các màu khác giữ nguyên...
  static const textDark = Color(0xFF3C2F2F);
  static const textGrey = Color(0xFF9E9E9E);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF64748B);

  static const bg = Color(0xFFF7F7F7);
  static const bgLight = Color(0xFFF3F3F3);
  static const surface = Color(0xFFFFFFFF);

  static const border = Color(0xFFE2E8F0);

  static const chatMe = Color(0xFFDCFCE7);
  static const chatMeBorder = Color(0xFFBBF7D0);
  static const chatMeText = Color(0xFF14532D);
  static const chatOther = Color(0xFFFFFFFF);

  static const inputBg = Color(0xFFF1F5F9);
  static const imageBtnBg = Color(0xFFEFF6FF);

  static const success = Color(0xFF22C55E);

  static const sendButton = Color(0xffFF3D4F);
}
