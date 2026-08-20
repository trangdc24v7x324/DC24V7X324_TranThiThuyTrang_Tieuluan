// FILE HỌC TẬP: lib/features/profile/widgets/profile_header.dart
// Vai trò: Widget hồ sơ cho phần đầu hồ sơ.
// Luồng sử dụng: Hiển thị/chỉnh sửa một phần hồ sơ và trả sự kiện về màn hình Profile.

import 'dart:io';

import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Lớp ProfileHeader: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class ProfileHeader extends StatelessWidget {
  final String name;
  final String avatarUrl;

  // Khởi tạo ProfileHeader: nhận các tham số cần thiết để tạo đối tượng cho widget hồ sơ cho phần đầu hồ sơ.
  const ProfileHeader({super.key, required this.name, required this.avatarUrl});

  // Chọn ảnh (_pickImage): mở bộ chọn ảnh, nhận file và cập nhật phần xem trước.
  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null || !context.mounted) return;

      final success = await context.read<ProfileProvider>().updateAvatar(
        File(picked.path),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cập nhật ảnh đại diện thành công'
                : 'Cập nhật ảnh đại diện thất bại',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật avatar: $e')));
    }
  }

  // Xây dựng giao diện (build): dựng cây widget của ProfileHeader từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final isUploadingAvatar = provider.isUploadingAvatar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isUploadingAvatar ? null : () => _pickImage(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 98,
                  width: 98,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFEF2A39),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child:
                        avatarUrl.isNotEmpty
                            ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 54,
                                    color: Colors.grey,
                                  ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 54,
                              color: Colors.grey,
                            ),
                  ),
                ),

                Positioned(
                  right: -7,
                  bottom: -7,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF2A39),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        isUploadingAvatar
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }
}
