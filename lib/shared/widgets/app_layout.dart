import 'package:flutter/material.dart';
import 'app_header.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget child;

  final List<Widget>? actions; 
  final Widget? floatingActionButton;

  const AppLayout({
    super.key,
    required this.title,
    this.showBack = false,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppHeader.gradient),
        child: Column(
          children: [
            AppHeader(
              title: title,
              showBack: showBack,
              actions: actions,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
