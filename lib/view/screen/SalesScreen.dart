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

  final TextEditingController customerController = TextEditingController(
    text: "نقدي",
  );

  String paymentType = "نقدي";

  final TextEditingController notesController = TextEditingController();

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
  if (cart.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("لا توجد منتجات في السلة"),
      ),
    );
    return;
  }

  final customerController =
      TextEditingController(text: "نقدي");

  final notesController =
      TextEditingController();

  String paymentType = "نقدي";

  final now = DateTime.now();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              "تأكيد البيع",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // اسم الزبون
                  TextField(
                    controller: customerController,
                    decoration: InputDecoration(
                      labelText: "اسم الزبون",
                      prefixIcon:
                          const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // التاريخ
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: "التاريخ",
                      prefixIcon:
                          const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
                      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
                    ),
                  ),

                  const SizedBox(height: 15),

                  // طريقة الدفع
                  DropdownButtonFormField<String>(
                    value: paymentType,
                    decoration: InputDecoration(
                      labelText: "طريقة الدفع",
                      prefixIcon:
                          const Icon(Icons.payment),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
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
                      if (value != null) {
                        setDialogState(() {
                          paymentType = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 15),

                  // الملاحظات
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "ملاحظات",
                      prefixIcon:
                          const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // الإجمالي
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "الإجمالي:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${totalPrice.toStringAsFixed(0)} د.ع",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text("إلغاء"),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF011236),
                ),
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child: const Text(
                  "تأكيد البيع",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  // إذا ألغى المستخدم
  if (confirmed != true) {
    customerController.dispose();
    notesController.dispose();
    return;
  }

  try {

    // =========================
    // إنشاء الفاتورة
    // =========================

    final invoice = InvoiceModel(
      customerName:
          customerController.text.trim().isEmpty
              ? "نقدي"
              : customerController.text.trim(),

      date: now.toString(),

      total: totalPrice,

      paymentType: paymentType,

      notes: notesController.text.trim(),
    );

    // حفظ الفاتورة والحصول على ID
    final invoiceId =
        await DatabaseHelper.instance
            .insertInvoice(invoice);

    // =========================
    // حفظ المنتجات
    // =========================

    for (var item in cart) {

      final sale = SaleModel(
        invoiceId: invoiceId,

        productId: item.product.id!,

        productName: item.product.name,

        barcode: item.product.barcode,

        price: item.product.sellPrice,

        quantity: item.quantity,

        total: item.totalPrice,

        saleDate: now.toString(),
      );

      await DatabaseHelper.instance
          .insertSale(sale);

      // تحديث كمية المخزن
      final remainingQuantity =
          item.product.quantity -
          item.quantity;

      await DatabaseHelper.instance
          .updateProductQuantity(
        item.product.id!,
        remainingQuantity,
      );
    }

    // تنظيف السلة
    cart.clear();

    totalPrice = 0;

    customerController.dispose();
    notesController.dispose();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "تم حفظ الفاتورة وإتمام البيع بنجاح",
        ),
      ),
    );

    // الانتقال إلى القوائم
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MenusScreen(),
      ),
    );

  } catch (e) {

    debugPrint("ERROR: $e");

    customerController.dispose();
    notesController.dispose();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "حدث خطأ: $e",
        ),
      ),
    );
  }
}

  void showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      "سلة المبيعات",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: cart.isEmpty
                          ? const Center(
                              child: Text(
                                "السلة فارغة",
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : ListView.builder(
                              itemCount: cart.length,
                              itemBuilder: (context, index) {
                                final item = cart[index];

                                return Card(
                                  child: ListTile(
                                    title: Text(item.product.name),

                                    subtitle: Text(
                                      "${item.totalPrice.toStringAsFixed(0)} د.ع",
                                    ),

                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            if (item.quantity > 1) {
                                              item.quantity--;
                                            } else {
                                              cart.removeAt(index);
                                            }

                                            calculateTotal();

                                            setState(() {});
                                            setSheetState(() {});
                                          },
                                        ),

                                        Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            if (item.quantity <
                                                item.product.quantity) {
                                              item.quantity++;

                                              calculateTotal();

                                              setState(() {});
                                              setSheetState(() {});
                                            }
                                          },
                                        ),
                                      ],
                                    ),

                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        cart.removeAt(index);

                                        calculateTotal();

                                        setState(() {});
                                        setSheetState(() {});
                                      },
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          "${totalPrice.toStringAsFixed(0)} د.ع",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF011236),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await completeSale();
                        },
                        child: const Text("إتمام البيع",style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold),),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  showCart();
                },
              ),

              if (cart.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cart.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
       

        
          ],
        ),
      ),
    );
  }
}
