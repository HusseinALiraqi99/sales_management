import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, "sales_management.db");

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {

    await db.execute('''
CREATE TABLE products(
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT NOT NULL,
barcode TEXT NOT NULL,
buyPrice REAL NOT NULL,
sellPrice REAL NOT NULL,
quantity INTEGER NOT NULL,
image TEXT
)
''');

    await db.execute('''
CREATE TABLE invoices(
id INTEGER PRIMARY KEY AUTOINCREMENT,
customerName TEXT NOT NULL,
date TEXT NOT NULL,
total REAL NOT NULL,
paymentType TEXT,
notes TEXT
)
''');

    await db.execute('''
CREATE TABLE sales(
id INTEGER PRIMARY KEY AUTOINCREMENT,
invoiceId INTEGER,
productId INTEGER,
productName TEXT,
barcode TEXT,
price REAL,
quantity INTEGER,
total REAL,
saleDate TEXT
)
''');
  }

  /// إضافة منتج
  Future<int> insertProduct(ProductModel product) async {
    final db = await database;

    return await db.insert(
      'products',
      product.toMap(),
    );
  }

  /// جلب جميع المنتجات
  Future<List<ProductModel>> getProducts() async {
    final db = await database;

    final maps = await db.query('products');

    return List.generate(
      maps.length,
      (index) => ProductModel.fromMap(maps[index]),
    );
  }

  /// تعديل منتج
  Future<int> updateProduct(ProductModel product) async {
    final db = await database;

    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }  /// حذف منتج
  Future<int> deleteProduct(int id) async {
    final db = await database;

    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// البحث بالاسم أو الباركود
  Future<List<ProductModel>> searchProducts(String keyword) async {
    final db = await database;

    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
    );

    return List.generate(
      maps.length,
      (index) => ProductModel.fromMap(maps[index]),
    );
  }

  /// حذف جميع المنتجات
  Future<void> deleteAllProducts() async {
    final db = await database;
    await db.delete('products');
  }

  /// التحقق من وجود الباركود
  Future<bool> barcodeExists(String barcode, {int? excludeId}) async {
    final db = await database;

    List<Map<String, dynamic>> result;

    if (excludeId == null) {
      result = await db.query(
        'products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    } else {
      result = await db.query(
        'products',
        where: 'barcode = ? AND id != ?',
        whereArgs: [barcode, excludeId],
      );
    }

    return result.isNotEmpty;
  }

  /// تحديث كمية المنتج
  Future<int> updateProductQuantity(
    int productId,
    int newQuantity,
  ) async {
    final db = await database;

    return await db.update(
      'products',
      {
        'quantity': newQuantity,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  /// جلب منتج بالباركود
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final db = await database;

    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (result.isEmpty) return null;

    return ProductModel.fromMap(result.first);
  }

  /// جلب منتج بالمعرف
  Future<ProductModel?> getProductById(int id) async {
    final db = await database;

    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    return ProductModel.fromMap(result.first);
  }  /// حفظ عملية بيع
  Future<int> insertSale(SaleModel sale) async {
    final db = await database;

    return await db.insert(
      'sales',
      sale.toMap(),
    );
  }

  /// جلب جميع عمليات البيع
  Future<List<SaleModel>> getSales() async {
    final db = await database;

    final maps = await db.query(
      'sales',
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => SaleModel.fromMap(maps[index]),
    );
  }
  

  /// جلب عمليات البيع الخاصة بفاتورة معينة
  Future<List<SaleModel>> getSalesByInvoice(int invoiceId) async {
    final db = await database;

    final maps = await db.query(
      'sales',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );

    return List.generate(
      maps.length,
      (index) => SaleModel.fromMap(maps[index]),
    );
  }
  

  /// حذف جميع المبيعات
  Future<void> deleteAllSales() async {
    final db = await database;
    await db.delete('sales');
  }

  /// حفظ فاتورة
  Future<int> insertInvoice(InvoiceModel invoice) async {
    final db = await database;

    return await db.insert(
      'invoices',
      invoice.toMap(),
    );
  }

  /// جلب جميع الفواتير
  Future<List<InvoiceModel>> getInvoices() async {
    final db = await database;

    final maps = await db.query(
      'invoices',
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => InvoiceModel.fromMap(maps[index]),
    );
  }

  /// حذف فاتورة
  Future<int> deleteInvoice(int id) async {
    final db = await database;

    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}