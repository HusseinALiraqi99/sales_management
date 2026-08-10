import 'package:path/path.dart';
import 'package:sales_management/models/cart_item_model.dart';
import 'package:sqflite/sqflite.dart';

import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  // ============================================================
  // Database
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'sales_management.db',
    );

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // إنشاء قاعدة البيانات
  // ============================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
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

  // ============================================================
  // تحديث قاعدة البيانات
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // إضافة invoiceId إلى sales إذا كانت قاعدة البيانات قديمة
    if (oldVersion < 3) {
      final columns = await db.rawQuery(
        'PRAGMA table_info(sales)',
      );

      final hasInvoiceId = columns.any(
        (column) => column['name'] == 'invoiceId',
      );

      if (!hasInvoiceId) {
        await db.execute(
          'ALTER TABLE sales ADD COLUMN invoiceId INTEGER',
        );
      }
    }

    // الإصدار 4 لا يحتاج تغييرًا في الجداول.
    // رفعنا الإصدار حتى تتم إعادة فتح قاعدة البيانات
    // بشكل صحيح مع النسخ السابقة.
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Future<int> insertProduct(
    ProductModel product,
  ) async {
    final db = await database;

    return await db.insert(
      'products',
      product.toMap(),
    );
  }

  Future<List<ProductModel>> getProducts() async {
    final db = await database;

    final maps = await db.query(
      'products',
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => ProductModel.fromMap(
        maps[index],
      ),
    );
  }

  Future<int> updateProduct(
    ProductModel product,
  ) async {
    final db = await database;

    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductModel>> searchProducts(
    String keyword,
  ) async {
    final db = await database;

    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: [
        '%$keyword%',
        '%$keyword%',
      ],
    );

    return List.generate(
      maps.length,
      (index) => ProductModel.fromMap(
        maps[index],
      ),
    );
  }

  Future<void> deleteAllProducts() async {
    final db = await database;

    await db.delete('products');
  }

  Future<bool> barcodeExists(
    String barcode, {
    int? excludeId,
  }) async {
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
        whereArgs: [
          barcode,
          excludeId,
        ],
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

  Future<ProductModel?> getProductByBarcode(
    String barcode,
  ) async {
    final db = await database;

    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (result.isEmpty) {
      return null;
    }

    return ProductModel.fromMap(
      result.first,
    );
  }

  Future<ProductModel?> getProductById(
    int id,
  ) async {
    final db = await database;

    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return ProductModel.fromMap(
      result.first,
    );
  }

  // ============================================================
  // INVOICES
  // ============================================================

  Future<int> insertInvoice(
    InvoiceModel invoice,
  ) async {
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
      (index) => InvoiceModel.fromMap(
        maps[index],
      ),
    );
  }

  // ============================================================
  // جلب الفواتير حسب الفترة
  // ============================================================

  Future<List<InvoiceModel>> getInvoicesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final maps = await db.query(
      'invoices',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startDate.toString(),
        endDate.toString(),
      ],
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => InvoiceModel.fromMap(
        maps[index],
      ),
    );
  }

  // ============================================================
  // اليوم
  // ============================================================

  Future<List<InvoiceModel>> getTodayInvoices() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    return await getInvoicesByPeriod(
      startDate: start,
      endDate: end,
    );
  }

  // ============================================================
  // الأسبوع
  // ============================================================

  Future<List<InvoiceModel>> getWeekInvoices() async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final start = today.subtract(
      Duration(days: now.weekday - 1),
    );

    final end = start.add(
      const Duration(days: 7),
    );

    return await getInvoicesByPeriod(
      startDate: start,
      endDate: end,
    );
  }

  // ============================================================
  // الشهر
  // ============================================================

  Future<List<InvoiceModel>> getMonthInvoices() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      1,
    );

    final end = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    return await getInvoicesByPeriod(
      startDate: start,
      endDate: end,
    );
  }

  // ============================================================
  // مجموع مبيعات الفترة
  // ============================================================

  Future<double> getSalesTotalByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT SUM(total) AS total
      FROM invoices
      WHERE date >= ?
      AND date < ?
      ''',
      [
        startDate.toString(),
        endDate.toString(),
      ],
    );

    final value = result.first['total'];

    if (value == null) {
      return 0;
    }

    return (value as num).toDouble();
  }

  // ============================================================
  // الأرباح
  // ============================================================

  Future<double> getProfitByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT SUM(
        (sales.price - products.buyPrice)
        * sales.quantity
      ) AS profit
      FROM sales
      INNER JOIN products
      ON sales.productId = products.id
      WHERE sales.saleDate >= ?
      AND sales.saleDate < ?
      ''',
      [
        startDate.toString(),
        endDate.toString(),
      ],
    );

    final value = result.first['profit'];

    if (value == null) {
      return 0;
    }

    return (value as num).toDouble();
  }

  // ============================================================
  // SALES
  // ============================================================

  Future<int> insertSale(
    SaleModel sale,
  ) async {
    final db = await database;

    return await db.insert(
      'sales',
      sale.toMap(),
    );
  }

  Future<List<SaleModel>> getSales() async {
    final db = await database;

    final maps = await db.query(
      'sales',
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => SaleModel.fromMap(
        maps[index],
      ),
    );
  }

  Future<List<SaleModel>> getSalesByInvoice(
    int invoiceId,
  ) async {
    final db = await database;

    final maps = await db.query(
      'sales',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );

    return List.generate(
      maps.length,
      (index) => SaleModel.fromMap(
        maps[index],
      ),
    );
  }

  Future<void> deleteAllSales() async {
    final db = await database;

    await db.delete('sales');
  }

  // ============================================================
  // حذف فاتورة + مبيعاتها
  // ============================================================

  Future<void> deleteInvoiceWithSales(
    int invoiceId,
  ) async {
    final db = await database;

    await db.transaction(
      (txn) async {
        await txn.delete(
          'sales',
          where: 'invoiceId = ?',
          whereArgs: [invoiceId],
        );

        await txn.delete(
          'invoices',
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
      },
    );
  }

  // ============================================================
  // حذف فاتورة فقط
  // ============================================================

  Future<int> deleteInvoice(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // تحديث الفاتورة
  // ============================================================

 Future<void> updateInvoice(
  InvoiceModel invoice,
  List<CartItemModel> cart,
) async {
  final db = await database;

  await db.transaction((txn) async {
    // 1️⃣ جلب المبيعات القديمة للفاتورة
    final oldSales = await txn.query(
      'sales',
      where: 'invoiceId = ?',
      whereArgs: [invoice.id],
    );

    // 2️⃣ إعادة الكميات القديمة إلى المخزن
    for (final sale in oldSales) {
      final productId = sale['productId'] as int;
      final oldQuantity = sale['quantity'] as int;

      await txn.rawUpdate(
        '''
        UPDATE products
        SET quantity = quantity + ?
        WHERE id = ?
        ''',
        [oldQuantity, productId],
      );
    }

    // 3️⃣ حذف مبيعات الفاتورة القديمة
    await txn.delete(
      'sales',
      where: 'invoiceId = ?',
      whereArgs: [invoice.id],
    );

    // 4️⃣ إضافة المبيعات الجديدة
    for (final item in cart) {
      await txn.insert(
        'sales',
        SaleModel(
          invoiceId: invoice.id,
          productId: item.product.id!,
          productName: item.product.name,
          barcode: item.product.barcode,
          price: item.product.sellPrice,
          quantity: item.quantity,
          total: item.totalPrice,
          saleDate: DateTime.now().toString(),
        ).toMap(),
      );

      // 5️⃣ خصم الكمية الجديدة من المخزن
      await txn.rawUpdate(
        '''
        UPDATE products
        SET quantity = quantity - ?
        WHERE id = ?
        ''',
        [
          item.quantity,
          item.product.id,
        ],
      );
    }

    // 6️⃣ تحديث بيانات الفاتورة والإجمالي الجديد
    await txn.update(
      'invoices',
      {
        'customerName': invoice.customerName,
        'date': invoice.date,
        'total': invoice.total,
        'paymentType': invoice.paymentType,
        'notes': invoice.notes,
      },
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  });
}

  Future<void> updateInvoiceData({
  required int invoiceId,
  required String customerName,
  required String date,
  required double total,
  required String paymentType,
  required String notes,
}) async {
  final db = await database;

  await db.update(
    'invoices',
    {
      'customerName': customerName,
      'date': date,
      'total': total,
      'paymentType': paymentType,
      'notes': notes,
    },
    where: 'id = ?',
    whereArgs: [invoiceId],
  );
}

  // ============================================================
  // إغلاق قاعدة البيانات
  // ============================================================

  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}