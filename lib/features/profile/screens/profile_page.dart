import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:CT466_project_trangdc24v7x324/features/profile/widgets/account_info_section.dart';
import 'package:CT466_project_trangdc24v7x324/features/profile/widgets/address_section.dart';
import 'package:CT466_project_trangdc24v7x324/features/profile/widgets/general_info_section.dart';
import 'package:CT466_project_trangdc24v7x324/features/profile/widgets/payment_methods_section.dart';
import 'package:CT466_project_trangdc24v7x324/features/profile/widgets/profile_header.dart';

import 'package:CT466_project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:CT466_project_trangdc24v7x324/routes/app_routes.dart';

// DESIGN SYSTEM
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:CT466_project_trangdc24v7x324/shared/theme/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProfileProvider>().loadProfile(forceReload: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Tài khoản',
      showBack: true,

      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.profile == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                child: const Text('Đăng nhập lại'),
              ),
            );
          }

          final profile = provider.profile!;

          return AppBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                ProfileHeader(
                  name: profile.fullName,
                  avatarUrl: profile.avatarUrl,
                ),

                const SizedBox(height: 16),

                GeneralInfoSection(
                  profile: profile,
                  isEditing: provider.isEditingGeneralInfo,
                  onEdit: provider.toggleGeneralInfoEdit,
                  onSave: ({
                    required fullName,
                    required email,
                    required phoneNumber,
                    required gender,
                    required dateOfBirth,
                  }) async {
                    final success = await provider.updateGeneralInfo(
                      fullName: fullName,
                      email: email,
                      phoneNumber: phoneNumber,
                      gender: gender,
                      dateOfBirth: dateOfBirth,
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Cập nhật thông tin thành công'
                              : provider.errorMessage ??
                                  'Cập nhật thông tin thất bại',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                AccountInfoSection(
                  profile: profile,
                  onChangePassword: () {
                    _showChangePasswordDialog(context);
                  },
                ),

                const SizedBox(height: 16),

                AddressSection(
                  addresses: profile.addresses,
                  isEditing: provider.isEditingAddress,
                  onEdit: provider.toggleAddressEdit,
                  onSave: (updatedAddresses) async {
                    final success = await provider.updateAddresses(
                      updatedAddresses,
                    );

                    if (success) {
                      // Lấy lại record thật từ PocketBase:
                      // id mới, default, label, lat/lng.
                      await provider.loadProfile(forceReload: true);
                    }

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Cập nhật địa chỉ thành công'
                              : provider.errorMessage ??
                                  'Cập nhật địa chỉ thất bại',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                PaymentMethodsSection(
                  methods: profile.paymentMethods,
                  isEditing: provider.isEditingPaymentMethods,
                  onEdit: provider.togglePaymentMethodsEdit,
                  onSave: (updatedMethods) async {
                    final success = await provider.updatePaymentMethods(
                      updatedMethods,
                    );

                    if (success) {
                      // PaymentPage sẽ đọc lại đúng phương thức mặc định
                      // từ ProfileProvider/PocketBase.
                      await provider.loadProfile(forceReload: true);
                    }

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Cập nhật phương thức thanh toán thành công'
                              : provider.errorMessage ??
                                  'Cập nhật phương thức thanh toán thất bại',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                _ActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Lịch sử mua hàng',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.orders);
                  },
                ),

                const SizedBox(height: 18),

                _LogoutButton(
                  isLoading: provider.isLoading,
                  onPressed:
                      provider.isLoading
                          ? null
                          : () async {
                            final shouldLogout = await _showLogoutDialog();

                            if (!context.mounted) return;

                            if (shouldLogout == true) {
                              await provider.logout(context);
                            }
                          },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<ProfileProvider>(
          builder: (context, provider, _) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Đổi mật khẩu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      provider.isChangingPassword
                          ? null
                          : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed:
                      provider.isChangingPassword
                          ? null
                          : () async {
                            final oldPass = oldPasswordController.text.trim();
                            final newPass = newPasswordController.text.trim();
                            final confirmPass =
                                confirmPasswordController.text.trim();

                            if (oldPass.isEmpty ||
                                newPass.isEmpty ||
                                confirmPass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Vui lòng nhập đầy đủ mật khẩu',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (newPass.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mật khẩu mới phải có ít nhất 6 ký tự',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (newPass != confirmPass) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Xác nhận mật khẩu không khớp'),
                                ),
                              );
                              return;
                            }

                            try {
                              await context
                                  .read<ProfileProvider>()
                                  .changePassword(
                                    oldPassword: oldPass,
                                    newPassword: newPass,
                                  );

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đổi mật khẩu thành công'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                  child:
                      provider.isChangingPassword
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _LogoutButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.logout_rounded),
        label: Text(isLoading ? 'Đang đăng xuất...' : 'Đăng xuất'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 144, 12, 2), // màu nền nút
          foregroundColor: Colors.white, // màu chữ và icon
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
