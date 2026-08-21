import 'package:flutter/material.dart';
import 'package:sales_management/database/database_helper.dart';
import 'package:sales_management/models/cart_item_model.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sales_management/models/product_model.dart';
import 'package:sales_management/models/sale_model.dart';

class EditInvoiceScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const EditInvoiceScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<EditInvoiceScreen> createState() =>
      _EditInvoiceScreenState();
}

class _EditInvoiceScreenState
    extends State<EditInvoiceScreen> {

  List<ProductModel> products = [];
  List<ProductModel> filteredProducts = [];
  List<CartItemModel> cart = [];

  final TextEditingController searchController =
      TextEditingController();

  final TextEditingController customerController =
      TextEditingController();

  bool isLoading = true;

  double totalPrice = 0;

  String paymentType = "نقدي";

  @override
  void initState() {
    super.initState();

    customerController.text =
        widget.invoice.customerName;

    paymentType =
        widget.invoice.paymentType;

    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    customerController.dispose();
    super.dispose();
  }

  // =========================
  // تحميل البيانات
  // =========================

  Future<void> loadData() async {
    try {
      final allProducts =
          await DatabaseHelper.instance.getProducts();

      final sales =
          await DatabaseHelper.instance.getSalesByInvoice(
        widget.invoice.id!,
      );

      List<CartItemModel> loadedCart = [];

      for (var sale in sales) {
        final product =
            await DatabaseHelper.instance.getProductById(
          sale.productId,
        );

        if (product != null) {
          loadedCart.add(
            CartItemModel(
              product: product,
              quantity: sale.quantity,
            ),
          );
        }
      }

      products = allProducts;
      filteredProducts = allProducts;
      cart = loadedCart;

      calculateTotal();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD EDIT INVOICE: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "حدث خطأ أثناء تحميل القائمة: $e",
          ),
        ),
      );
    }
  }

  // =========================
  // البحث
  // =========================

  void searchProduct(String value) {
    setState(() {
      filteredProducts = products.where((product) {
        return product.name
                .toLowerCase()
                .contains(value.toLowerCase()) ||
            product.barcode.contains(value);
      }).toList();
    });
  }

  // =========================
  // حساب المجموع
  // =========================

  void calculateTotal() {
    totalPrice = 0;

    for (var item in cart) {
      totalPrice += item.totalPrice;
    }
  }

  // =========================
  // إضافة منتج للسلة
  // =========================

  void addToCart(ProductModel product) {
    final index = cart.indexWhere(
      (e) => e.product.id == product.id,
    );

    if (index == -1) {
      if (product.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("المنتج غير متوفر"),
          ),
        );
        return;
      }

      cart.add(
        CartItemModel(
          product: product,
          quantity: 1,
        ),
      );
    } else {
      /*
       * في صفحة التعديل يجب الانتباه إلى أن
       * الكمية القديمة مباعة أصلًا.
       *
       * لذلك نسمح بزيادة الكمية،
       * وسيتم حساب الفرق عند الحفظ.
       */

      cart[index].quantity++;
    }

    calculateTotal();

    setState(() {});
  }

  // =========================
  // تنقيص
  // =========================

  void decreaseQuantity(int index) {
    setState(() {
      if (cart[index].quantity > 1) {
        cart[index].quantity--;
      } else {
        cart.removeAt(index);
      }

      calculateTotal();
    });
  }

  // =========================
  // زيادة
  // =========================

  void increaseQuantity(int index) {
    setState(() {
      cart[index].quantity++;
      calculateTotal();
    });
  }

  // =========================
  // حذف
  // =========================

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
      calculateTotal();
    });
  }

  // =========================
  // حفظ التعديل
  // =========================
