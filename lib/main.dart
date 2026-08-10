import 'package:flutter/material.dart';
import 'package:sales_management/view/screen/menus_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // اللغة العربية
      locale: const Locale('ar'),

      // اتجاه التطبيق من اليمين إلى اليسار
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      home: const MenusScreen(),
    );
  }
}