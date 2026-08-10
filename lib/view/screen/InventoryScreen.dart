import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/product_model.dart';
import 'package:sales_management/view/screen/EditProductScreen.dart';

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================
  // تحميل المنتجات
  // =========================

  Future<void> loadProducts() async {
    try {
      final data = await DatabaseHelper.instance.getProducts();

      if (!mounted) return;

      setState(() {
        allProducts = data;
        products = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD PRODUCTS: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // البحث
  // =========================

  void searchProduct(String value) {
    final search = value.trim().toLowerCase();

    // إذا لم يكتب شيئًا
    if (search.isEmpty) {
      setState(() {
        products = allProducts;
      });
      return;
    }

    // البحث عن المنتجات الناقصة
    if (search == "ناقص" || search == "ناقصه" || search == "ناقصه") {
      setState(() {
        products = allProducts
            .where((product) => product.quantity < 5)
            .toList();
      });
      return;
    }

    // البحث باسم المنتج أو الباركود
    setState(() {
      products = allProducts.where((product) {
        return product.name.toLowerCase().contains(search) ||
            product.barcode.toLowerCase().contains(search);
      }).toList();
    });
  }

  // =========================
  // لون البطاقة حسب الكمية
  // =========================

  Color getCardColor(ProductModel product) {
    if (product.quantity == 0) {
      return Colors.red.shade50;
    }

    if (product.quantity < 5) {
      return Colors.orange.shade50;
    }

    return Colors.white;
  }

  // =========================
  // لون الكمية
  // =========================

  Color getQuantityColor(ProductModel product) {
    if (product.quantity == 0) {
      return Colors.red;
    }

    if (product.quantity < 5) {
      return Colors.orange.shade800;
    }

    return Colors.black;
  }

  // =========================
  // نص حالة المخزون
  // =========================

  String getStockStatus(ProductModel product) {
    if (product.quantity == 0) {
      return "نفد المخزون";
    }

    if (product.quantity < 5) {
      return "مخزون ناقص";
    }

    return "متوفر";
  }

  // =========================
  // لون حالة المخزون
  // =========================

  Color getStockStatusColor(ProductModel product) {
    if (product.quantity == 0) {
      return Colors.red;
    }

    if (product.quantity < 5) {
      return Colors.orange.shade800;
    }

    return Colors.green;
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
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),

        child: Column(
          children: [
            // =========================
            // البحث
            // =========================
            Padding(
              padding: const EdgeInsets.all(15),

              child: TextField(
                controller: searchController,
                onChanged: searchProduct,

                decoration: InputDecoration(
                  hintText: "ابحث باسم المنتج أو الباركود أو اكتب ناقص",

                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();

                            setState(() {
                              products = allProducts;
                            });
                          },
                        )
                      : null,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            // =========================
            // حالة البحث
            // =========================
            if (searchController.text.trim() == "ناقص")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),

                child: Align(
                  alignment: Alignment.centerRight,

                  child: Text(
                    "المنتجات الناقصة: ${products.length}",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 5),

            // =========================
            // المنتجات
            // =========================
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                  ? const Center(
                      child: Text(
                        "لا توجد منتجات",
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),

                      itemCount: products.length,

                      itemBuilder: (context, index) {
                        final product = products[index];

                        final isOutOfStock = product.quantity == 0;

                        final isLowStock = product.quantity < 5;

                        return Card(
                          color: getCardColor(product),

                          margin: const EdgeInsets.only(bottom: 15),

                          elevation: 3,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(15),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                // =====================
                                // اسم المنتج + الحالة
                                // =====================
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,

                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    if (isOutOfStock || isLowStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),

                                        decoration: BoxDecoration(
                                          color: getStockStatusColor(product),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),

                                        child: Text(
                                          getStockStatus(product),

                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // =====================
                                // الباركود
                                // =====================
                                Text(
                                  "الباركود : ${product.barcode}",

                                  style: const TextStyle(fontSize: 16),
                                ),

                                const SizedBox(height: 5),

                                // =====================
                                // سعر الشراء
                                // =====================
                                Text(
                                  "سعر الشراء : ${product.buyPrice}",

                                  style: const TextStyle(fontSize: 16),
                                ),

                                const SizedBox(height: 5),

                                // =====================
                                // سعر البيع
                                // =====================
                                Text(
                                  "سعر البيع : ${product.sellPrice}",

                                  style: const TextStyle(fontSize: 16),
                                ),

                                const SizedBox(height: 5),

                                // =====================
                                // الكمية
                                // =====================
                                Text(
                                  "الكمية : ${product.quantity}",

                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: getQuantityColor(product),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // =====================
                                // شريط تنبيه المخزون
                                // =====================
                                if (isOutOfStock)
                                  Container(
                                    width: double.infinity,

                                    padding: const EdgeInsets.all(10),

                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),

                                    child: const Text(
                                      "⚠ هذا المنتج نفد من المخزون",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (isLowStock)
                                  Container(
                                    width: double.infinity,

                                    padding: const EdgeInsets.all(10),

                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,

                                      borderRadius: BorderRadius.circular(10),
                                    ),

                                    child: Text(
                                      "⚠ تنبيه: الكمية منخفضة (${product.quantity})",

                                      style: TextStyle(
                                        color: Colors.orange.shade900,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                // =====================
                                // الأزرار
                                // =====================
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,

                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditProductScreen(
                                              product: product,
                                            ),
                                          ),
                                        );

                                        if (result == true) {
                                          await loadProducts();
                                        }
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

                                        await loadProducts();

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("تم حذف المنتج"),
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
