import 'package:flutter/material.dart';

class AppBody extends StatelessWidget {
  final Widget child;

  const AppBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: child,
    );
  }
}
