import 'package:flutter/material.dart';
import 'nav_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navColors = NavColors.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: navColors.foreground,
      unselectedItemColor: navColors.foregroundMuted,
      backgroundColor: navColors.background,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/home.png'), size: 46),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/catalog.png'), size: 46),
          label: 'Каталог',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/korzina.png'), size: 46),
          label: 'Корзина',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/prof.png'), size: 46),
          label: 'Профиль',
        ),
      ],
    );
  }
}
