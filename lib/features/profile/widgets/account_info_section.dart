
import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/user_profile_model.dart';
import '../../../shared/widgets/section_card.dart';

class AccountInfoSection extends StatelessWidget {
  final UserProfileModel profile;
  final VoidCallback onChangePassword;

  const AccountInfoSection({
    super.key,
    required this.profile,
    required this.onChangePassword,
  });

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
