import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState
    extends State<BarcodeScannerScreen> {

  final MobileScannerController controller =
      MobileScannerController();

  bool scanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "مسح الباركود",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [

          MobileScanner(
            controller: controller,

            onDetect: (capture) {

              if (scanned) return;

              final Barcode barcode =
                  capture.barcodes.first;

              final String? code =
                  barcode.rawValue;

              if (code != null && code.isNotEmpty) {

                scanned = true;

                Navigator.pop(context, code);

              }
            },
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
          ),

          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "وجّه الكاميرا نحو الباركود",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}