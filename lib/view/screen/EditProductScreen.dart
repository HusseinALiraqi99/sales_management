

import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/product_model.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() =>
      _EditProductScreenState();
}

class _EditProductScreenState
    extends State<EditProductScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController buyPriceController =
      TextEditingController();

  final TextEditingController sellPriceController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.product.name;
    buyPriceController.text =
        widget.product.buyPrice.toString();
    sellPriceController.text =
        widget.product.sellPrice.toString();
    quantityController.text =
        widget.product.quantity.toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    buyPriceController.dispose();
    sellPriceController.dispose();
    quantityController.dispose();

    super.dispose();
  }

  // =========================
  // حفظ التعديل
  // =========================

  Future<void> saveProduct() async {
    final name = nameController.text.trim();

    final buyPrice =
        double.tryParse(
      buyPriceController.text.trim(),
    );

    final sellPrice =
        double.tryParse(
      sellPriceController.text.trim(),
    );

    final quantity =
        int.tryParse(
      quantityController.text.trim(),
    );

    // =========================
    // التحقق من البيانات
    // =========================

    if (name.isEmpty) {
      showMessage("يرجى إدخال اسم المنتج");
      return;
    }

    if (buyPrice == null || buyPrice < 0) {
      showMessage("يرجى إدخال سعر شراء صحيح");
      return;
    }

    if (sellPrice == null || sellPrice < 0) {
      showMessage("يرجى إدخال سعر بيع صحيح");
      return;
    }

    if (quantity == null || quantity < 0) {
      showMessage("يرجى إدخال كمية صحيحة");
      return;
    }

    // =========================
    // منع سعر البيع الأقل
    // من سعر الشراء
    // =========================

    if (sellPrice < buyPrice) {
      showMessage(
        "سعر البيع لا يمكن أن يكون أقل من سعر الشراء",
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final updatedProduct = ProductModel(
        id: widget.product.id,
        name: name,
        barcode: widget.product.barcode,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        quantity: quantity,
        image: widget.product.image,
      );

      await DatabaseHelper.instance
          .updateProduct(updatedProduct);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "تم تعديل المنتج بنجاح",
          ),
        ),
      );

      // إرجاع true إلى صفحة المخزن
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        "ERROR UPDATE PRODUCT: $e",
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(
        "حدث خطأ أثناء تعديل المنتج",
      );
    }
  }

  // =========================
  // رسالة
  // =========================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // =========================
  // حقل إدخال
  // =========================

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
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
        title: const Text(
          "تعديل المنتج",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),

        decoration:
            const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.only(
            topLeft:
                Radius.circular(40),
            topRight:
                Radius.circular(40),
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 10),

              // =====================
              // اسم المنتج
              // =====================

              buildTextField(
                controller:
                    nameController,
                label: "اسم المنتج",
                icon: Icons.inventory_2,
              ),

              const SizedBox(height: 15),

              // =====================
              // الباركود
              // =====================

              TextField(
                enabled: false,
                controller:
                    TextEditingController(
                  text:
                      widget.product.barcode,
                ),
                decoration:
                    InputDecoration(
                  labelText: "الباركود",
                  prefixIcon:
                      const Icon(
                    Icons.qr_code,
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

              const SizedBox(height: 15),

              // =====================
              // سعر الشراء
              // =====================

              buildTextField(
                controller:
                    buyPriceController,
                label: "سعر الشراء",
                icon:
                    Icons.shopping_cart,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 15),

              // =====================
              // سعر البيع
              // =====================

              buildTextField(
                controller:
                    sellPriceController,
                label: "سعر البيع",
                icon:
                    Icons.sell,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 15),

              // =====================
              // الكمية
              // =====================

              buildTextField(
                controller:
                    quantityController,
                label: "الكمية",
                icon:
                    Icons.inventory,
                keyboardType:
                    TextInputType.number,
              ),

              const SizedBox(height: 30),

              // =====================
              // حفظ
              // =====================

              SizedBox(
                width:
                    double.infinity,
                height: 55,

                child:
                    ElevatedButton(
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

                  onPressed:
                      isSaving
                          ? null
                          : saveProduct,

                  child:
                      isSaving
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    3,
                              ),
                            )
                          : const Text(
                              "حفظ التعديل",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 15),

              // =====================
              // إلغاء
              // =====================

              SizedBox(
                width:
                    double.infinity,
                height: 50,

                child:
                    OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),

                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                          );
                        },

                  child:
                      const Text(
                    "إلغاء",
                    style: TextStyle(
                      fontSize: 17,
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

