import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import 'address_page.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  static const Color _primaryColor = Color(0xFF6288D5);

  final List<_AddressEntry> _addresses = const [
    _AddressEntry(
      icon: Icons.home_outlined,
      title: 'HOME',
      address: '2464 Royal Ln. Mesa, New Jersey 45463',
    ),
    _AddressEntry(
      icon: Icons.work_outline,
      title: 'WORK',
      address: '3891 Ranchview Dr. Richardson, California 62639',
    ),
  ];

  int _selectedIndex = 0;

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? _theme.scaffoldBackgroundColor : const Color(0xFFF3F6FB);
  Color get _cardBg => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurfaceVariant;

  void _openAddressEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primarySoft = _primaryColor.withValues(alpha: _isDark ? 0.18 : 0.12);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Мой адрес',
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openAddressEditor,
            icon: const Icon(Icons.add_circle_outline, color: _primaryColor),
            tooltip: 'Добавить адрес',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _addresses[index];
          return _buildAddressCard(
            context: context,
            icon: entry.icon,
            iconColor: _primaryColor,
            iconBgColor: primarySoft,
            title: entry.title,
            address: entry.address,
            isSelected: index == _selectedIndex,
            onTap: () => setState(() => _selectedIndex = index),
          );
        },
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String address,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? _primaryColor : Colors.transparent;
    final shadowColor = _isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);

    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        color: _mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _openAddressEditor,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _primaryColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Редактировать',
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showDeleteDialog(context, title),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: _primaryColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Удалить',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить адрес?'),
          content: Text('Вы уверены, что хотите удалить адрес "$title"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }
}

class _AddressEntry {
  final IconData icon;
  final String title;
  final String address;

  const _AddressEntry({
    required this.icon,
    required this.title,
    required this.address,
  });
}
