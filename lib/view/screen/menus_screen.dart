import 'package:flutter/material.dart';
import 'package:sales_management/view/screen/AddProduct_Screen.dart';

class MenusScreen extends StatelessWidget {
  const MenusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011236),

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

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: const Center(
          child: Text(
            'لا توجد قوائم',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),

      extendBody: true,

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF011236),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 35,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.grid_view,
                      color: Colors.grey, size: 22),
                  SizedBox(height: 4),
                  Text(
                    "القوائم",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined,
                      color: Colors.grey, size: 22),
                  SizedBox(height: 4),
                  Text(
                    "المخزن",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 40),

Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: const [
                  Icon(Icons.bar_chart,
                      color: Colors.grey, size: 22),
                  SizedBox(height: 4),
    const SizedBox(height: 4),
    const Text(
      "تقارير",
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11,
      ),
    ),
  ],
),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long,
                      color: Colors.grey, size: 22),
                  SizedBox(height: 4),
                  Text(
                    "المبيعات",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
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
}