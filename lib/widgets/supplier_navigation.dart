import 'package:flutter/material.dart';
import '../supplier/supplier_orders_page.dart';
import '../supplier/supplier_products_page.dart';
import '../supplier/supplier_profile_page.dart';
import 'nav_colors.dart';

class SupplierNavigation extends StatefulWidget {
  const SupplierNavigation({super.key});

  @override
  State<SupplierNavigation> createState() => _SupplierNavigationState();
}

class _SupplierNavigationState extends State<SupplierNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SupplierProductsPage(),
    SupplierOrdersPage(),
    SupplierProfilePage(),
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
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Товары',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Заказы',
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

