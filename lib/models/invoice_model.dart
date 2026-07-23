class InvoiceModel {
  int? id;
  String date;
  double total;

  InvoiceModel({
    this.id,
    required this.date,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total': total,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      date: map['date'],
      total: map['total'],
    );
  }
}