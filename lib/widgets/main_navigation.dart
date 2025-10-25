import 'package:flutter/material.dart';
import 'package:flutter_project/pages/home_page.dart';
import 'package:flutter_project/pages/catalog.dart';
import 'package:flutter_project/pages/cart_page.dart';
import 'package:flutter_project/profile/profile_page.dart';
import 'package:flutter_svg/flutter_svg.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CatalogPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildNavItem(
                  'assets/icons/main.svg',
                  'assets/icons/main_active.svg',
                  'Главная',
                  0,
                ),
                _buildNavItem(
                  'assets/icons/catalog.svg',
                  'assets/icons/catalog_active.svg',
                  'Каталог',
                  1,
                ),
                _buildNavItem(
                  'assets/icons/cart.svg',
                  'assets/icons/cart_active.svg',
                  'Корзина',
                  2,
                ),
                _buildNavItem(
                  'assets/icons/profile.svg',
                  'assets/icons/profile_active.svg',
                  'Профиль',
                  3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String iconPath,
    String activeIconPath,
    String label,
    int index,
  ) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isActive ? activeIconPath : iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isActive ? const Color(0xFF6288D5) : Colors.grey.shade600,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? const Color(0xFF6288D5)
                    : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
