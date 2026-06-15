// Роль-зависимая нижняя навигация. Один виджет для всех ролей, поэтому
// все панели выглядят одинаково - визуал скопирован с BottomNavBar.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'nav_colors.dart';
import 'nav_helpers.dart';
import 'nav_role.dart';
import 'notification_badge.dart';
import '../../core/ui/theme/app_dimensions.dart';

/// Универсальная нижняя навигация, управляемая списком вкладок.
///
/// Принимает индекс активной вкладки и коллбэк нажатия - вызывающий код
/// решает, переключать ли индекс локально или делать pushAndRemoveUntil.
class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  /// Вкладки роли в порядке слева направо.
  final List<RoleNavTab> tabs;

  /// Индекс активной вкладки. null - ни одна не выделена (внутренние экраны).
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
        minimum: const EdgeInsets.only(bottom: AppDimensions.minBottomSafePadding),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                _buildNavItem(context, tabs[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, RoleNavTab tab, int index) {
    final isActive = isTabActive(currentIndex, index, tabs.length);
    final navColors = NavColors.of(context);
    final activeColor = navColors.foreground;
    final inactiveColor = navColors.foregroundMuted;
    final splashColor = activeColor.withValues(alpha: 0.18);
    final highlightColor = activeColor.withValues(alpha: 0.12);
    final hoverColor = activeColor.withValues(alpha: 0.08);
    bool isPressed = false;

    // Семантика на всю вкладку: screen reader озвучивает метку и состояние
    // выбора, а SVG из семантики исключён ниже в _buildIcon.
    return Expanded(
      child: Semantics(
        label: tab.label,
        button: true,
        selected: isActive,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(tab, isActive, activeColor, inactiveColor),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? activeColor : inactiveColor,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(
    RoleNavTab tab,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isModeratorsTab = tab.icon == 'assets/icons/moderators.svg';
    final iconSize = isModeratorsTab ? 36.0 : 28.0;
    final iconOffsetY = isModeratorsTab ? 0.0 : 0.0;
    const iconSlotSize = 28.0;


    final iconWidget = ExcludeSemantics(
      child: SizedBox(
        width: iconSize,
        height: iconSlotSize,
        child: OverflowBox(
          maxWidth: iconSize,
          maxHeight: iconSize,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: Offset(0, iconOffsetY),
            child: SvgPicture.asset(
              isActive ? tab.activeIcon : tab.icon,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                isActive ? activeColor : inactiveColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );

    final source = tab.badgeCount;
    if (source == null) return iconWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        ValueListenableBuilder<int>(
          valueListenable: source,
          builder: (context, count, _) {
            return NotificationBadge(
              count: count,
              size: 20,
              // Метка значка называет вкладку и число; при 0 значок скрыт,
              // и метка не нужна.
              semanticLabel: count > 0
                  ? badgeSemanticLabel(tab.label, count)
                  : null,
            );
          },
        ),
      ],
    );
  }
}
