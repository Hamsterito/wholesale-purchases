import 'package:flutter/material.dart';
import '../moderator/moderation_page.dart';
import '../moderator/moderator_profile_page.dart';
import 'nav_colors.dart';

class ModeratorNavigation extends StatefulWidget {
  const ModeratorNavigation({super.key});

  @override
  State<ModeratorNavigation> createState() => _ModeratorNavigationState();
}

class _ModeratorNavigationState extends State<ModeratorNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ModerationPage(),
    ModeratorProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final navColors = NavColors.of(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: navColors.foreground,
        unselectedItemColor: navColors.foregroundMuted,
        backgroundColor: navColors.background,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Модерация',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

