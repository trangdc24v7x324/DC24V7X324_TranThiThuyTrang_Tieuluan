
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';

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

  Future<void> _startSplashFlow() async {

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final client = getPocketBase();

    if (!client.authStore.isValid) {
      _goToLogin();
      return;
    }

    try {

      await client.collection('users').authRefresh();

      if (!mounted) return;

      final model = client.authStore.model;

      if (model == null) {
        client.authStore.clear();

        _goToLogin();
        return;
      }

      final Map<String, dynamic> data = model.toJson();

      final bool isActive = data['isActive'] != false;

      if (!isActive) {
        client.authStore.clear();

        _goToLogin();
        return;
      }

      final String role = (data['role'] ?? '').toString().trim().toLowerCase();

      switch (role) {
        case 'manager':
          _goToManagerHome();
          break;

        case 'customer':
          _goToCustomerHome();
          break;

        default:

          client.authStore.clear();

          _goToLogin();
          break;
      }
    } catch (error) {
      debugPrint('Splash auth refresh error: $error');

      client.authStore.clear();

      if (!mounted) return;

      _goToLogin();
    }
  }

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
