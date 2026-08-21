class DebtPaymentModel {
  int? id;

  String customerName;

  double amount;

  String paymentDate;

  DebtPaymentModel({
    this.id,
    required this.customerName,
    required this.amount,
    required this.paymentDate,
  });

  // تحويل البيانات إلى Map لحفظها في SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'amount': amount,
      'paymentDate': paymentDate,
    };
  }

  // تحويل البيانات القادمة من SQLite إلى Model
  factory DebtPaymentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return DebtPaymentModel(
      id: map['id'],

      customerName:
          map['customerName'] ?? '',

      amount:
          (map['amount'] as num).toDouble(),

      paymentDate:
          map['paymentDate'] ?? '',
    );
  }
}