// FILE HỌC TẬP: lib/features/auth/screens/forgot_password_page.dart
// Vai trò: Màn hình quên mật khẩu.
// Luồng sử dụng: Nhận dữ liệu người dùng, gọi AuthService và điều hướng theo kết quả xác thực.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project_trangdc24v7x324/services/auth_service.dart';

// Lớp ForgotPasswordPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class ForgotPasswordPage extends StatefulWidget {
  // Khởi tạo ForgotPasswordPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình quên mật khẩu.
  const ForgotPasswordPage({super.key});

  // Tạo state (createState): liên kết ForgotPasswordPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

// Lớp _ForgotPasswordPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isSuccess = false;

  String? _error;

  // =========================================================
  // EMAIL VALIDATION
  // =========================================================

  // Kiểm tra điều kiện (_isValidEmail): đánh giá trạng thái hợp lệ email và trả kết quả cho lớp gọi.
  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(email);
  }

  // =========================================================
  // SEND RESET EMAIL
  // =========================================================

  // Đặt lại mật khẩu (_sendResetEmail): kiểm tra email và yêu cầu PocketBase gửi liên kết khôi phục.
  Future<void> _sendResetEmail() async {
    if (_isLoading) return;

    final String email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập email.';
      });

      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Email không đúng định dạng.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isSuccess = false;
    });

    try {
      await _authService.requestPasswordReset(email: email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _error =
            'Không thể gửi yêu cầu đặt lại mật khẩu. '
            'Vui lòng thử lại.';
      });
    }
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  // Xử lý _inputDecoration: thực hiện phần nghiệp vụ tương ứng trong màn hình quên mật khẩu.
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFEF2A39)),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      labelStyle: const TextStyle(color: Colors.black87),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF2A39), width: 1.4),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  // Giải phóng tài nguyên (dispose): hủy controller/listener khi widget bị loại khỏi cây giao diện.
  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  // Xây dựng giao diện (build): dựng cây widget của _ForgotPasswordPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [Color(0xffFF939B), Color(0xffEF2A39), Color(0xffEF2A39)],
            stops: [0.0, 0.67, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height - MediaQuery.of(context).padding.top - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================================
                  // BACK BUTTON
                  // ===========================================
                  IconButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              Navigator.pop(context);
                            },
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===========================================
                  // LOGO
                  // ===========================================
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'YourFood',
                          style: GoogleFonts.lobster(
                            fontSize: 42,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Khôi phục tài khoản của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===========================================
                  // FORM
                  // ===========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Nhập địa chỉ email đã '
                          'đăng ký. Hệ thống sẽ gửi '
                          'hướng dẫn đặt lại mật khẩu.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =====================================
                        // EMAIL
                        // =====================================
                        TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onSubmitted: (_) {
                            if (!_isLoading) {
                              _sendResetEmail();
                            }
                          },
                          decoration: _inputDecoration(
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        // =====================================
                        // ERROR
                        // =====================================
                        if (_error != null) ...[
                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        // =====================================
                        // SUCCESS
                        // =====================================
                        if (_isSuccess) ...[
                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: Colors.green.shade700,
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    'Yêu cầu đã được gửi. '
                                    'Vui lòng kiểm tra email '
                                    'để đặt lại mật khẩu.',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // =====================================
                        // SEND BUTTON
                        // =====================================
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF2A39),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'Gửi yêu cầu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =====================================
                        // BACK LOGIN
                        // =====================================
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                    },
                            child: const Text(
                              'Quay lại đăng nhập',
                              style: TextStyle(
                                color: Color(0xFFEF2A39),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
