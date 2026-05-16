import 'package:flutter/material.dart';
import '../theme/app_color_palette.dart';
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

  List<String> _normalizedImages() {
    final images = widget.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    return images.isEmpty ? [''] : images;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColorPalette.of(context);
    final images = _normalizedImages();

    return Container(
      color: palette.card,
      child: Container(
        color: palette.bgBottom,
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
                      placeholder: _buildPlaceholder(palette),
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
                            ? palette.accent
                            : palette.card.withValues(alpha: 0.7),
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

  Widget _buildPlaceholder(AppColorPalette palette) {
    return Container(
      color: palette.bgBottom,
      child: Icon(Icons.image, size: 100, color: palette.muted),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
