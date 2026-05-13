import 'package:flutter/material.dart';
import '../supplier/supplier_orders_page.dart';
import '../supplier/supplier_products_page.dart';
import '../supplier/supplier_profile_page.dart';
import '../supplier/supplier_qa_page.dart';
import 'nav_colors.dart';

class SupplierNavigation extends StatefulWidget {
  const SupplierNavigation({super.key});

  @override
  State<SupplierNavigation> createState() => _SupplierNavigationState();
}

class _SupplierNavigationState extends State<SupplierNavigation> {
  int _currentIndex = 0;
  int _unansweredCount = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SupplierProductsPage(),
      SupplierOrdersPage(),
      SupplierQAPage(onUnansweredCountChanged: _updateUnansweredCount),
      SupplierProfilePage(),
    ];
  }

  void _updateUnansweredCount(int count) {
    setState(() {
      _unansweredCount = count;
    });
  }

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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Товары',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: _buildQATabIcon(navColors),
            label: 'Q&A',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  Widget _buildQATabIcon(NavColors navColors) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Icon(Icons.help_outline),
        if (_unansweredCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: navColors.foreground,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unansweredCount > 99 ? '99+' : _unansweredCount.toString(),
                style: TextStyle(
                  color: navColors.background,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
