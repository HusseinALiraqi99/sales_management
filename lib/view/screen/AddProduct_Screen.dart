import 'package:flutter/material.dart';
import 'package:sales_management/view/screen/BarcodeScanner_Screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController productNameController =
      TextEditingController();

  final TextEditingController buyPriceController =
      TextEditingController();

  final TextEditingController sellPriceController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController();

  final TextEditingController barcodeController =
      TextEditingController();

  @override
  void dispose() {
    productNameController.dispose();
    buyPriceController.dispose();
    sellPriceController.dispose();
    quantityController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011236),
      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "إضافة منتج",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [

              GestureDetector(
                onTap: () async {

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const BarcodeScannerScreen(),
                    ),
                  );

                  if (result != null) {
                    barcodeController.text = result;
                  }
                },
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF011236),
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 60,
                        color: Color(0xFF011236),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "مسح الباركود",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF011236),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

            

              

              TextField(
                controller: barcodeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "الباركود",
                  prefixIcon:
                      const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),
                TextField(
                controller: productNameController,
                decoration: InputDecoration(
                  labelText: "اسم المنتج",
                  prefixIcon:
                      const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: buyPriceController,
                keyboardType:
                    TextInputType.number,
                decoration: InputDecoration(
                  labelText: "سعر الشراء",
                  prefixIcon:
                      const Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: sellPriceController,
                keyboardType:
                    TextInputType.number,
                decoration: InputDecoration(
                  labelText: "سعر البيع",
                  prefixIcon:
                      const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: quantityController,
                keyboardType:
                    TextInputType.number,
                decoration: InputDecoration(
                  labelText: "الكمية",
                  prefixIcon:
                      const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF011236),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "حفظ المنتج",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}