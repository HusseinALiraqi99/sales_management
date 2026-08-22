import 'package:flutter/material.dart';

import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/debt_payment_model.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/view/screen/InvoiceDetails_Screen.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController searchController = TextEditingController();

  // مهم:
  // هذا Controller تابع للصفحة وليس للـ Dialog
  // لذلك لا يتم عمل dispose له عند إغلاق Dialog.
  final TextEditingController amountController = TextEditingController();

  // ============================================================
  // DATA
  // ============================================================

  List<InvoiceModel> allDebts = [];
  List<InvoiceModel> filteredDebts = [];

  bool isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    amountController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD DEBT HISTORY
  // ============================================================

  Future<void> loadHistory() async {
    try {
      final debts = await DatabaseHelper.instance.getDebtHistory();

      if (!mounted) return;

      setState(() {
        allDebts = debts;
        filteredDebts = debts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR LOAD DEBT HISTORY: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('حدث خطأ أثناء تحميل الديون: $e'),
        ),
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void searchCustomer(String value) {
    final keyword = value.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      if (keyword.isEmpty) {
        filteredDebts = allDebts;
      } else {
        filteredDebts = allDebts.where((invoice) {
          return invoice.customerName.toLowerCase().contains(keyword);
        }).toList();
      }
    });
  }

  // ============================================================
  // GROUP BY CUSTOMER
  // ============================================================

  Map<String, List<InvoiceModel>> get groupedDebts {
    final Map<String, List<InvoiceModel>> result = {};

    for (final invoice in filteredDebts) {
      final customerName = invoice.customerName.trim();

      if (customerName.isEmpty) {
        continue;
      }

      result.putIfAbsent(customerName, () => []);

      result[customerName]!.add(invoice);
    }

    return result;
  }

  // ============================================================
  // CUSTOMER TOTAL
  // ============================================================

  double customerTotal(List<InvoiceModel> invoices) {
    double total = 0.0;

    for (final invoice in invoices) {
      total += invoice.total.toDouble();
    }

    return total;
  }

  // ============================================================
  // DEBT PAYMENT DIALOG
  // ============================================================

  Future<void> showDebtPaymentDialog() async {
    // تنظيف مبلغ قديم قبل فتح النافذة
    amountController.clear();

    // ==========================================================
    // CUSTOMER NAMES
    // ==========================================================

    List<String> customerNames = [];

    try {
      customerNames = await DatabaseHelper.instance.getDebtCustomerNames();
    } catch (e) {
      debugPrint('ERROR GET CUSTOMER NAMES: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('حدث خطأ أثناء جلب أسماء الزبائن: $e'),
        ),
      );

      return;
    }

    if (!mounted) return;

    // ==========================================================
    // DIALOG VARIABLES
    // ==========================================================

    String selectedCustomer = '';

    double totalDebt = 0.0;

    double paidAmount = 0.0;

    double remainingDebt = 0.0;

    bool loadingCustomer = false;

    bool savingPayment = false;

    // ==========================================================
    // SHOW DIALOG
    // ==========================================================

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // ==================================================
            // LOAD CUSTOMER DATA
            // ==================================================

            Future<void> loadCustomerData(String customerName) async {
              final name = customerName.trim();

              if (name.isEmpty) {
                setDialogState(() {
                  selectedCustomer = '';

                  totalDebt = 0.0;

                  paidAmount = 0.0;

                  remainingDebt = 0.0;

                  loadingCustomer = false;
                });

                return;
              }

              setDialogState(() {
                selectedCustomer = name;

                loadingCustomer = true;
              });

              try {
                final data = await DatabaseHelper.instance.getCustomerDebtData(
                  name,
                );

                final double debt = (data['debt'] ?? 0.0).toDouble();

                final double paid = (data['paid'] ?? 0.0).toDouble();

                double remaining = (data['remaining'] ?? 0.0).toDouble();

                if (remaining < 0) {
                  remaining = 0.0;
                }

                debugPrint('CUSTOMER: $name');

                debugPrint('DEBT DATA: $data');

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  totalDebt = debt;

                  paidAmount = paid;

                  remainingDebt = remaining;

                  loadingCustomer = false;
                });
              } catch (e) {
                debugPrint('ERROR GET CUSTOMER DEBT: $e');

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  totalDebt = 0.0;

                  paidAmount = 0.0;

                  remainingDebt = 0.0;

                  loadingCustomer = false;
                });
              }
            }

            // ==================================================
            // SAVE PAYMENT
            // ==================================================

            Future<void> savePayment() async {
              if (savingPayment) {
                return;
              }

              final customer = selectedCustomer.trim();

              if (customer.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('اختر اسم الزبون أولاً'),
                  ),
                );

                return;
              }

              final amount = double.tryParse(amountController.text.trim());

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('أدخل مبلغًا صحيحًا'),
                  ),
                );

                return;
              }

              // ==================================================
              // التحقق من الدين
              // ==================================================

              if (remainingDebt <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.orange,
                    content: Text('لا يوجد مبلغ دين متبقي على هذا الزبون'),
                  ),
                );

                return;
              }

              if (amount > remainingDebt) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('المبلغ أكبر من الدين المتبقي'),
                  ),
                );

                return;
              }

              // ==================================================
              // START SAVING
              // ==================================================

              setDialogState(() {
                savingPayment = true;
              });

              try {
                final payment = DebtPaymentModel(
                  customerName: customer,

                  amount: amount,

                  paymentDate: DateTime.now().toString(),
                );

                await DatabaseHelper.instance.insertDebtPayment(payment);
                await DatabaseHelper.instance.convertCustomerDebtToCash(
                  selectedCustomer,
                );

                // ==================================================
                // إغلاق الـ Dialog
                // ==================================================

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                // ==================================================
                // تحديث سجل الديون
                // ==================================================

                await loadHistory();

                if (!mounted) return;

                // ==================================================
                // تنظيف مبلغ التسديد
                // ==================================================

                amountController.clear();

                // ==================================================
                // رسالة النجاح
                // ==================================================

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('تم تسجيل تسديد الدين بنجاح'),
                  ),
                );
              } catch (e) {
                debugPrint('ERROR SAVE PAYMENT: $e');

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  savingPayment = false;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('حدث خطأ أثناء حفظ التسديد: $e'),
                  ),
                );
              }
            }

            // ==================================================
            // DIALOG UI
            // ==================================================

            return AlertDialog(
              insetPadding: const EdgeInsets.all(12),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              // ==================================================
              // TITLE
              // ==================================================
              title: const Text(
                'تسديد دين',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              // ==================================================
              // CONTENT
              // ==================================================
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(dialogContext).size.width * 0.9,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      // ==================================================
                      // CUSTOMER AUTOCOMPLETE
                      // ==================================================
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final keyword = textEditingValue.text
                              .trim()
                              .toLowerCase();

                          if (keyword.isEmpty) {
                            return const Iterable<String>.empty();
                          }

                          return customerNames.where(
                            (name) => name.toLowerCase().contains(keyword),
                          );
                        },

                        onSelected: (String name) {
                          loadCustomerData(name);
                        },

                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,

                                focusNode: focusNode,

                                decoration: InputDecoration(
                                  labelText: 'اسم الزبون',

                                  hintText: 'اكتب اسم الزبون',

                                  prefixIcon: const Icon(Icons.person),

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                onChanged: (value) {
                                  final typedName = value.trim();

                                  final exact = customerNames.where(
                                    (name) =>
                                        name.trim().toLowerCase() ==
                                        typedName.toLowerCase(),
                                  );

                                  if (exact.isNotEmpty) {
                                    loadCustomerData(exact.first);
                                  } else {
                                    setDialogState(() {
                                      selectedCustomer = '';

                                      totalDebt = 0.0;

                                      paidAmount = 0.0;

                                      remainingDebt = 0.0;
                                    });
                                  }
                                },
                              );
                            },
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // LOADING CUSTOMER
                      // ==================================================
                      if (loadingCustomer)
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(),
                        ),

                      // ==================================================
                      // DEBT DATA
                      // ==================================================
                      if (!loadingCustomer && selectedCustomer.isNotEmpty)
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(15),

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,

                            borderRadius: BorderRadius.circular(15),

                            border: Border.all(color: Colors.grey.shade300),
                          ),

                          child: Column(
                            children: [
                              // ==================================================
                              // TOTAL DEBT
                              // ==================================================
                              _debtRow(
                                title: 'إجمالي الدين',

                                value: totalDebt,

                                color: Colors.red,
                              ),

                              const SizedBox(height: 12),

                              // ==================================================
                              // PAID
                              // ==================================================
                              _debtRow(
                                title: 'المبلغ المسدد',

                                value: paidAmount,

                                color: Colors.green,
                              ),

                              const SizedBox(height: 12),

                              const Divider(),

                              const SizedBox(height: 8),

                              // ==================================================
                              // REMAINING
                              // ==================================================
                              _debtRow(
                                title: 'المبلغ المتبقي',

                                value: remainingDebt,

                                color: Colors.blue,

                                big: true,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // PAYMENT AMOUNT
                      // ==================================================
                      TextField(
                        controller: amountController,

                        enabled: !savingPayment,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),

                        decoration: InputDecoration(
                          labelText: 'المبلغ المسدد',

                          hintText: 'أدخل مبلغ التسديد',

                          prefixIcon: Column(
                            children: [
                              const Icon(Icons.payments),
                              SizedBox(height: 2),
                              Text(
                                " تسديد",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),

                          suffixText: 'د.ع',

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // DATE
                      // ==================================================
                      Container(
                        width: double.infinity,

                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                            ),

                            const SizedBox(width: 10),

                            Text(
                              _formatDate(DateTime.now()),
                              style: const TextStyle(fontSize: 16),
                            ),

                            const Spacer(),

                            const Text(
                              'تاريخ التسديد',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // ACTIONS
              // ==================================================
              actionsAlignment: MainAxisAlignment.center,

              actions: [
                // ==================================================
                // CANCEL
                // ==================================================
                TextButton(
                  onPressed: savingPayment
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },

                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                // ==================================================
                // SAVE
                // ==================================================
                ElevatedButton.icon(
                  onPressed: savingPayment ? null : savePayment,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF011236),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  icon: savingPayment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),

                  label: Text(
                    savingPayment ? 'جارٍ الحفظ...' : 'تسديد',

                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DEBT ROW
  // ============================================================

  Widget _debtRow({
    required String title,
    required double value,
    required Color color,
    bool big = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: big ? 17 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          '${value.toStringAsFixed(0)} د.ع',
          style: TextStyle(
            fontSize: big ? 20 : 17,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$year/$month/$day  $hour:$minute';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final groups = groupedDebts;

    return Scaffold(
      backgroundColor: const Color(0xFF011236),

      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),

        elevation: 0,

        centerTitle: true,

        title: const Text(
          'سجل الديون',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'تسديد دين',

            icon: Column(
              children: [
                const Icon(Icons.payments, color: Colors.white),
                const SizedBox(height: 2),
                Text(
                  'تسديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            onPressed: showDebtPaymentDialog,
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
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
            // ====================================================
            // SEARCH
            // ====================================================
            Padding(
              padding: const EdgeInsets.all(15),

              child: TextField(
                controller: searchController,

                onChanged: searchCustomer,

                decoration: InputDecoration(
                  hintText: 'ابحث باسم الزبون',

                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),

                          onPressed: () {
                            searchController.clear();

                            searchCustomer('');
                          },
                        )
                      : null,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            // ====================================================
            // LIST
            // ====================================================
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : groups.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد ديون',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),

                      itemCount: groups.length,

                      itemBuilder: (context, index) {
                        final customerName = groups.keys.elementAt(index);

                        final invoices = groups[customerName]!;

                        final total = customerTotal(invoices);

                        return Card(
                          elevation: 4,

                          margin: const EdgeInsets.only(bottom: 15),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: ExpansionTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,

                              child: Icon(Icons.person, color: Colors.white),
                            ),

                            title: Text(
                              customerName,

                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              '${invoices.length} قائمة'
                              '  •  '
                              'المجموع: '
                              '${total.toStringAsFixed(0)} د.ع',
                            ),

                            children: [
                              const Divider(height: 1),

                              ...invoices.map((invoice) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.blue,
                                  ),

                                  title: Text(
                                    'قائمة رقم ${invoice.id}',

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  subtitle: Text('التاريخ: ${invoice.date}'),

                                  trailing: Text(
                                    '${invoice.total.toStringAsFixed(0)} د.ع',

                                    style: const TextStyle(
                                      color: Colors.blue,

                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  onTap: () async {
                                    await Navigator.push(
                                      context,

                                      MaterialPageRoute(
                                        builder: (_) => InvoiceDetailsScreen(
                                          invoice: invoice,
                                        ),
                                      ),
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    await loadHistory();
                                  },
                                );
                              }),

                              const SizedBox(height: 10),
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
