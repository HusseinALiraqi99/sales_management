import 'package:flutter/material.dart';

import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/view/screen/DebtHistory_Screen.dart';

import 'package:sales_management/view/screen/EditInvoice_Screen.dart';
import 'package:sales_management/view/screen/InvoiceDetails_Screen.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() =>
      _DebtScreenState();
}
double totalDebt = 0;

class _DebtScreenState extends State<DebtScreen> {

  List<InvoiceModel> debts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  // =========================
  // تحميل الديون
  // =========================

  Future<void> loadDebts() async {
  try {
    final result =
        await DatabaseHelper.instance.getDebtInvoices();

    double total = 0;

    for (final debt in result) {
      total += debt.total;
    }

    if (!mounted) return;

    setState(() {
      debts = result;
      totalDebt = total;
      isLoading = false;
    });
  } catch (e) {
    debugPrint("ERROR LOAD DEBTS: $e");

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}
  // =========================
  // حذف الدين
  // =========================

  Future<void> showDeleteDialog(
    InvoiceModel debt,
  ) async {

    final confirm =
        await showDialog<bool>(
      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(
            "حذف الدين",
            textAlign: TextAlign.right,
          ),

          content: Text(
            "هل أنت متأكد من حذف دين "
            "${debt.customerName}؟\n\n"
            "المبلغ: "
            "${debt.total.toStringAsFixed(0)} د.ع",

            textAlign: TextAlign.right,
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                "إلغاء",
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                "حذف",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {

      await DatabaseHelper.instance
          .deleteInvoiceWithSales(
        debt.id!,
      );

      await loadDebts();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "تم حذف الدين بنجاح",
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "حدث خطأ أثناء الحذف: $e",
          ),
        ),
      );
    }
  }

  // =========================
  // خيارات الضغط المطول
  // =========================

  void showDebtOptions(
    InvoiceModel debt,
  ) {

    showModalBottomSheet(
      context: context,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {

        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              
              Padding(
  padding: const EdgeInsets.fromLTRB(
    15,
    20,
    15,
    10,
  ),
  child: Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.blue,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                "إجمالي الديون",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Text(
            "${totalDebt.toStringAsFixed(0)} د.ع",
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
),

              const SizedBox(
                height: 10,
              ),

              const Text(
                "خيارات الدين",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // =====================
              // تعديل
              // =====================

              ListTile(

                leading:
                    const Icon(
                  Icons.edit,
                  color: Colors.blue,
                ),

                title: const Text(
                  "تعديل الدين",
                ),

                onTap: () async {

                  Navigator.pop(
                    context,
                  );

                  final result =
                      await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditInvoiceScreen(
                        invoice: debt,
                      ),
                    ),
                  );

                  if (result == true) {
                    await loadDebts();
                  }
                },
              ),

              // =====================
              // حذف
              // =====================

              ListTile(

                leading:
                    const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),

                title: const Text(
                  "حذف الدين",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),

                onTap: () async {

                  Navigator.pop(
                    context,
                  );

                  await showDeleteDialog(
                    debt,
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
    );
  }

  // =========================
  // الواجهة
  // =========================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(0xFF011236),

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF011236),

        elevation: 0,

        centerTitle: true,

        title: const Text(
          "الديون",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        // =====================
        // زر السجل
        // =====================

        actions: [

          IconButton(
            tooltip: "سجل الديون",

            icon: const Icon(
              Icons.history,
              color: Colors.white,
              size: 28,
            ),

            onPressed: () async {

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DebtHistoryScreen(),
                ),
              );

              await loadDebts();
            },
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),
      

      body: Container(

        width: double.infinity,

        decoration:
            const BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.only(
            topLeft:
                Radius.circular(40),
            topRight:
                Radius.circular(40),
          ),
        ),

        child: isLoading

            ? const Center(
                child:
                    CircularProgressIndicator(),
              )

            : debts.isEmpty

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
                        const EdgeInsets.all(
                      15,
                    ),

                    itemCount:
                        debts.length,

                    itemBuilder:
                        (context, index) {

                      final debt =
                          debts[index];

                      return Card(

                        elevation: 3,

                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),

                        child: ListTile(

                          // =================
                          // اسم الزبون
                          // =================

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
                            debt.customerName,

                            style:
                                const TextStyle(
                              color:
                                  Colors.blue,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          subtitle: Text(
                            "التاريخ: "
                            "${debt.date}\n"
                            "طريقة الدفع: "
                            "${debt.paymentType}",
                          ),

                          trailing: Text(
                            "${debt.total.toStringAsFixed(0)} د.ع",

                            style:
                                const TextStyle(
                              color:
                                  Colors.blue,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          // =================
                          // ضغط عادي
                          // =================

                          onTap: () async {

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceDetailsScreen(
                                  invoice: debt,
                                ),
                              ),
                            );

                            await loadDebts();
                          },

                          // =================
                          // ضغط مطول
                          // =================

                          onLongPress: () {

                            showDebtOptions(
                              debt,
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}