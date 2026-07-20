class ProductModel {
  int? id;
  String name;
  String barcode;
  double buyPrice;
  double sellPrice;
  int quantity;
  String image;

  ProductModel({
    this.id,
    required this.name,
    required this.barcode,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'quantity': quantity,
      'image': image,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      buyPrice: map['buyPrice'],
      sellPrice: map['sellPrice'],
      quantity: map['quantity'],
      image: map['image'] ?? '',
    );
  }
}