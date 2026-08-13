import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/view/screen/InvoiceDetails_Screen.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() =>
      _DebtHistoryScreenState();
}

class _DebtHistoryScreenState
    extends State<DebtHistoryScreen> {

  final TextEditingController searchController =
      TextEditingController();

  List<InvoiceModel> allDebts = [];
  List<InvoiceModel> filteredDebts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================
  // تحميل سجل الديون
  // =========================

  Future<void> loadHistory() async {
    try {
      final debts =
          await DatabaseHelper.instance.getDebtHistory();

      if (!mounted) return;

      setState(() {
        allDebts = debts;
        filteredDebts = debts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD DEBT HISTORY: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "حدث خطأ أثناء تحميل سجل الديون: $e",
          ),
        ),
      );
    }
  }

  // =========================
  // البحث
  // =========================

  void searchCustomer(String value) {
    final keyword = value.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        filteredDebts = allDebts;
      } else {
        filteredDebts = allDebts.where((invoice) {
          return invoice.customerName
              .toLowerCase()
              .contains(keyword);
        }).toList();
      }
    });
  }

  // =========================
  // تجميع الديون حسب الزبون
  // =========================

  Map<String, List<InvoiceModel>> get groupedDebts {

    final Map<String, List<InvoiceModel>> result = {};

    for (final invoice in filteredDebts) {
      final customer = invoice.customerName.trim();

      if (!result.containsKey(customer)) {
        result[customer] = [];
      }

      result[customer]!.add(invoice);
    }

    return result;
  }

  // =========================
  // مجموع دين الزبون
  // =========================

  double customerTotal(
    List<InvoiceModel> invoices,
  ) {
    double total = 0;

    for (final invoice in invoices) {
      total += invoice.total;
    }

    return total;
  }

  // =========================
  // الواجهة
  // =========================

  @override
  Widget build(BuildContext context) {

    final groups = groupedDebts;

    return Scaffold(
      backgroundColor: const Color(0xFF011236),

      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "سجل الديون",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),

        child: Column(
          children: [

            // =========================
            // البحث
            // =========================

            Padding(
              padding: const EdgeInsets.all(15),

              child: TextField(
                controller: searchController,
                onChanged: searchCustomer,

                decoration: InputDecoration(
                  hintText: "ابحث باسم الزبون",

                  prefixIcon: const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                      searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                              ),
                              onPressed: () {
                                searchController.clear();
                                searchCustomer("");
                              },
                            )
                          : null,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            // =========================
            // المحتوى
            // =========================

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )

                  : groups.isEmpty
                      ? const Center(
                          child: Text(
                            "لا توجد ديون",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                        )

                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),

                          itemCount: groups.length,

                          itemBuilder:
                              (context, index) {

                            final customerName =
                                groups.keys.elementAt(
                              index,
                            );

                            final invoices =
                                groups[customerName]!;

                            final total =
                                customerTotal(
                              invoices,
                            );

                            return Card(
                              elevation: 4,

                              margin:
                                  const EdgeInsets.only(
                                bottom: 15,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),

                              child: ExpansionTile(

                                leading:
                                    const CircleAvatar(
                                  backgroundColor:
                                      Colors.blue,

                                  child: Icon(
                                    Icons.person,
                                    color:
                                        Colors.white,
                                  ),
                                ),

                                title: Text(
                                  customerName,
                                  style:
                                      const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text(
                                  "${invoices.length} قائمة"
                                  "  •  "
                                  "المجموع: "
                                  "${total.toStringAsFixed(0)} د.ع",
                                ),

                                children: [

                                  const Divider(
                                    height: 1,
                                  ),

                                  // =====================
                                  // قوائم الزبون
                                  // =====================

                                  ...invoices.map(
                                    (invoice) {

                                      return ListTile(

                                        leading:
                                            const Icon(
                                          Icons
                                              .receipt_long,
                                          color:
                                              Colors.blue,
                                        ),

                                        title: Text(
                                          "قائمة رقم ${invoice.id}",
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        subtitle:
                                            Text(
                                          "التاريخ: "
                                          "${invoice.date}",
                                        ),

                                        trailing:
                                            Text(
                                          "${invoice.total.toStringAsFixed(0)} د.ع",
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.blue,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        onTap: () async {

                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      InvoiceDetailsScreen(
                                                invoice:
                                                    invoice,
                                              ),
                                            ),
                                          );

                                          loadHistory();
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}