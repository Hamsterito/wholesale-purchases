import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/home.png'), size: 46),
          label: "Главная",
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/catalog.png'), size: 46),
          label: "Каталог",
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/korzina.png'), size: 46),
          label: "Корзина",
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/icons/prof.png'), size: 46),
          label: "Профиль",
        ),
      ],
    );
  }
}
