class SaleModel {
  int? id;
  int productId;
  String productName;
  String barcode;
  double price;
  int quantity;
  double total;
  String saleDate;

  SaleModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.price,
    required this.quantity,
    required this.total,
    required this.saleDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
      'total': total,
      'saleDate': saleDate,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      barcode: map['barcode'],
      price: map['price'],
      quantity: map['quantity'],
      total: map['total'],
      saleDate: map['saleDate'],
    );
  }
}