import 'package:flutter/material.dart';

import 'bottom_nav_bar.dart';
import 'main_navigation.dart';

/// Нижняя навигация для внутренних экранов (история заказов, настройки и т.д.).
/// При нажатии на вкладку делает Navigator.pushAndRemoveUntil и открывает
/// корневой MainNavigation с нужным индексом - внутренние экраны не
/// сохраняются в стеке навигации, чтобы пользователь не "застревал" в них
/// после переключения вкладки.
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, this.currentIndex});

  /// Индекс активной вкладки (обычно null или 3 = профиль), просто для
  /// подсветки. На внутренних экранах часто передают null.
  final int? currentIndex;

  void _openTab(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainNavigation(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) => _openTab(context, index),
    );
  }
}
