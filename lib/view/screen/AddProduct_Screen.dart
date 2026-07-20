import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/product_model.dart';
import 'package:sales_management/view/screen/BarcodeScanner_Screen.dart';


class AddProductScreen extends StatefulWidget {
  
  

  final ProductModel? product;

  const AddProductScreen({
    super.key,
    this.product,
  });

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
  void initState() {
    super.initState();

    if (widget.product != null) {
      productNameController.text = widget.product!.name;
      barcodeController.text = widget.product!.barcode;
      buyPriceController.text =
          widget.product!.buyPrice.toString();
      sellPriceController.text =
          widget.product!.sellPrice.toString();
      quantityController.text =
          widget.product!.quantity.toString();
    }
  }

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
        title: Text(
          widget.product == null
              ? "إضافة منتج"
              : "تعديل منتج",
          style: const TextStyle(
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
                  prefixIcon: const Icon(Icons.qr_code),
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
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "سعر الشراء",
                  prefixIcon: const Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: sellPriceController,
                keyboardType: TextInputType.number,
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
                keyboardType: TextInputType.number,
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
                    backgroundColor: const Color(0xFF011236),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {

                    if (productNameController.text.isEmpty ||
                        barcodeController.text.isEmpty ||
                        buyPriceController.text.isEmpty ||
                        sellPriceController.text.isEmpty ||
                        quantityController.text.isEmpty) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("يرجى ملء جميع الحقول"),
                        ),
                      );
                      return;
                    }
                    // ===== منع تكرار الباركود =====
  bool exists = await DatabaseHelper.instance.barcodeExists(
    barcodeController.text.trim(),
    excludeId: widget.product?.id,
  );

  if (exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("هذا الباركود مسجل مسبقاً"),
      ),
    );
    return;
  }

                    final product = ProductModel(
                      id: widget.product?.id,
                      name: productNameController.text.trim(),
                      barcode: barcodeController.text.trim(),
                      buyPrice: double.parse(
                          buyPriceController.text),
                      sellPrice: double.parse(
                          sellPriceController.text),
                      quantity:
                          int.parse(quantityController.text),
                      image: "",
                    );

                    if (widget.product == null) {

                      await DatabaseHelper.instance
                          .insertProduct(product);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text("تم حفظ المنتج بنجاح"),
                          backgroundColor: Colors.green,
                        ),
                      );

                    } else {

                      await DatabaseHelper.instance
                          .updateProduct(product);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text("تم تعديل المنتج بنجاح"),
                          backgroundColor: Colors.green,
                        ),
                      );

                    }

                    Navigator.pop(context, true);
                  },
                  child: Text(
                    widget.product == null
                        ? "حفظ المنتج"
                        : "تعديل المنتج",
                    style: const TextStyle(
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
