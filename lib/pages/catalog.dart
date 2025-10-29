import 'package:flutter/material.dart';

enum CategoryFilter { all, drinks, vegetables, bread, dairy, meat }

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  CategoryFilter _selectedFilter = CategoryFilter.all;

  void _onFilterTapped(CategoryFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  bool _shouldShowCategory(CategoryFilter category) {
    if (_selectedFilter == CategoryFilter.all) return true;
    return _selectedFilter == category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterTabs(),
            Expanded(child: _buildCategoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Каталог',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Поиск...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('Все', CategoryFilter.all),
                  const SizedBox(width: 12),
                  _buildFilterButton('Напитки', CategoryFilter.drinks),
                  const SizedBox(width: 12),
                  _buildFilterButton('Овощи фрукты', CategoryFilter.vegetables),
                  const SizedBox(width: 12),
                  _buildFilterButton('Хлеб', CategoryFilter.bread),
                  const SizedBox(width: 12),
                  _buildFilterButton('Молочка', CategoryFilter.dairy),
                  const SizedBox(width: 12),
                  _buildFilterButton('Мясо', CategoryFilter.meat),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, CategoryFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterTapped(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6288D5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_shouldShowCategory(CategoryFilter.bread)) ...[
          _buildCategoryTitle('Хлеб и пекарня'),
          const SizedBox(height: 12),
          _buildCategoryRow([
            _buildCategoryCard('Выпечка\nот Манса', Colors.orange[200]!),
            _buildCategoryCard('Хлеб', Colors.orange[200]!),
            _buildCategoryCard('Выпечка и\nпироги', Colors.orange[200]!),
          ]),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.vegetables)) ...[
          _buildCategoryTitle('Свежие овощи и фрукты'),
          const SizedBox(height: 12),
          _buildCategoryRow([
            _buildCategoryCard(
              'Фрукты, ягоды',
              Colors.green[300]!,
              height: 120,
            ),
            _buildCategoryCard(
              'Овощи, грибы и\nзелень',
              Colors.green[300]!,
              height: 120,
            ),
          ]),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.dairy)) ...[
          _buildCategoryTitle('Молоко, яйца и сыр'),
          const SizedBox(height: 12),
          _buildCategoryRow([
            _buildCategoryCard('Сыр', Colors.brown[100]!),
            _buildCategoryCard('Творог,\nсметана', Colors.brown[100]!),
            _buildCategoryCard('Йогурт и\nдесерты', Colors.brown[100]!),
          ]),
          const SizedBox(height: 12),
          _buildCategoryRow([
            _buildCategoryCard(
              'Молоко\nкисломолочные\nпродукты',
              Colors.yellow[100]!,
            ),
            _buildCategoryCard('Масло и яйца', Colors.yellow[100]!),
          ]),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.meat)) ...[
          _buildCategoryTitle('Мясная лавка'),
          const SizedBox(height: 12),
          _buildCategoryRow([
            _buildCategoryCard('Мясо и\nптица', Colors.pink[100]!),
            _buildCategoryCard('Колбасы и\nсосиски', Colors.pink[100]!),
            _buildCategoryCard('Мясные\nделикатесы', Colors.pink[100]!),
          ]),
          const SizedBox(height: 24),
        ],
        if (_shouldShowCategory(CategoryFilter.drinks)) ...[
          _buildCategoryTitle('Напитки'),
          const SizedBox(height: 12),
          _buildCategoryRow([
            _buildCategoryCard('Вода', Colors.blue[100]!),
            _buildCategoryCard('Соки', Colors.orange[100]!),
            _buildCategoryCard('Газировка', Colors.blue[200]!),
          ]),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCategoryCard(String title, Color color, {double? height}) {
    return Expanded(
      child: Container(
        height: height ?? 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(List<Widget> cards) {
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          cards[i],
        ],
      ],
    );
  }
}
