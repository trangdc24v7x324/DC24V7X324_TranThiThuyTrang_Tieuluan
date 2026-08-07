import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:CT466_project_trangdc24v7x324/routes/app_routes.dart';
import 'package:CT466_project_trangdc24v7x324/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadLastEmail();
  }

  // =========================================================
  // LOAD EMAIL ĐÃ ĐĂNG NHẬP TRƯỚC ĐÓ
  // =========================================================

  Future<void> _loadLastEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? savedEmail = prefs.getString('last_email');

    if (!mounted) return;

    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
  }

  // =========================================================
  // VALIDATE EMAIL
  // =========================================================

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(email);
  }

  // =========================================================
  // CHUYỂN LỖI THÀNH THÔNG BÁO THÂN THIỆN
  // =========================================================

  String _getLoginErrorMessage(Object error) {
    final String message =
        error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('Tài khoản của bạn đã bị khóa')) {
      return 'Tài khoản của bạn đã bị khóa.';
    }

    if (message.contains('Tài khoản chưa được phân quyền hợp lệ')) {
      return 'Tài khoản chưa được phân quyền hợp lệ.';
    }

    if (message.contains('Không lấy được thông tin tài khoản')) {
      return 'Không lấy được thông tin tài khoản.';
    }

    if (message.contains('Vui lòng nhập email')) {
      return 'Vui lòng nhập email.';
    }

    if (message.contains('Vui lòng nhập mật khẩu')) {
      return 'Vui lòng nhập mật khẩu.';
    }

    return 'Đăng nhập thất bại. '
        'Vui lòng kiểm tra email hoặc mật khẩu.';
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    if (_isLoading) return;

    final String email = _emailController.text.trim().toLowerCase();

    // Không trim password.
    final String password = _passwordController.text;

    // =======================================================
    // VALIDATION
    // =======================================================

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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // =====================================================
      // AUTHENTICATE
      // =====================================================

      await _authService.login(email: email, password: password);

      // =====================================================
      // LƯU EMAIL
      // =====================================================

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_email', email);

      if (!mounted) return;

      // =====================================================
      // KIỂM TRA ROLE
      // =====================================================

      if (_authService.isManager) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(context, AppRoutes.managerHome);

        return;
      }

      if (_authService.isCustomer) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(context, AppRoutes.home);

        return;
      }

      // Không thuộc role hợp lệ.
      await _authService.logout();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Tài khoản chưa được phân quyền hợp lệ.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = _getLoginErrorMessage(error);
      });
    }
  }

  // =========================================================
  // OPEN REGISTER
  // =========================================================

  Future<void> _openRegisterPage() async {
    final Object? result = await Navigator.pushNamed(
      context,
      AppRoutes.register,
    );

    if (!mounted) return;

    // RegisterPage sẽ trả email về nếu đăng ký thành công.
    if (result is String && result.trim().isNotEmpty) {
      final String registeredEmail = result.trim().toLowerCase();

      _emailController.text = registeredEmail;

      _passwordController.clear();

      setState(() {
        _error = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký thành công. '
            'Vui lòng đăng nhập.',
          ),
        ),
      );
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
    _emailController.dispose();
    _passwordController.dispose();

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),

                    Text(
                      'YourFood',
                      style: GoogleFonts.lobster(
                        fontSize: 42,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Đăng nhập để tiếp tục '
                      'đặt món ngon mỗi ngày',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

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
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Nhập thông tin '
                            'tài khoản của bạn',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // =========================
                          // EMAIL
                          // =========================
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

                          // =========================
                          // PASSWORD
                          // =========================
                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                _login();
                              }
                            },
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
                          const SizedBox(height: 6),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgotPassword,
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: Color(0xFFEF2A39),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // =========================
                          // ERROR
                          // =========================
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

                          // =========================
                          // LOGIN BUTTON
                          // =========================
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
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
                                        'Đăng nhập',
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

                    TextButton(
                      onPressed: _isLoading ? null : _openRegisterPage,
                      child: RichText(
                        text: TextSpan(
                          text: 'Chưa có tài khoản? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 14,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Đăng ký',
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

                    const SizedBox(height: 8),
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
