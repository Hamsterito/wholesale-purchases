import 'package:flutter/material.dart';
import 'package:flutter_project/pages/cart_page.dart';
import 'package:flutter_project/pages/catalog.dart';
import 'package:flutter_project/pages/home_page.dart';
import 'package:flutter_project/profile/profile_page.dart';
import 'package:flutter_project/services/notification_service.dart';
import 'package:flutter_project/widgets/top_message.dart';

import 'bottom_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CatalogPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    // Переключение вкладок IndexedStack идёт через setState, без push/pop
    // на корневом Navigator. NavigatorObserver такие смены не видит,
    // поэтому закрываем активный top-message вручную.
    dismissTopMessage();
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_currentIndex < 0 || _currentIndex > 3) {
      _currentIndex = 0;
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Управляем polling при переходе приложения в фон и обратно
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        NotificationService().pausePolling();
      case AppLifecycleState.resumed:
        NotificationService().resumePolling();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
