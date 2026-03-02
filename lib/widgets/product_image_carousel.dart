import 'package:flutter/material.dart';
import 'smart_image.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const ProductImageCarousel({super.key, required this.imageUrls});

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  Color get _cardBg => _colorScheme.surface;
  Color get _surfaceContainer => _colorScheme.surfaceContainerHighest;
  Color get _mutedText => _colorScheme.onSurfaceVariant;

  List<String> _normalizedImages() {
    final images = widget.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    return images.isEmpty ? [''] : images;
  }

  @override
  Widget build(BuildContext context) {
    final images = _normalizedImages();

    return Container(
      color: _cardBg,
      child: Container(
        color: _surfaceContainer,
        height: 400,
        child: Stack(
          children: [
            RepaintBoundary(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final path = images[index];
                  return Center(
                    child: SmartImage(
                      path: path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: _buildPlaceholder(),
                    ),
                  );
                },
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _currentIndex == index
                            ? const Color(0xFF6288D5)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _surfaceContainer,
      child: Icon(Icons.image, size: 100, color: _mutedText),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
