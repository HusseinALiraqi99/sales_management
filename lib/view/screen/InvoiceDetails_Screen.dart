import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/models/sale_model.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState
    extends State<InvoiceDetailsScreen> {
  List<SaleModel> items = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    items = await DatabaseHelper.instance
        .getSalesByInvoice(widget.invoice.id!);

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011236),

      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),
        centerTitle: true,
        title: const Text(
          "تفاصيل الفاتورة",
          style: TextStyle(color: Colors.white),
        ),
      ),
    body: Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(40),
      topRight: Radius.circular(40),
    ),
  ),
  child: isLoading
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "الزبون : ${widget.invoice.customerName}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "التاريخ : ${widget.invoice.date}",
            ),

            const SizedBox(height: 8),

            Text(
              "طريقة الدفع : ${widget.invoice.paymentType}",
            ),

            const Divider(height: 30),

            const Text(
              "الأصناف",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {

                  final item = items[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.inventory,
                      ),

                      title: Text(item.productName),

                      subtitle: Text(
                        "الكمية : ${item.quantity}\nالسعر : ${item.price}",
                      ),

                      trailing: Text(
                        "${item.total} د.ع",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "الإجمالي : ${widget.invoice.total} د.ع",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
),
);
}
}
      