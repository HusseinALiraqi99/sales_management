import 'package:flutter/material.dart';

import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/view/screen/DebtHistory_Screen.dart';
import 'package:sales_management/view/screen/EditInvoice_Screen.dart';
import 'package:sales_management/view/screen/InvoiceDetails_Screen.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

// ============================================================
// موديل عرض دين الزبون
// ============================================================

class CustomerDebt {
  final String customerName;

  double totalDebt;
  double paidAmount;
  double remainingDebt;

  final List<InvoiceModel> invoices;

  CustomerDebt({
    required this.customerName,
    required this.totalDebt,
    required this.paidAmount,
    required this.remainingDebt,
    required this.invoices,
  });
}

// ============================================================
// STATE
// ============================================================

class _DebtScreenState extends State<DebtScreen> {
  List<CustomerDebt> customerDebts = [];

  bool isLoading = true;

  double totalDebt = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadDebts();
  }

  // ============================================================
  // تحميل الديون
  // ============================================================

  Future<void> loadDebts() async {
    try {
      final invoices =
          await DatabaseHelper.instance.getDebtInvoices();

      final Map<String, List<InvoiceModel>> grouped = {};

      // ----------------------------------------------------------
      // تجميع الفواتير حسب اسم الزبون
      // ----------------------------------------------------------

      for (final invoice in invoices) {
        final customer =
            invoice.customerName.trim();

        if (customer.isEmpty) {
          continue;
        }

        if (!grouped.containsKey(customer)) {
          grouped[customer] = [];
        }

        grouped[customer]!.add(invoice);
      }

      final List<CustomerDebt> result = [];

      double grandTotalRemaining = 0;

      // ----------------------------------------------------------
      // حساب دين كل زبون
      // ----------------------------------------------------------

      for (final entry in grouped.entries) {
        final customerName = entry.key;

        final customerInvoices = entry.value;

        double debt = 0;

        for (final invoice in customerInvoices) {
          debt += invoice.total;
        }

        // --------------------------------------------------------
        // جلب المبلغ المسدد
        // --------------------------------------------------------

        double paid = 0;

        try {
          paid = await DatabaseHelper.instance
              .getCustomerPaidAmount(customerName);
        } catch (e) {
          debugPrint(
            "ERROR GET PAID AMOUNT: $e",
          );

          paid = 0;
        }

        // --------------------------------------------------------
        // حساب المتبقي
        // --------------------------------------------------------

        double remaining =
            debt - paid;

        if (remaining < 0) {
          remaining = 0;
        }

        // --------------------------------------------------------
        // نعرض الزبون فقط إذا بقي عليه دين
        // --------------------------------------------------------

        if (remaining > 0) {
          result.add(
            CustomerDebt(
              customerName: customerName,
              totalDebt: debt,
              paidAmount: paid,
              remainingDebt: remaining,
              invoices: customerInvoices,
            ),
          );

          grandTotalRemaining += remaining;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        customerDebts = result;
        totalDebt = grandTotalRemaining;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "ERROR LOAD DEBTS: $e",
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // حذف الدين
  // ============================================================

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

    if (confirm != true) {
      return;
    }

    try {
      await DatabaseHelper.instance
          .deleteInvoiceWithSales(
        debt.id!,
      );

      await loadDebts();

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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

  // ============================================================
  // خيارات الدين
  // ============================================================

  void showDebtOptions(
    CustomerDebt customer,
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
              // --------------------------------------------------
              // معلومات الدين
              // --------------------------------------------------

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  15,
                  20,
                  15,
                  10,
                ),
                child: Card(
                  elevation: 4,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              "الزبون",
                              style:
                                  TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              customer.customerName,
                              style:
                                  const TextStyle(
                                color: Colors.blue,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              "إجمالي الدين",
                              style:
                                  TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${customer.totalDebt.toStringAsFixed(0)} د.ع",
                              style:
                                  const TextStyle(
                                color: Colors.red,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              "المسدد",
                              style:
                                  TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${customer.paidAmount.toStringAsFixed(0)} د.ع",
                              style:
                                  const TextStyle(
                                color: Colors.green,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const Divider(
                          height: 20,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              "المتبقي",
                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${customer.remainingDebt.toStringAsFixed(0)} د.ع",
                              style:
                                  const TextStyle(
                                color: Colors.blue,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
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

              // --------------------------------------------------
              // تعديل
              // --------------------------------------------------

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

                  if (customer.invoices.isEmpty) {
                    return;
                  }

                  final result =
                      await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditInvoiceScreen(
                        invoice:
                            customer.invoices.first,
                      ),
                    ),
                  );

                  if (result == true) {
                    await loadDebts();
                  }
                },
              ),

              // --------------------------------------------------
              // حذف
              // --------------------------------------------------

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

                  if (customer.invoices.isEmpty) {
                    return;
                  }

                  await showDeleteDialog(
                    customer.invoices.first,
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

  // ============================================================
  // الواجهة
  // ============================================================

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

        actions: [
          // ------------------------------------------------------
          // سجل الديون
          // ------------------------------------------------------

          IconButton(
            tooltip: "سجل الديون",
            icon: Column(
              children: [
                const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(height: 2),
                Text(
                  "السجل",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                  ),
                ),
              ],
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
            : customerDebts.isEmpty
                ? const Center(
                    child: Text(
                      "لا توجد ديون",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // ==================================================
                      // إجمالي الديون المتبقية
                      // ==================================================

                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          15,
                          15,
                          15,
                          5,
                        ),
                        child: Card(
                          elevation: 4,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .account_balance_wallet,
                                      color:
                                          Colors.blue,
                                      size: 30,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "إجمالي الديون",
                                      style:
                                          TextStyle(
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),

                                Text(
                                  "${totalDebt.toStringAsFixed(0)} د.ع",
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.blue,
                                    fontSize:
                                        20,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // قائمة الزبائن
                      // ==================================================

                      Expanded(
                        child:
                            ListView.builder(
                          padding:
                              const EdgeInsets.all(
                            15,
                          ),
                          itemCount:
                              customerDebts.length,
                          itemBuilder:
                              (context, index) {
                            final customer =
                                customerDebts[
                                    index];

                            return Card(
                              elevation: 3,
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 12,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  15,
                                ),
                              ),
                              child: ListTile(
                                // --------------------------------
                                // اسم الزبون
                                // --------------------------------

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
                                  customer
                                      .customerName,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.blue,
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                // --------------------------------
                                // التفاصيل
                                // --------------------------------

                                subtitle:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      "${customer.invoices.length} قائمة",
                                    ),

                                    Text(
                                      "إجمالي الدين: "
                                      "${customer.totalDebt.toStringAsFixed(0)} د.ع",
                                    ),

                                    Text(
                                      "المسدد: "
                                      "${customer.paidAmount.toStringAsFixed(0)} د.ع",
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.green,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 3,
                                    ),

                                    Text(
                                      "المتبقي: "
                                      "${customer.remainingDebt.toStringAsFixed(0)} د.ع",
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.blue,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // --------------------------------
                                // المتبقي على اليمين
                                // --------------------------------

                                trailing:
                                    Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    const Text(
                                      "المتبقي",
                                      style:
                                          TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "${customer.remainingDebt.toStringAsFixed(0)} د.ع",
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.blue,
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // --------------------------------
                                // الضغط
                                // --------------------------------

                                onTap: () async {
                                  if (customer
                                      .invoices
                                      .isEmpty) {
                                    return;
                                  }

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InvoiceDetailsScreen(
                                        invoice:
                                            customer
                                                .invoices
                                                .first,
                                      ),
                                    ),
                                  );

                                  await loadDebts();
                                },

                                // --------------------------------
                                // الضغط المطول
                                // --------------------------------

                                onLongPress: () {
                                  showDebtOptions(
                                    customer,
                                  );
                                },
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