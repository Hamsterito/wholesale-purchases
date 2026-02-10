import 'package:flutter/material.dart';
import 'package:flutter_project/pages/home_page.dart';
import 'package:flutter_project/pages/catalog.dart';
import 'package:flutter_project/pages/cart_page.dart';
import 'package:flutter_project/profile/profile_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

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
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor =
        isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
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
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;
    final splashColor = activeColor.withValues(alpha: 0.18);
    final highlightColor = activeColor.withValues(alpha: 0.12);
    final hoverColor = activeColor.withValues(alpha: 0.08);
    bool isPressed = false;

    return Expanded(
      child: StatefulBuilder(
        builder: (context, setInnerState) {
          return AnimatedScale(
            scale: isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: InkWell(
              onTap: () => _onItemTapped(index),
              onHighlightChanged: (value) {
                setInnerState(() => isPressed = value);
              },
              borderRadius: BorderRadius.circular(12),
              splashColor: splashColor,
              highlightColor: highlightColor,
              hoverColor: hoverColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    isActive ? activeIconPath : iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isActive ? activeColor : inactiveColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
