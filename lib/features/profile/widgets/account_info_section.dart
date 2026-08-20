// FILE HỌC TẬP: lib/features/profile/widgets/account_info_section.dart
// Vai trò: Widget hồ sơ cho tài khoản thông tin khu vực.
// Luồng sử dụng: Hiển thị/chỉnh sửa một phần hồ sơ và trả sự kiện về màn hình Profile.

import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/user_profile_model.dart';
import '../../../shared/widgets/section_card.dart';

// Lớp AccountInfoSection: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class AccountInfoSection extends StatelessWidget {
  final UserProfileModel profile;
  final VoidCallback onChangePassword;

  // Khởi tạo AccountInfoSection: nhận các tham số cần thiết để tạo đối tượng cho widget hồ sơ cho tài khoản thông tin khu vực.
  const AccountInfoSection({
    super.key,
    required this.profile,
    required this.onChangePassword,
  });

  // Xây dựng giao diện (build): dựng cây widget của AccountInfoSection từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Thông tin tài khoản',
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text(
                  'Tài khoản đăng nhập',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  profile.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Mật khẩu', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  profile.passwordMasked,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onChangePassword,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
