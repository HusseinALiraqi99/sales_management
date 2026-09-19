import 'package:flutter/material.dart';
import 'package:sales_management/services/license_service.dart';
import 'package:sales_management/view/screen/menus_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() =>
      _ActivationScreenState();
}

class _ActivationScreenState
    extends State<ActivationScreen> {
  final TextEditingController codeController =
      TextEditingController();

  bool isLoading = false;

  String? errorMessage;

  Future<void> activateProgram() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        errorMessage = 'يرجى إدخال رمز التفعيل';
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final success =
        await LicenseService.activate(code);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MenusScreen(),
        ),
        (route) => false,
      );

      return;
    }

    setState(() {
      isLoading = false;
      errorMessage = 'رمز التفعيل غير صحيح';
    });
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011236),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(30),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 70,
                    color: Color(0xFF011236),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'تفعيل البرنامج',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF011236),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'انتهت فترة التجربة المجانية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 25),

                  TextField(
                    controller: codeController,

                    textDirection:
                        TextDirection.ltr,

                    textAlign: TextAlign.center,

                    decoration:
                        InputDecoration(
                      labelText: 'رمز التفعيل',

                      hintText:
                          'أدخل رمز التفعيل',

                      prefixIcon:
                          const Icon(
                        Icons.key,
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : activateProgram,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF011236,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'تفعيل البرنامج',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}