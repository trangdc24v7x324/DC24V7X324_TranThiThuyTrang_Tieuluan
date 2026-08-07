import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NavIcon extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const NavIcon({
    super.key,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (index) {
      case 0:
        icon =
            selectedIndex == 0
                ? CupertinoIcons.house_fill
                : CupertinoIcons.home;
        break;
      case 1:
        icon =
            selectedIndex == 1 ? CupertinoIcons.cart_fill : CupertinoIcons.cart;
        break;
      case 2:
        icon =
            selectedIndex == 2
                ? CupertinoIcons.chat_bubble_fill
                : CupertinoIcons.chat_bubble;
        break;
      case 3:
        icon =
            selectedIndex == 3 ? CupertinoIcons.bell_fill : CupertinoIcons.bell;
        break;
      default:
        icon = CupertinoIcons.circle;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onTap(index),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: selectedIndex == index ? Colors.white : Colors.white70,
                  size: 28,
                ),

                if (badgeCount > 0)
                  Positioned(
                    right: -9,
                    top: -9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEF2A39),
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFEF2A39),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selectedIndex == index ? 6 : 0,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
