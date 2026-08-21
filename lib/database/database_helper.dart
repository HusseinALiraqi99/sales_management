import 'package:path/path.dart';
import 'package:sales_management/models/cart_item_model.dart';
import 'package:sqflite/sqflite.dart';

import '../models/debt_payment_model.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  // ============================================================
  // DATABASE
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
  // CREATE DATABASE
  // ============================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // PRODUCTS
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

    // INVOICES
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

    // SALES
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

    // DEBT PAYMENTS
    await db.execute('''
      CREATE TABLE debt_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL
      )
    ''');
  }

  // ============================================================
  // DATABASE UPGRADE
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // VERSION 3
    if (oldVersion < 3) {
      final columns = await db.rawQuery(
        'PRAGMA table_info(sales)',
      );

      final hasInvoiceId = columns.any(
        (column) => column['name'] == 'invoiceId',
      );

      if (!hasInvoiceId) {
        await db.execute('''
          ALTER TABLE sales
          ADD COLUMN invoiceId INTEGER
        ''');
      }
    }

    // VERSION 4
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerName TEXT NOT NULL,
          amount REAL NOT NULL,
          paymentDate TEXT NOT NULL
        )
      ''');
    }
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
      (index) => ProductModel.fromMap(maps[index]),
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
      (index) => ProductModel.fromMap(maps[index]),
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

    return ProductModel.fromMap(result.first);
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

    return ProductModel.fromMap(result.first);
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
      (index) => InvoiceModel.fromMap(maps[index]),
    );
  }

  Future<List<InvoiceModel>> getInvoicesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final maps = await db.rawQuery(
      '''
      SELECT *
      FROM invoices
      WHERE date >= ?
      AND date < ?
      ORDER BY id DESC
      ''',
      [
        startDate.toString(),
        endDate.toString(),
      ],
    );

    return List.generate(
      maps.length,
      (index) => InvoiceModel.fromMap(maps[index]),
    );
  }

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

  Future<int> updateInvoice(
    InvoiceModel invoice,
  ) async {
    final db = await database;

    return await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
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
      (index) => SaleModel.fromMap(maps[index]),
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
      (index) => SaleModel.fromMap(maps[index]),
    );
  }

  Future<void> deleteAllSales() async {
    final db = await database;

    await db.delete('sales');
  }

  // ============================================================
  // UPDATE INVOICE WITH CART
  // ============================================================

  Future<void> updateInvoiceWithCart(
    InvoiceModel invoice,
    List<CartItemModel> cart,
  ) async {
    final db = await database;

    await db.transaction(
      (txn) async {
        final oldSales = await txn.query(
          'sales',
          where: 'invoiceId = ?',
          whereArgs: [invoice.id],
        );

        for (final sale in oldSales) {
          final productId =
              (sale['productId'] as num).toInt();

          final oldQuantity =
              (sale['quantity'] as num).toInt();

          await txn.rawUpdate(
            '''
            UPDATE products
            SET quantity = quantity + ?
            WHERE id = ?
            ''',
            [
              oldQuantity,
              productId,
            ],
          );
        }

        await txn.delete(
          'sales',
          where: 'invoiceId = ?',
          whereArgs: [invoice.id],
        );

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
      },
    );
  }

  // ============================================================
  // REPORTS
  // ============================================================

  Future<double> getSalesTotalByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM sales
      WHERE saleDate >= ?
      AND saleDate < ?
      ''',
      [
        startDate.toString(),
        endDate.toString(),
      ],
    );

    return (result.first['total'] as num?)
            ?.toDouble() ??
        0.0;
  }

  Future<double> getProfitByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        COALESCE(
          SUM(
            (sales.price - products.buyPrice)
            * sales.quantity
          ),
          0
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

    return (result.first['profit'] as num?)
            ?.toDouble() ??
        0.0;
  }

  // ============================================================
  // DEBTS
  // ============================================================

  Future<List<InvoiceModel>> getDebtInvoices() async {
    final db = await database;

    final maps = await db.query(
      'invoices',
      where: 'paymentType = ?',
      whereArgs: ['آجل'],
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => InvoiceModel.fromMap(maps[index]),
    );
  }

  Future<List<InvoiceModel>> getDebtHistory() async {
    final db = await database;

    final maps = await db.query(
      'invoices',
      where: 'paymentType = ?',
      whereArgs: ['آجل'],
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => InvoiceModel.fromMap(maps[index]),
    );
  }

  Future<List<InvoiceModel>> searchDebtHistory(
    String customerName,
  ) async {
    final db = await database;

    final maps = await db.query(
      'invoices',
      where:
          'paymentType = ? AND customerName LIKE ?',
      whereArgs: [
        'آجل',
        '%$customerName%',
      ],
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => InvoiceModel.fromMap(maps[index]),
    );
  }

  // ============================================================
  // DEBT PAYMENTS
  // ============================================================

