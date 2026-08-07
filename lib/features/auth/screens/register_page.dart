import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:CT466_project_trangdc24v7x324/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  String? _error;

  // =========================================================
  // EMAIL VALIDATION
  // =========================================================

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(email);
  }

  // =========================================================
  // NORMALIZE PHONE
  // =========================================================

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\.-]'), '');
  }

  // =========================================================
  // PHONE VALIDATION
  // =========================================================

  bool _isValidPhone(String phone) {
    final RegExp phoneRegex = RegExp(r'^(0\d{9}|\+84\d{9})$');

    return phoneRegex.hasMatch(phone);
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String _getRegisterErrorMessage(Object error) {
    final String message =
        error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('Email không được để trống') ||
        message.contains('Mật khẩu không được để trống') ||
        message.contains('Họ tên không được để trống')) {
      return message;
    }

    final String lower = message.toLowerCase();

    if (lower.contains('email')) {
      return 'Email đã được sử dụng '
          'hoặc không hợp lệ.';
    }

    return 'Không thể tạo tài khoản. '
        'Vui lòng kiểm tra lại thông tin.';
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> _register() async {
    if (_isLoading) return;

    final String fullName = _fullNameController.text.trim();

    final String phone = _normalizePhone(_phoneController.text.trim());

    final String email = _emailController.text.trim().toLowerCase();

    // Không trim password.
    final String password = _passwordController.text;

    final String confirmPassword = _confirmPasswordController.text;

    // =======================================================
    // VALIDATION
    // =======================================================

    if (fullName.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập họ và tên.';
      });

      return;
    }

    if (fullName.length < 2) {
      setState(() {
        _error = 'Họ và tên không hợp lệ.';
      });

      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập số điện thoại.';
      });

      return;
    }

    if (!_isValidPhone(phone)) {
      setState(() {
        _error = 'Số điện thoại không hợp lệ.';
      });

      return;
    }

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

    if (password.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập mật khẩu.';
      });

      return;
    }

    if (password.length < 8) {
      setState(() {
        _error = 'Mật khẩu phải có ít nhất 8 ký tự.';
      });

      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _error = 'Vui lòng xác nhận mật khẩu.';
      });

      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = 'Mật khẩu xác nhận không khớp.';
      });

      return;
    }

    // =======================================================
    // REGISTER
    // =======================================================

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phone,
      );

      if (!mounted) return;

      // Trả email về LoginPage.
      Navigator.pop(context, email);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = _getRegisterErrorMessage(error);
      });
    }
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFEF2A39)),
      suffixIcon: suffixIcon,
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

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
          child: AutofillGroup(
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
                    // =====================
                    // BACK
                    // =====================
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

                    const SizedBox(height: 8),

                    // =====================
                    // HEADER
                    // =====================
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
                            'Tạo tài khoản để '
                            'bắt đầu đặt món',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =====================
                    // FORM
                    // =====================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Điền thông tin bên dưới '
                            'để tạo tài khoản mới',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // =====================
                          // FULL NAME
                          // =====================
                          TextField(
                            controller: _fullNameController,
                            enabled: !_isLoading,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: _inputDecoration(
                              label: 'Họ và tên',
                              icon: Icons.person_outline,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // =====================
                          // PHONE
                          // =====================
                          TextField(
                            controller: _phoneController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            decoration: _inputDecoration(
                              label: 'Số điện thoại',
                              icon: Icons.phone_outlined,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // =====================
                          // EMAIL
                          // =====================
                          TextField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // =====================
                          // PASSWORD
                          // =====================
                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: _inputDecoration(
                              label: 'Mật khẩu',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // =====================
                          // CONFIRM PASSWORD
                          // =====================
                          TextField(
                            controller: _confirmPasswordController,
                            enabled: !_isLoading,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                _register();
                              }
                            },
                            decoration: _inputDecoration(
                              label: 'Xác nhận mật khẩu',
                              icon: Icons.lock_reset_outlined,
                              suffixIcon: IconButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                          // =====================
                          // ERROR
                          // =====================
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

                          const SizedBox(height: 20),

                          // =====================
                          // REGISTER BUTTON
                          // =====================
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF2A39),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
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
                                        'Tạo tài khoản',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =====================
                    // LOGIN
                    // =====================
                    Center(
                      child: TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  Navigator.pop(context);
                                },
                        child: RichText(
                          text: TextSpan(
                            text: 'Đã có tài khoản? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Đăng nhập',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
