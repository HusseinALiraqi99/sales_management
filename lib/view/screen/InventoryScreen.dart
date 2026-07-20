import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController searchController = TextEditingController();

  List<ProductModel> products = [];
  List<ProductModel> allProducts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    allProducts = await DatabaseHelper.instance.getProducts();

    setState(() {
      products = allProducts;
      isLoading = false;
    });
  }

  void searchProduct(String value) {
    if (value.isEmpty) {
      setState(() {
        products = allProducts;
      });
      return;
    }

    setState(() {
      products = allProducts.where((product) {
        return product.name
                .toLowerCase()
                .contains(value.toLowerCase()) ||
            product.barcode.contains(value);
      }).toList();
    });
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
          "المخزن",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: searchController,
                onChanged: searchProduct,
                decoration: InputDecoration(
                  hintText: "ابحث باسم المنتج أو الباركود",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : products.isEmpty
                      ? const Center(
                          child: Text(
                            "لا توجد منتجات",
                            style: TextStyle(fontSize: 20),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            ProductModel product = products[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      "الباركود : ${product.barcode}",
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      "سعر الشراء : ${product.buyPrice}",
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      "سعر البيع : ${product.sellPrice}",
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      "الكمية : ${product.quantity}",
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [

                                        IconButton(
                                          onPressed: () {
                                            // سنضيف التعديل لاحقاً
                                          },
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                        ),

                                        IconButton(
                                          onPressed: () async {

                                            await DatabaseHelper.instance
                                                .deleteProduct(product.id!);

                                            loadProducts();

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "تم حذف المنتج"),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}