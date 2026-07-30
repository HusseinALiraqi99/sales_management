class SaleModel {
  int? id;
  int? invoiceId;

  int productId;
  String productName;
  String barcode;
  double price;
  int quantity;
  double total;
  String saleDate;

  SaleModel({
    this.id,
    this.invoiceId,
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
      'invoiceId': invoiceId,
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
      invoiceId: map['invoiceId'],
      productId: map['productId'],
      productName: map['productName'],
      barcode: map['barcode'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      total: (map['total'] as num).toDouble(),
      saleDate: map['saleDate'],
    );
  }
}