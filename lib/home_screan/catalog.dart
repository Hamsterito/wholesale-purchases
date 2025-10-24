import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalog',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const CatalogPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum CategoryFilter { all, drinks, vegetables, bread, dairy, meat }

class CatalogPage extends StatefulWidget {
  const CatalogPage({Key? key}) : super(key: key);

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Астана, Coffe Boom, проспект мангилик Ел...',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Поиск
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Фильтры
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.sort, size: 20),
                  SizedBox(width: 8),
                  Icon(Icons.tune, size: 20),
                  SizedBox(width: 16),
                  _buildFilterButton('Все', CategoryFilter.all),
                  SizedBox(width: 16),
                  _buildFilterButton('Напитки', CategoryFilter.drinks),
                  SizedBox(width: 16),
                  _buildFilterButton('Овощи фрукты', CategoryFilter.vegetables),
                  SizedBox(width: 16),
                  _buildFilterButton('Хлеб', CategoryFilter.bread),
                  SizedBox(width: 16),
                  _buildFilterButton('Молочка', CategoryFilter.dairy),
                  SizedBox(width: 16),
                  _buildFilterButton('Мясо', CategoryFilter.meat),
                ],
              ),
            ),
          ),

          // Категории
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Хлеб и пекарня
                if (_shouldShowCategory(CategoryFilter.bread)) ...[
                  _buildCategoryTitle('Хлеб и пекарня'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Выпечка\nот Манса',
                          Colors.orange[200]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Хлеб',
                          Colors.orange[300]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Выпечка и\nпироги',
                          Colors.orange[200]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Свежие овощи и фрукты
                if (_shouldShowCategory(CategoryFilter.vegetables)) ...[
                  _buildCategoryTitle('Свежие овощи и фрукты'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Фрукты, ягоды',
                          Colors.green[300]!,
                          height: 120,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Овощи, грибы и\nзелень',
                          Colors.green[300]!,
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Молоко, яйца и сыр
                if (_shouldShowCategory(CategoryFilter.dairy)) ...[
                  _buildCategoryTitle('Молоко, яйца и сыр'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Сыр',
                          Colors.brown[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Творог,\nсметана',
                          Colors.brown[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Йогурт и\nдесерты',
                          Colors.brown[100]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Молоко\nкисломолочные\nпродукты',
                          Colors.yellow[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Масло и яйца',
                          Colors.yellow[100]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Мясная лавка
                if (_shouldShowCategory(CategoryFilter.meat)) ...[
                  _buildCategoryTitle('Мясная лавка'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Мясо и\nптица',
                          Colors.pink[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Колбасы и\nсосиски',
                          Colors.pink[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Мясные\nделикатесы',
                          Colors.pink[100]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Напитки (пример категории)
                if (_shouldShowCategory(CategoryFilter.drinks)) ...[
                  _buildCategoryTitle('Напитки'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          'Вода',
                          Colors.blue[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Соки',
                          Colors.orange[100]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          'Газировка',
                          Colors.blue[200]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
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
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCategoryCard(String title, Color color, {double? height}) {
    return Container(
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}