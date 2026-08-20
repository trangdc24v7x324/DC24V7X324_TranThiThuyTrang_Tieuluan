
import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffFF8A95), Color(0xffFF3D4F), Color(0xffD91F2D)],
    stops: [0.0, 0.45, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 380;

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(gradient: gradient),
        padding: EdgeInsets.fromLTRB(
          isSmall ? 16 : 18,
          12,
          isSmall ? 16 : 18,
          20,
        ),
        child: Row(
          children: [
            if (showBack) ...[
              _BackButton(onTap: onBack ?? () => Navigator.pop(context)),
              const SizedBox(width: 10),
            ],

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
