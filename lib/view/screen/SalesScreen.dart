import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/cart_item_model.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/models/product_model.dart';
import 'package:sales_management/models/sale_model.dart';
import 'package:sales_management/view/screen/menus_screen.dart';

class SalesScreen extends StatefulWidget {
  final ProductModel? scannedProduct;

  const SalesScreen({super.key, this.scannedProduct});
  

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<ProductModel> products = [];
  List<ProductModel> filteredProducts = [];
  List<CartItemModel> cart = [];

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;

  double totalPrice = 0;

  final TextEditingController customerController =
    TextEditingController(text: "نقدي");

String paymentType = "نقدي";

final TextEditingController notesController =
    TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts().then((_) {
      if (widget.scannedProduct != null) {
        addToCart(widget.scannedProduct!);
      }
    });
  }

  Future<void> loadProducts() async {
    products = await DatabaseHelper.instance.getProducts();

    filteredProducts = products;

    setState(() {
      isLoading = false;
    });
  }

  void searchProduct(String value) {
    setState(() {
      filteredProducts = products.where((product) {
        return product.name.toLowerCase().contains(value.toLowerCase()) ||
            product.barcode.contains(value);
      }).toList();
    });
  }

  void calculateTotal() {
    totalPrice = 0;

    for (var item in cart) {
      totalPrice += item.totalPrice;
    }
  }

  void addToCart(ProductModel product) {
    final index = cart.indexWhere((e) => e.product.id == product.id);

    if (index == -1) {
      if (product.quantity <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("المنتج غير متوفر")));
        return;
      }

      cart.add(CartItemModel(product: product, quantity: 1));
    } else {
      if (cart[index].quantity < product.quantity) {
        cart[index].quantity++;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("الكمية غير كافية")));
        return;
      }
    }

    calculateTotal();

    setState(() {});
  }

  void removeFromCart(int index) {
    cart.removeAt(index);

    calculateTotal();

    setState(() {});
  }

  Future<void> completeSale() async {
    try {
      if (cart.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا توجد منتجات في الفاتورة")),
        );
        return;
      }
      final invoice = InvoiceModel(
  customerName: customerController.text.trim().isEmpty
      ? "نقدي"
      : customerController.text.trim(),
  date: DateTime.now().toString(),
  total: totalPrice,
  paymentType: paymentType,
  notes: notesController.text.trim(),
);

final invoiceId =
    await DatabaseHelper.instance.insertInvoice(invoice);

      for (var item in cart) {
       final sale = SaleModel(
  invoiceId: invoiceId,
  productId: item.product.id!,
  productName: item.product.name,
  barcode: item.product.barcode,
  price: item.product.sellPrice,
  quantity: item.quantity,
  total: item.totalPrice,
  saleDate: DateTime.now().toString(),
);

        await DatabaseHelper.instance.insertSale(sale);

        await DatabaseHelper.instance.updateProductQuantity(
          item.product.id!,
          item.product.quantity - item.quantity,
        );
      }

      cart.clear();
      totalPrice = 0;
      customerController.text = "نقدي";
notesController.clear();
paymentType = "نقدي";

      await loadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("تمت عملية البيع بنجاح"),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenusScreen()),
      );
    } catch (e) {
      debugPrint("ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("حدث خطأ: $e")),
      );
    }
  }
  Future<void> showInvoiceDialog() async {
 if (customerController.text.isEmpty) {
  customerController.text = "نقدي";
}

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text("بيانات الفاتورة"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  TextField(
                    controller: customerController,
                    decoration: const InputDecoration(
                      labelText: "اسم الزبون",
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: paymentType,
                    decoration: const InputDecoration(
                      labelText: "طريقة الدفع",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "نقدي",
                        child: Text("نقدي"),
                      ),
                      DropdownMenuItem(
                        value: "آجل",
                        child: Text("آجل"),
                      ),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        paymentType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: "ملاحظات",
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("إلغاء"),
          ),

          ElevatedButton(
            onPressed: () async {

              Navigator.pop(context);

              await completeSale();

            },
            child: const Text("حفظ"),
          ),
        ],
      );
    },
  );
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
          "المبيعات",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: searchProduct,
              decoration: InputDecoration(
                hintText: "بحث بالاسم أو الباركود",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "المنتجات",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              flex: 2,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              radius: 25,
                              backgroundColor: Color(0xFF011236),
                              child: Icon(Icons.inventory, color: Colors.white),
                            ),

                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("الباركود : ${product.barcode}"),

                                Text("السعر : ${product.sellPrice}"),

                                Text("المتوفر : ${product.quantity}"),
                              ],
                            ),

                            trailing: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 34,
                              ),
                              onPressed: () {
                                addToCart(product);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 15),

            const Divider(),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "سلة المبيعات",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Text(
                        "لا توجد منتجات في السلة",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.shopping_cart,
                              color: Color(0xFF011236),
                            ),

                            title: Text(item.product.name),

                            subtitle: Text("الكمية : ${item.quantity}"),

                            trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [

    IconButton(
      icon: const Icon(
        Icons.remove_circle,
        color: Colors.red,
      ),
      onPressed: () {
        setState(() {
          if (cart[index].quantity > 1) {
            cart[index].quantity--;
          } else {
            cart.removeAt(index);
          }
          calculateTotal();
        });
      },
    ),

    Text(
      "${cart[index].quantity}",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),

    IconButton(
      icon: const Icon(
        Icons.add_circle,
        color: Colors.green,
      ),
      onPressed: () {
        if (cart[index].quantity <
            cart[index].product.quantity) {
          setState(() {
            cart[index].quantity++;
            calculateTotal();
          });
        }
      },
    ),

    const SizedBox(width: 10),

    Text(
      "${item.totalPrice.toStringAsFixed(0)}",
      style: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "الإجمالي",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                Text(
                  "${totalPrice.toStringAsFixed(0)} د.ع",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

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
                  await showInvoiceDialog();

                },
                child: const Text(
                  "إتمام البيع",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
