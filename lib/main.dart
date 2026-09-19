import 'package:flutter/material.dart';

import 'package:sales_management/services/license_service.dart';

import 'package:sales_management/view/screen/activation_screen.dart';

import 'package:sales_management/view/screen/menus_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LicenseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      locale: const Locale('ar'),

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      home: const LicenseGate(),
    );
  }
}

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});

  @override
  State<LicenseGate> createState() =>
      _LicenseGateState();
}

class _LicenseGateState
    extends State<LicenseGate> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LicenseService.canUseProgram(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                Color(0xFF011236),

            body: Center(
              child:
                  CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MenusScreen();
        }

        return const ActivationScreen();
      },
    );
  }
}