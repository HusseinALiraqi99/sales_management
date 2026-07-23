import 'package:path/path.dart';
import 'package:sales_management/models/invoice_model.dart';
import 'package:sqflite/sqflite.dart';

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
  version: 2,
  onCreate: _onCreate,
  onUpgrade: (db, oldVersion, newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        productName TEXT,
        barcode TEXT,
        price REAL,
        quantity INTEGER,
        total REAL,
        saleDate TEXT
      )
    ''');
  },
);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE sales(
id INTEGER PRIMARY KEY AUTOINCREMENT,
productId INTEGER,
productName TEXT,
barcode TEXT,
price REAL,
quantity INTEGER,
total REAL,
saleDate TEXT
)
''');
await db.execute('''
CREATE TABLE invoices(
id INTEGER PRIMARY KEY AUTOINCREMENT,
date TEXT NOT NULL,
total REAL NOT NULL
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

    final List<Map<String, dynamic>> maps =
        await db.query('products');

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
  }

  /// حذف منتج
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

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
    );

    return List.generate(
      maps.length,
      (index) => ProductModel.fromMap(maps[index]),
    );
  }

  /// حذف جميع المنتجات (للاختبار)
  Future<void> deleteAllProducts() async {
    final db = await database;

    await db.delete('products');
  }

  /// إغلاق قاعدة البيانات
  Future close() async {
    final db = await database;
    db.close();
  }
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
Future<ProductModel?> getProductByBarcode(String barcode) async {
  final db = await database;

  final result = await db.query(
    'products',
    where: 'barcode = ?',
    whereArgs: [barcode],
  );

  if (result.isEmpty) {
    return null;
  }

  return ProductModel.fromMap(result.first);
}
Future<ProductModel?> getProductById(int id) async {
  final db = await database;

  final result = await db.query(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (result.isEmpty) {
    return null;
  }

  return ProductModel.fromMap(result.first);
}
Future<int> insertSale(SaleModel sale) async {
  final db = await database;

  return await db.insert(
    'sales',
    sale.toMap(),
  );
}
Future<List<SaleModel>> getSales() async {
  final db = await database;

  final List<Map<String, dynamic>> maps =
      await db.query(
    'sales',
    orderBy: 'id DESC',
  );

  return List.generate(
    maps.length,
    (index) => SaleModel.fromMap(maps[index]),
  );
}
Future<void> deleteAllSales() async {
  final db = await database;

  await db.delete('sales');
}
Future<int> insertInvoice(InvoiceModel invoice) async {
  final db = await database;

  return await db.insert(
    'invoices',
    invoice.toMap(),
  );
}
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

}