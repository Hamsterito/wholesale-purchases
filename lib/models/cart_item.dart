import 'product.dart';

class CartItem {
  final Product product;
  final Supplier supplier;
  final int quantity;

  const CartItem({
    required this.product,
    required this.supplier,
    required this.quantity,
  });

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      product: product,
      supplier: supplier,
      quantity: quantity ?? this.quantity,
    );
  }
}
