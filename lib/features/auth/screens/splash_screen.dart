import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:CT466_project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:CT466_project_trangdc24v7x324/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _startSplashFlow();
  }

  /// Kiểm tra phiên đăng nhập và điều hướng người dùng.
  Future<void> _startSplashFlow() async {
    // Hiển thị Splash ngắn để giữ nhận diện thương hiệu.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final client = getPocketBase();

    // =========================================================
    // 1. KIỂM TRA PHIÊN ĐĂNG NHẬP
    // =========================================================

    if (!client.authStore.isValid) {
      _goToLogin();
      return;
    }

    try {
      // =======================================================
      // 2. LÀM MỚI THÔNG TIN TÀI KHOẢN
      // =======================================================

      await client.collection('users').authRefresh();

      if (!mounted) return;

      // Phiên bản PocketBase hiện tại của dự án
      // sử dụng authStore.model.
      final model = client.authStore.model;

      if (model == null) {
        client.authStore.clear();

        _goToLogin();
        return;
      }

      final Map<String, dynamic> data = model.toJson();

      // =======================================================
      // 3. KIỂM TRA TRẠNG THÁI TÀI KHOẢN
      // =======================================================

      // Nếu dữ liệu cũ chưa có isActive,
      // tạm xem tài khoản là đang hoạt động.
      final bool isActive = data['isActive'] != false;

      if (!isActive) {
        client.authStore.clear();

        _goToLogin();
        return;
      }

      // =======================================================
      // 4. KIỂM TRA ROLE
      // =======================================================

      final String role = (data['role'] ?? '').toString().trim().toLowerCase();

      switch (role) {
        case 'manager':
          _goToManagerHome();
          break;

        case 'customer':
          _goToCustomerHome();
          break;

        default:
          // Role không hợp lệ.
          client.authStore.clear();

          _goToLogin();
          break;
      }
    } catch (error) {
      debugPrint('Splash auth refresh error: $error');

      // Phiên không thể refresh.
      client.authStore.clear();

      if (!mounted) return;

      _goToLogin();
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _goToCustomerHome() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _goToManagerHome() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.managerHome);
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;

          final double screenHeight = constraints.maxHeight;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xffFF939B),
                  Color(0xffEF2A39),
                  Color(0xFFEF2A39),
                ],
                stops: [0.0, 0.67, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // =================================================
                // TÊN APP + SLOGAN
                // =================================================
                Positioned(
                  top: screenHeight * 0.32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'YourFood',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lobster(
                            textStyle: TextStyle(
                              fontSize: screenWidth * 0.14,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        Text(
                          'Ăn uống theo cách của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.042,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =================================================
                // HÌNH MINH HỌA
                // =================================================
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: screenHeight * 0.28,
                    child: Stack(
                      children: [
                        Positioned(
                          left: -screenWidth * 0.04,
                          bottom: 0,
                          child: Image.asset(
                            'images/splashScreen/image2.png',
                            width: screenWidth * 0.48,
                            fit: BoxFit.contain,
                          ),
                        ),

                        Positioned(
                          left: screenWidth * 0.18,
                          bottom: screenHeight * 0.01,
                          child: Image.asset(
                            'images/splashScreen/image1.png',
                            width: screenWidth * 0.42,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // =========================================
                        // HOTLINE
                        // =========================================
                        Positioned(
                          right: screenWidth * 0.05,
                          bottom: screenHeight * 0.04,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Liên hệ 0762 851 111',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: screenWidth * 0.026,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =================================================
                // HIỆU ỨNG BLUR
                // =================================================
                Positioned(
                  right: -screenWidth * 0.1,
                  bottom: screenHeight * 0.15,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      width: screenWidth * 0.25,
                      height: screenWidth * 0.25,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
