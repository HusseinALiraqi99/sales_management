class InvoiceModel {
  int? id;
  String customerName;
  String date;
  double total;
  String paymentType;
  String notes;

  InvoiceModel({
    this.id,
    required this.customerName,
    required this.date,
    required this.total,
    this.paymentType = "نقدي",
    this.notes = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'date': date,
      'total': total,
      'paymentType': paymentType,
      'notes': notes,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      customerName: map['customerName'],
      date: map['date'],
      total: (map['total'] as num).toDouble(),
      paymentType: map['paymentType'] ?? "نقدي",
      notes: map['notes'] ?? "",
    );
  }
}