Future<void> saveEdit() async {
  if (cart.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("لا يمكن حفظ قائمة بدون منتجات"),
      ),
    );
    return;
  }

  try {
    calculateTotal();

    final customerName =
        customerController.text.trim().isEmpty
            ? "نقدي"
            : customerController.text.trim();

await DatabaseHelper.instance.updateInvoiceWithCart(
  InvoiceModel(
    id: widget.invoice.id,
    customerName:
        customerController.text.trim().isEmpty
            ? "نقدي"
            : customerController.text.trim(),
    date: widget.invoice.date,
    total: totalPrice,
    paymentType: paymentType,
    notes: widget.invoice.notes,
  ),
  cart,
);

    // التأكد من تحديث بيانات الفاتورة بالإجمالي الجديد
    await DatabaseHelper.instance.updateInvoiceData(
      invoiceId: widget.invoice.id!,
      customerName: customerName,
      date: widget.invoice.date,
      total: totalPrice,
      paymentType: paymentType,
      notes: widget.invoice.notes,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text("تم تعديل القائمة بنجاح"),
      ),
    );

    // إرجاع true حتى تقوم صفحة القوائم بإعادة تحميل البيانات
    Navigator.pop(context, true);
  } catch (e) {
    debugPrint("ERROR UPDATE INVOICE: $e");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text("حدث خطأ أثناء تعديل القائمة: $e"),
      ),
    );
  }
}

  // =========================
  // الواجهة
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011236),

      appBar: AppBar(
        backgroundColor: const Color(0xFF011236),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "تعديل القائمة",
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

        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [

                  // =====================
                  // اسم الزبون
                  // =====================

                  TextField(
                    controller: customerController,
                    decoration: InputDecoration(
                      labelText: "اسم الزبون",
                      prefixIcon:
                          const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // =====================
                  // طريقة الدفع
                  // =====================

                  DropdownButtonFormField<String>(
                    value: paymentType,
                    decoration: InputDecoration(
                      labelText: "طريقة الدفع",
                      prefixIcon:
                          const Icon(Icons.payment),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
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
                      if (value == null) return;

                      setState(() {
                        paymentType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 15),

                  // =====================
                  // البحث
                  // =====================

                  TextField(
                    controller: searchController,
                    onChanged: searchProduct,
                    decoration: InputDecoration(
                      hintText:
                          "بحث بالاسم أو الباركود",
                      prefixIcon:
                          const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // =====================
                  // المنتجات
                  // =====================

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "المنتجات",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      itemCount:
                          filteredProducts.length,
                      itemBuilder:
                          (context, index) {

                        final product =
                            filteredProducts[index];

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 8,
                          ),

                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              backgroundColor:
                                  Color(0xFF011236),
                              child: Icon(
                                Icons.inventory,
                                color: Colors.white,
                              ),
                            ),

                            title: Text(
                              product.name,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              "السعر: ${product.sellPrice} د.ع\n"
                              "المتوفر: ${product.quantity}",
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

                  const Divider(),

                  // =====================
                  // السلة
                  // =====================

                  const Align(
                    alignment:
                        Alignment.centerRight,
                    child: Text(
                      "محتويات القائمة",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: cart.isEmpty
                        ? const Center(
                            child: Text(
                              "لا توجد منتجات",
                            ),
                          )
                        : ListView.builder(
                            itemCount: cart.length,
                            itemBuilder:
                                (context, index) {

                              final item =
                                  cart[index];

                              return Card(
                                margin:
                                    const EdgeInsets
                                        .only(
                                  bottom: 8,
                                ),

                                child: ListTile(
                                  leading:
                                      const Icon(
                                    Icons
                                        .shopping_cart,
                                    color:
                                        Color(
                                            0xFF011236),
                                  ),

                                  title: Text(
                                    item.product.name,
                                  ),

                                  subtitle: Text(
                                    "السعر: "
                                    "${item.product.sellPrice} د.ع",
                                  ),

                                  trailing: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [

                                      IconButton(
                                        icon:
                                            const Icon(
                                          Icons
                                              .remove_circle,
                                          color:
                                              Colors.red,
                                        ),
                                        onPressed: () {
                                          decreaseQuantity(
                                            index,
                                          );
                                        },
                                      ),

                                      Text(
                                        "${item.quantity}",
                                        style:
                                            const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      IconButton(
                                        icon:
                                            const Icon(
                                          Icons
                                              .add_circle,
                                          color:
                                              Colors.green,
                                        ),
                                        onPressed: () {
                                          increaseQuantity(
                                            index,
                                          );
                                        },
                                      ),

                                      IconButton(
                                        icon:
                                            const Icon(
                                          Icons.delete,
                                          color:
                                              Colors.red,
                                        ),
                                        onPressed: () {
                                          removeFromCart(
                                            index,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(),

                  // =====================
                  // الإجمالي
                  // =====================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [

                      const Text(
                        "الإجمالي",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        "${totalPrice.toStringAsFixed(0)} د.ع",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // =====================
                  // حفظ التعديل
                  // =====================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                                0xFF011236),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  15),
                        ),
                      ),
                      onPressed: saveEdit,
                      child: const Text(
                        "حفظ التعديل",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}