// Единая нижняя навигационная панель для всего приложения

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/notification_service.dart';
import 'nav_colors.dart';
import 'notification_badge.dart';

/// Описание одной вкладки в нижней навигации.
class _NavTab {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String icon;
  final String activeIcon;
  final String label;
}

const _tabs = <_NavTab>[
  _NavTab(
    icon: 'assets/icons/main.svg',
    activeIcon: 'assets/icons/main_active.svg',
    label: 'Главная',
  ),
  _NavTab(
    icon: 'assets/icons/catalog.svg',
    activeIcon: 'assets/icons/catalog_active.svg',
    label: 'Каталог',
  ),
  _NavTab(
    icon: 'assets/icons/cart.svg',
    activeIcon: 'assets/icons/cart_active.svg',
    label: 'Корзина',
  ),
  _NavTab(
    icon: 'assets/icons/profile.svg',
    activeIcon: 'assets/icons/profile_active.svg',
    label: 'Профиль',
  ),
];

/// Индекс вкладки профиля - на него вешаем значок уведомлений.
const int _profileTabIndex = 3;

/// Универсальная нижняя навигационная панель.
///
/// Принимает индекс активной вкладки и коллбэк нажатия - вызывающий код
/// решает, переключать ли индекс локально (как в MainNavigation) или
/// делать Navigator.pushAndRemoveUntil (как в MainBottomNav).
///
/// Значок уведомлений на иконке профиля рисуется здесь же - благодаря
/// этому все экраны приложения показывают его одинаково.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Индекс активной вкладки. null - ни одна не выделена (например,
  /// на внутренних экранах вроде "История заказов" или "Настройки").
  final int? currentIndex;

  /// Вызывается при нажатии на вкладку с её индексом.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.05);
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
              for (var i = 0; i < _tabs.length; i++)
                _buildNavItem(context, _tabs[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavTab tab, int index) {
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
              onTap: () => onTap(index),
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
                  _buildIcon(tab, isActive, activeColor, inactiveColor),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
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

  Widget _buildIcon(
    _NavTab tab,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    final iconWidget = SvgPicture.asset(
      isActive ? tab.activeIcon : tab.icon,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isActive ? activeColor : inactiveColor,
        BlendMode.srcIn,
      ),
    );

    // Только у профиля показываем значок уведомлений.
    // Фильтрация по роли уже в NotificationService._computeTotal:
    // buyer видит сообщения + заказы + отзывы, supplier - сообщения +
    // заказы + модерации, moderator - сообщения + модерации.
    if (_tabs.indexOf(tab) != _profileTabIndex) {
      return iconWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        ValueListenableBuilder<int>(
          valueListenable: NotificationService().totalNotificationCount,
          builder: (context, count, _) {
            return NotificationBadge(count: count, size: 20);
          },
        ),
      ],
    );
  }
}
