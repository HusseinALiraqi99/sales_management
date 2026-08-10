import 'package:flutter/material.dart';

import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/view/screen/InvoiceDetails_Screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;

  List<InvoiceModel> todayInvoices = [];
  List<InvoiceModel> weekInvoices = [];
  List<InvoiceModel> monthInvoices = [];

  double todaySales = 0;
  double weekSales = 0;
  double monthSales = 0;

  double todayProfit = 0;
  double weekProfit = 0;
  double monthProfit = 0;

  @override
  void initState() {
    super.initState();

    loadReports();
  }

  // ============================================================
  // تحميل التقارير
  // ============================================================

  Future<void> loadReports() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();

      // ========================================================
      // اليوم
      // ========================================================

      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final tomorrowStart = todayStart.add(
        const Duration(days: 1),
      );

      // ========================================================
      // الأسبوع - يبدأ الاثنين
      // ========================================================

      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(
        Duration(days: now.weekday - 1),
      );

      final nextWeekStart = weekStart.add(
        const Duration(days: 7),
      );

      // ========================================================
      // الشهر
      // ========================================================

      final monthStart = DateTime(
        now.year,
        now.month,
        1,
      );

      final nextMonthStart = DateTime(
        now.year,
        now.month + 1,
        1,
      );

      // ========================================================
      // جلب فواتير اليوم
      // ========================================================

      final newTodayInvoices =
          await DatabaseHelper.instance
              .getInvoicesByPeriod(
        startDate: todayStart,
        endDate: tomorrowStart,
      );

      // ========================================================
      // جلب مبيعات اليوم
      // ========================================================

      final newTodaySales =
          await DatabaseHelper.instance
              .getSalesTotalByPeriod(
        startDate: todayStart,
        endDate: tomorrowStart,
      );

      // ========================================================
      // جلب أرباح اليوم
      // ========================================================

      final newTodayProfit =
          await DatabaseHelper.instance
              .getProfitByPeriod(
        startDate: todayStart,
        endDate: tomorrowStart,
      );

      // ========================================================
      // الأسبوع
      // ========================================================

      final newWeekInvoices =
          await DatabaseHelper.instance
              .getInvoicesByPeriod(
        startDate: weekStart,
        endDate: nextWeekStart,
      );

      final newWeekSales =
          await DatabaseHelper.instance
              .getSalesTotalByPeriod(
        startDate: weekStart,
        endDate: nextWeekStart,
      );

      final newWeekProfit =
          await DatabaseHelper.instance
              .getProfitByPeriod(
        startDate: weekStart,
        endDate: nextWeekStart,
      );

      // ========================================================
      // الشهر
      // ========================================================

      final newMonthInvoices =
          await DatabaseHelper.instance
              .getInvoicesByPeriod(
        startDate: monthStart,
        endDate: nextMonthStart,
      );

      final newMonthSales =
          await DatabaseHelper.instance
              .getSalesTotalByPeriod(
        startDate: monthStart,
        endDate: nextMonthStart,
      );

      final newMonthProfit =
          await DatabaseHelper.instance
              .getProfitByPeriod(
        startDate: monthStart,
        endDate: nextMonthStart,
      );

      if (!mounted) return;

      setState(() {
        todayInvoices = newTodayInvoices;
        todaySales = newTodaySales;
        todayProfit = newTodayProfit;

        weekInvoices = newWeekInvoices;
        weekSales = newWeekSales;
        weekProfit = newWeekProfit;

        monthInvoices = newMonthInvoices;
        monthSales = newMonthSales;
        monthProfit = newMonthProfit;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'REPORT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'حدث خطأ في تحميل التقارير: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // تنسيق السعر
  // ============================================================

  String formatMoney(double value) {
    return '${value.toStringAsFixed(0)} د.ع';
  }

  // ============================================================
  // بطاقة التقرير
  // ============================================================

  Widget reportCard({
    required String title,
    required IconData icon,
    required List<InvoiceModel> invoices,
    required double sales,
    required double profit,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ReportInvoicesScreen(
                title: title,
                invoices: invoices,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        const Color(0xFF011236),
                    child: Icon(
                      icon,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const Divider(),

              const SizedBox(height: 10),

              Row(
                children: [
                  // القوائم
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Colors.blue,
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'القوائم',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${invoices.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // المبيعات
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.point_of_sale,
                          color: Colors.green,
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'المبيعات',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          formatMoney(sales),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // الأرباح
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.orange,
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'الأرباح',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          formatMoney(profit),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة الأرباح
  // ============================================================

  Widget profitCard({
    required String title,
    required double profit,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 5,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.green,
              size: 30,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              formatMoney(profit),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF011236),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'التقارير',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: loadReports,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
            : RefreshIndicator(
                onRefresh: loadReports,

                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.all(18),

                  children: [
                    const Text(
                      'القوائم',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // اليوم
                    reportCard(
                      title: 'قوائم اليوم',
                      icon: Icons.today,
                      invoices:
                          todayInvoices,
                      sales: todaySales,
                      profit:
                          todayProfit,
                    ),

                    // الأسبوع
                    reportCard(
                      title: 'قوائم الأسبوع',
                      icon: Icons.date_range,
                      invoices:
                          weekInvoices,
                      sales: weekSales,
                      profit:
                          weekProfit,
                    ),

                    // الشهر
                    reportCard(
                      title: 'قوائم الشهر',
                      icon: Icons.calendar_month,
                      invoices:
                          monthInvoices,
                      sales: monthSales,
                      profit:
                          monthProfit,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'الأرباح',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        profitCard(
                          title: 'اليوم',
                          profit:
                              todayProfit,
                          icon:
                              Icons.today,
                        ),

                        profitCard(
                          title: 'الأسبوع',
                          profit:
                              weekProfit,
                          icon:
                              Icons.date_range,
                        ),

                        profitCard(
                          title: 'الشهر',
                          profit:
                              monthProfit,
                          icon:
                              Icons.calendar_month,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // إجمالي المبيعات
                    Card(
                      elevation: 3,
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
                            const Text(
                              'إجمالي المبيعات',
                              style:
                                  TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'اليوم',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      formatMoney(
                                        todaySales,
                                      ),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color:
                                            Colors.green,
                                      ),
                                    ),
                                  ],
                                ),

                                Column(
                                  children: [
                                    const Text(
                                      'الأسبوع',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      formatMoney(
                                        weekSales,
                                      ),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color:
                                            Colors.green,
                                      ),
                                    ),
                                  ],
                                ),

                                Column(
                                  children: [
                                    const Text(
                                      'الشهر',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      formatMoney(
                                        monthSales,
                                      ),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        color:
                                            Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}

// ==================================================================
// صفحة فواتير التقرير
// ==================================================================

class ReportInvoicesScreen
    extends StatelessWidget {
  final String title;
  final List<InvoiceModel> invoices;

  const ReportInvoicesScreen({
    super.key,
    required this.title,
    required this.invoices,
  });

  String formatMoney(double value) {
    return '${value.toStringAsFixed(0)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF011236),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,

        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:
                Radius.circular(40),
            topRight:
                Radius.circular(40),
          ),
        ),

        child: invoices.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد قوائم في هذه الفترة',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.all(15),

                itemCount:
                    invoices.length,

                itemBuilder:
                    (context, index) {
                  final invoice =
                      invoices[index];

                  return Card(
                    elevation: 3,

                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),

                    child: ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            Color(0xFF011236),
                        child: Icon(
                          Icons.receipt,
                          color:
                              Colors.white,
                        ),
                      ),

                      title: Text(
                        invoice.customerName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        '${invoice.date}\n'
                        'الدفع: '
                        '${invoice.paymentType}',
                      ),

                      trailing: Text(
                        formatMoney(
                          invoice.total,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceDetailsScreen(
                              invoice:
                                  invoice,
                            ),
                          ),
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