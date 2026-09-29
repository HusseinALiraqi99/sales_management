import 'package:flutter/material.dart';

import 'package:sales_management/services/license_service.dart';

import 'package:sales_management/view/screen/activation_screen.dart';

import 'package:sales_management/view/screen/homepage_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String message = 'جاري تشغيل البرنامج...';

  @override
  void initState() {
    super.initState();

    checkLicense();
  }

  Future<void> checkLicense() async {
    // =========================
    // فحص التفعيل
    // =========================

    final activated =
        await LicenseService.isActivated();

    if (!mounted) return;

    if (activated) {
      setState(() {
        message = 'البرنامج مفعل';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomepageScreen(),
        ),
      );

      return;
    }

    // =========================
    // فحص الفترة التجريبية
    // =========================

    final trialActive =
        await LicenseService.isTrialActive();

    if (!mounted) return;

    if (!trialActive) {
      setState(() {
        message = 'انتهت الفترة التجريبية';
      });

      await Future.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ActivationScreen(),
        ),
      );

      return;
    }

    // =========================
    // الأيام المتبقية
    // =========================

    final daysRemaining =
        await LicenseService
            .getTrialDaysRemaining();

    if (!mounted) return;

    if (daysRemaining == 1) {
      setState(() {
        message =
            'الفترة التجريبية متبقي لها يوم واحد';
      });
    } else {
      setState(() {
        message =
            'الفترة التجريبية متبقي لها $daysRemaining يوم';
      });
    }

    // =========================
    // انتظار ثم الدخول للبرنامج
    // =========================

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HomepageScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF011236),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const CircularProgressIndicator(
              color: Colors.white,
            ),

            const SizedBox(height: 25),

            Text(
              message,
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}