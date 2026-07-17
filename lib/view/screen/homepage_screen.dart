import 'package:flutter/material.dart';
import 'package:sales_management/view/screen/menus_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MenusScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('images/logo.png')),
            SizedBox(height: 20),
            Text(
              'Sales Management!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('ادارة المبيعات', style: TextStyle(fontSize: 20)),
           
          ],
        ),
      ),
    );
  }
}