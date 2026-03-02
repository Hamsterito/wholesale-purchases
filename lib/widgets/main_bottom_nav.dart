import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_navigation.dart';
import 'nav_colors.dart';

class MainBottomNav extends StatelessWidget {
  final int? currentIndex;

  const MainBottomNav({
    super.key,
    this.currentIndex,
  });

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor =
        isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05);
    final navColors = NavColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: navColors.background,
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
                context,
                'assets/icons/main.svg',
                'assets/icons/main_active.svg',
                'Главная',
                0,
              ),
              _buildNavItem(
                context,
                'assets/icons/catalog.svg',
                'assets/icons/catalog_active.svg',
                'Каталог',
                1,
              ),
              _buildNavItem(
                context,
                'assets/icons/cart.svg',
                'assets/icons/cart_active.svg',
                'Корзина',
                2,
              ),
              _buildNavItem(
                context,
                'assets/icons/profile.svg',
                'assets/icons/profile_active.svg',
                'Профиль',
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String iconPath,
    String activeIconPath,
    String label,
    int index,
  ) {
    final isActive = currentIndex == index;
    final navColors = NavColors.of(context);
    final activeColor = navColors.foreground;
    final inactiveColor = navColors.foregroundMuted;
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
              onTap: () => _openTab(context, index),
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