Future<int> insertDebtPayment(
  DebtPaymentModel payment,
) async {
  final db = await database;

  try {
    final id = await db.insert(
      'debt_payments',
      {
        'customerName': payment.customerName.trim(),
        'amount': payment.amount,
        'paymentDate': payment.paymentDate,
      },
    );

    return id;
  } catch (e) {
    print('ERROR INSERT DEBT PAYMENT: $e');
    rethrow;
  }
}

  // ============================================================
  // أسماء الزبائن أصحاب الديون
  // ============================================================

  Future<List<String>> getDebtCustomerNames() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT DISTINCT TRIM(customerName) AS customerName
      FROM invoices
      WHERE paymentType = ?
        AND customerName IS NOT NULL
        AND TRIM(customerName) != ''
      ORDER BY customerName ASC
      ''',
      ['آجل'],
    );

    return result
        .map(
          (row) => row['customerName'].toString(),
        )
        .where(
          (name) => name.trim().isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // بيانات دين الزبون
  // ============================================================

Future<Map<String, double>> getCustomerDebtData(
  String customerName,
) async {
  final db = await database;

  final name = customerName.trim();

  // إجمالي الفواتير الآجلة
  final debtResult = await db.rawQuery(
    '''
    SELECT COALESCE(SUM(total), 0) AS total
    FROM invoices
    WHERE TRIM(customerName) = ?
      AND TRIM(paymentType) = ?
    ''',
    [
      name,
      'آجل',
    ],
  );

  // إجمالي التسديدات
  final paidResult = await db.rawQuery(
    '''
    SELECT COALESCE(SUM(amount), 0) AS total
    FROM debt_payments
    WHERE TRIM(customerName) = ?
    ''',
    [
      name,
    ],
  );

  final double debt =
      ((debtResult.first['total'] as num?) ?? 0)
          .toDouble();

  final double paid =
      ((paidResult.first['total'] as num?) ?? 0)
          .toDouble();

  double remaining = debt - paid;

  if (remaining < 0) {
    remaining = 0.0;
  }

  return {
    'debt': debt,
    'paid': paid,
    'remaining': remaining,
  };
}

  // ============================================================
  // جميع التسديدات
  // ============================================================

  Future<List<DebtPaymentModel>> getDebtPayments() async {
    final db = await database;

    final maps = await db.query(
      'debt_payments',
      orderBy: 'id DESC',
    );

    return List.generate(
      maps.length,
      (index) => DebtPaymentModel.fromMap(
        maps[index],
      ),
    );
  }

  // ============================================================
  // حذف تسديد
  // ============================================================

  Future<int> deleteDebtPayment(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'debt_payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
  // ============================================================
// إجمالي دين الزبون
// ============================================================

Future<double> getCustomerDebtAmount(
  String customerName,
) async {
  final db = await database;

  final name = customerName.trim();

 final result = await db.rawQuery(
  '''
  SELECT id, customerName, paymentType, total
  FROM invoices
  WHERE TRIM(customerName) = ?
  ''',
  [name],
);

print("================================");
print("CUSTOMER: $name");
print("INVOICES: $result");
print("================================");


  final value = result.first['total'];

  if (value == null) {
    return 0.0;
  }

  return (value as num).toDouble();
}

// ============================================================
// إجمالي المبلغ المسدد للزبون
// ============================================================

Future<double> getCustomerPaidAmount(
  String customerName,
) async {
  final db = await database;

  final name = customerName.trim();

  final result = await db.rawQuery(
    '''
    SELECT COALESCE(SUM(amount), 0) AS total
    FROM debt_payments
    WHERE TRIM(customerName) = ?
    ''',
    [name],
  );

  final value = result.first['total'];

  if (value == null) {
    return 0.0;
  }

  return (value as num).toDouble();
}

// ============================================================
// الدين المتبقي على الزبون
// ============================================================

Future<double> getCustomerRemainingDebt(
  String customerName,
) async {
  final debt = await getCustomerDebtAmount(customerName);

  final paid = await getCustomerPaidAmount(customerName);

  final remaining = debt - paid;

  if (remaining <= 0) {
    return 0.0;
  }

  return remaining;
}
}