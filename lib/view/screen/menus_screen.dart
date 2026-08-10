import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/view/screen/AddProduct_Screen.dart';
import 'package:sales_management/view/screen/EditInvoice_Screen.dart';
import 'package:sales_management/view/screen/InventoryScreen.dart';
import 'package:sales_management/view/screen/InvoiceDetails_Screen.dart';
import 'package:sales_management/view/screen/Reports_Screen.dart';
import 'package:sales_management/view/screen/SalesScreen.dart';

class MenusScreen extends StatefulWidget {
  const MenusScreen({super.key});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
  List<InvoiceModel> invoices = [];
  List<InvoiceModel> filteredInvoices = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================
  // جلب الفواتير
  // =========================

  Future<void> loadInvoices() async {
    final data = await DatabaseHelper.instance.getInvoices();

    if (!mounted) return;

    setState(() {
      invoices = data;
      filteredInvoices = data;
      isLoading = false;
    });
  }

  // =========================
  // البحث
  // =========================

  void searchInvoices(String value) {
    final searchText = value.trim().toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        filteredInvoices = invoices;
      } else {
        filteredInvoices = invoices.where((invoice) {
          return invoice.customerName.toLowerCase().contains(searchText) ||
              invoice.paymentType.toLowerCase().contains(searchText);
        }).toList();
      }
    });
  }

  // =========================
  // مسح البحث
  // =========================

  void clearSearch() {
    searchController.clear();

    setState(() {
      filteredInvoices = invoices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011236),

      // =========================
      // AppBar
      // =========================
      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'القوائم',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =========================
      // Body
      // =========================
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
            // خانة البحث
            // =========================
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
              child: TextField(
                controller: searchController,
                onChanged: searchInvoices,

                decoration: InputDecoration(
                  hintText: "بحث عن اسم القائمة",

                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: clearSearch,
                        )
                      : null,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            // =========================
            // قائمة الفواتير
            // =========================
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredInvoices.isEmpty
                  ? const Center(
                      child: Text(
                        "لا توجد قوائم",
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),

                      itemCount: filteredInvoices.length,

                      itemBuilder: (context, index) {
                        final invoice = filteredInvoices[index];

                        return Card(
                          elevation: 3,

                          margin: const EdgeInsets.only(bottom: 10),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: ListTile(
                            // =========================
                            // أيقونة الفاتورة
                            // =========================
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF011236),

                              child: Icon(Icons.receipt, color: Colors.white),
                            ),

                            // =========================
                            // اسم الزبون
                            // =========================
                            title: Text(
                              invoice.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),

                            // =========================
                            // التاريخ وطريقة الدفع
                            // =========================
                            subtitle: Text(
                              "${invoice.date}\n"
                              "طريقة الدفع: "
                              "${invoice.paymentType}",
                            ),

                            // =========================
                            // الإجمالي
                            // =========================
                            trailing: Text(
                              "${invoice.total.toStringAsFixed(0)} د.ع",

                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            // =========================
                            // الضغط على القائمة
                            // =========================
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InvoiceDetailsScreen(invoice: invoice),
                                ),
                              );

                              // تحديث البيانات
                              // بعد الرجوع
                              await loadInvoices();
                            },

                            // =========================
                            // الضغط المطول
                            // =========================
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,

                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),

                                builder: (sheetContext) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        const SizedBox(height: 10),

                                        const Text(
                                          "خيارات القائمة",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // =========================
                                        // تعديل
                                        // =========================
                                        ListTile(
                                          leading: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),

                                          title: const Text("تعديل القائمة"),

                                          onTap: () async {
                                            Navigator.pop(sheetContext);

                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditInvoiceScreen(
                                                      invoice: invoice,
                                                    ),
                                              ),
                                            );

                                            if (result == true) {
                                              setState(() {});
                                            }
                                          },
                                        ),

                                        // =========================
                                        // حذف
                                        // =========================
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),

                                          title: const Text("حذف القائمة"),

                                          onTap: () async {
                                            Navigator.pop(sheetContext);

                                            final confirm = await showDialog<bool>(
                                              context: context,

                                              builder: (dialogContext) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    "حذف القائمة",
                                                  ),

                                                  content: const Text(
                                                    "هل أنت متأكد من حذف هذه القائمة؟\n"
                                                    "سيتم حذف الفاتورة وجميع المنتجات الموجودة فيها.",
                                                  ),

                                                  actions: [
                                                    // إلغاء
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                          dialogContext,
                                                          false,
                                                        );
                                                      },

                                                      child: const Text(
                                                        "إلغاء",
                                                      ),
                                                    ),

                                                    // حذف
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),

                                                      onPressed: () {
                                                        Navigator.pop(
                                                          dialogContext,
                                                          true,
                                                        );
                                                      },

                                                      child: const Text(
                                                        "حذف",
                                                        style: TextStyle(
                                                          color: Colors.white,
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

                                            await DatabaseHelper.instance
                                                .deleteInvoice(invoice.id!);

                                            // تحديث القائمة
                                            await loadInvoices();
                                          },
                                        ),

                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  );
                                },
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

      // =========================
      // Floating Action Button
      // =========================
      extendBody: true,

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF011236),

        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );

          await loadInvoices();
        },

        child: const Icon(Icons.add, color: Colors.white, size: 35),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // =========================
      // Bottom Navigation
      // =========================
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),

        notchMargin: 8,

        color: Colors.white,

        child: SizedBox(
          height: 65,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              // القوائم
              Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: const [
                  Icon(Icons.grid_view, color: Color(0xFF011236), size: 22),

                  SizedBox(height: 4),

                  Text(
                    "القوائم",
                    style: TextStyle(color: Color(0xFF011236), fontSize: 11),
                  ),
                ],
              ),
              // المبيعات
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesScreen()),
                  );

                  await loadInvoices();
                },

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: const [
                    Icon(Icons.receipt_long, color: Colors.grey, size: 22),

                    SizedBox(height: 4),

                    Text(
                      "المبيعات",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),

             

              const SizedBox(width: 40),
               // المخزن
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );

                  await loadInvoices();
                },

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: const [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey,
                      size: 22,
                    ),

                    SizedBox(height: 4),

                    Text(
                      "المخزن",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // التقارير
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bar_chart, color: Colors.grey, size: 22),
                    SizedBox(height: 4),
                    Text(
                      "تقارير",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
