import 'product_model.dart';

class CartItemModel {
  ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice {
    return product.sellPrice * quantity;
  }
}