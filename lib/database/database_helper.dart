import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_model.dart';

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
      version: 1,
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
}