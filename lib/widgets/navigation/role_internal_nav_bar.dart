import 'package:flutter/material.dart';
import 'package:flutter_project/services/storage/auth_storage.dart';

import 'nav_role.dart';
import 'navigation_shell.dart';
import 'role_nav_config.dart';
import 'role_navigation_bar.dart';

/// Нижняя навигация для внутренних экранов (история заказов, настройки и т.д.).
/// Показывает панель активной роли, а при нажатии на вкладку делает
/// pushAndRemoveUntil на свежий NavigationShell с нужным индексом - внутренние
/// экраны не остаются в стеке, чтобы пользователь не "застревал" в них после
/// переключения вкладки.
class RoleInternalNavBar extends StatelessWidget {
  const RoleInternalNavBar({super.key, this.currentIndex});

  /// Индекс активной вкладки для подсветки. На внутренних экранах обычно null.
  final int? currentIndex;

  void _openTab(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => NavigationShell(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // resolveNavRole сам сводит нераспознанную роль к buyer, поэтому панель
    // никогда не остаётся без набора вкладок.
    final tabs = tabsForRole(resolveNavRole(AuthStorage.role));
    return RoleNavigationBar(
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: (index) => _openTab(context, index),
    );
  }
}
