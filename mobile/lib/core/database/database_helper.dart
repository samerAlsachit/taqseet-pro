import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final Uuid _uuid = const Uuid();

  // ✅ الإصدار 3
  static const int _databaseVersion = 3;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'marsa.db');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ✅ تحديث onUpgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE installment_plans ADD COLUMN customer_name TEXT',
        );
        print('✅ تم إضافة customer_name');
      } catch (e) {
        print('ℹ️ customer_name موجود: $e');
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE payment_schedule ADD COLUMN created_at TEXT',
        );
        print('✅ تم إضافة created_at');
      } catch (e) {
        print('ℹ️ created_at موجود: $e');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT,
        phone_alt TEXT,
        address TEXT,
        national_id TEXT,
        notes TEXT,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        quantity INTEGER NOT NULL DEFAULT 0,
        low_stock_alert INTEGER NOT NULL DEFAULT 5,
        sell_price_cash_iqd INTEGER NOT NULL DEFAULT 0,
        sell_price_install_iqd INTEGER NOT NULL DEFAULT 0,
        currency TEXT DEFAULT 'IQD',
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // installment_plans table
    await db.execute('''
      CREATE TABLE installment_plans (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        customer_name TEXT,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        total_price INTEGER NOT NULL,
        down_payment INTEGER NOT NULL,
        financed_amount INTEGER NOT NULL,
        remaining_amount INTEGER NOT NULL,
        currency TEXT DEFAULT 'IQD',
        frequency TEXT NOT NULL,
        installment_amount INTEGER NOT NULL,
        installments_count INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // ✅ payment_schedule مع created_at
    await db.execute('''
      CREATE TABLE payment_schedule (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        store_id TEXT NOT NULL,
        installment_no INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        amount INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES installment_plans (id)
      )
    ''');

    // payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        schedule_id TEXT NOT NULL,
        store_id TEXT NOT NULL,
        amount_paid INTEGER NOT NULL,
        payment_date TEXT NOT NULL,
        receipt_number TEXT NOT NULL,
        notes TEXT,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ... باقي الدوال كما هي (CRUD operations)

  // ==================== CUSTOMERS CRUD ====================

  Future<String> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    customer['id'] = customer['id'] ?? _uuid.v4();
    customer['created_at'] =
        customer['created_at'] ?? DateTime.now().toIso8601String();
    customer['updated_at'] = DateTime.now().toIso8601String();
    customer['sync_status'] = customer['sync_status'] ?? 'pending';

    await db.insert('customers', customer);
    return customer['id'];
  }

  Future<int> updateCustomer(String id, Map<String, dynamic> customer) async {
    final db = await database;

    // Don't update created_at
    customer.remove('created_at');
    customer['updated_at'] = DateTime.now().toIso8601String();
    customer['sync_status'] = 'pending';

    final result = await db.update(
      'customers',
      {
        'store_id': customer['store_id'],
        'full_name': customer['full_name'],
        'phone': customer['phone'],
        'phone_alt': customer['phone_alt'],
        'address': customer['address'],
        'national_id': customer['national_id'],
        'notes': customer['notes'],
        'sync_status': customer['sync_status'],
        'updated_at': customer['updated_at'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> deleteCustomer(String id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchCustomers(
    String query,
    String storeId,
  ) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'store_id = ? AND full_name LIKE ?',
      whereArgs: [storeId, '%$query%'],
      orderBy: 'full_name ASC',
    );
  }

  // ==================== PRODUCTS CRUD ====================

  Future<String> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    product['id'] = product['id'] ?? _uuid.v4();
    product['created_at'] =
        product['created_at'] ?? DateTime.now().toIso8601String();
    product['updated_at'] = DateTime.now().toIso8601String();
    product['sync_status'] = product['sync_status'] ?? 'pending';

    await db.insert('products', product);
    return product['id'];
  }

  Future<int> updateProduct(String id, Map<String, dynamic> product) async {
    final db = await database;

    // Don't update created_at
    product.remove('created_at');
    product['updated_at'] = DateTime.now().toIso8601String();
    product['sync_status'] = 'pending';

    final result = await db.update(
      'products',
      {
        'store_id': product['store_id'],
        'name': product['name'],
        'category': product['category'],
        'quantity': product['quantity'],
        'low_stock_alert': product['low_stock_alert'],
        'sell_price_cash_iqd': product['sell_price_cash_iqd'],
        'sell_price_install_iqd': product['sell_price_install_iqd'],
        'currency': product['currency'],
        'sync_status': product['sync_status'],
        'updated_at': product['updated_at'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getProductById(String id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchProducts(
    String query,
    String storeId,
  ) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'store_id = ? AND name LIKE ?',
      whereArgs: [storeId, '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts(String storeId) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'store_id = ? AND quantity <= low_stock_alert',
      whereArgs: [storeId],
      orderBy: 'quantity ASC',
    );
  }

  // ==================== INSTALLMENT PLANS CRUD ====================

  Future<String> insertInstallmentPlan(Map<String, dynamic> plan) async {
    final db = await database;
    plan['id'] = plan['id'] ?? _uuid.v4();
    plan['created_at'] = plan['created_at'] ?? DateTime.now().toIso8601String();
    plan['updated_at'] = DateTime.now().toIso8601String();
    plan['sync_status'] = plan['sync_status'] ?? 'pending';

    await db.insert('installment_plans', plan);
    return plan['id'];
  }

  Future<int> updateInstallmentPlan(
    String id,
    Map<String, dynamic> plan,
  ) async {
    final db = await database;

    // Don't update created_at
    plan.remove('created_at');
    plan['updated_at'] = DateTime.now().toIso8601String();
    plan['sync_status'] = 'pending';

    final result = await db.update(
      'installment_plans',
      {
        'store_id': plan['store_id'],
        'customer_id': plan['customer_id'],
        'customer_name': plan['customer_name'],
        'product_id': plan['product_id'],
        'product_name': plan['product_name'],
        'total_price': plan['total_price'],
        'down_payment': plan['down_payment'],
        'financed_amount': plan['financed_amount'],
        'remaining_amount': plan['remaining_amount'],
        'currency': plan['currency'],
        'frequency': plan['frequency'],
        'installment_amount': plan['installment_amount'],
        'installments_count': plan['installments_count'],
        'start_date': plan['start_date'],
        'end_date': plan['end_date'],
        'status': plan['status'],
        'sync_status': plan['sync_status'],
        'updated_at': plan['updated_at'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> deleteInstallmentPlan(String id) async {
    final db = await database;
    return await db.delete(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getInstallmentPlanById(String id) async {
    final db = await database;
    final result = await db.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllInstallmentPlans() async {
    final db = await database;
    return await db.query('installment_plans', orderBy: 'created_at DESC');
  }

  // ==================== PAYMENT SCHEDULE CRUD ====================

  // ✅ تحديث لإضافة created_at
  Future<int> insertPaymentSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    schedule['id'] = schedule['id'] ?? _uuid.v4();
    schedule['sync_status'] = schedule['sync_status'] ?? 'pending';
    schedule['created_at'] =
        schedule['created_at'] ??
        DateTime.now().toIso8601String(); // ✅ إضافة created_at

    return await db.insert('payment_schedule', schedule);
  }

  Future<int> updatePaymentScheduleStatus(String id, String status) async {
    final db = await database;
    return await db.update(
      'payment_schedule',
      {'status': status, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentScheduleByPlanId(
    String planId,
  ) async {
    final db = await database;
    return await db.query(
      'payment_schedule',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'installment_no ASC',
    );
  }

  Future<int> deletePaymentScheduleByPlanId(String planId) async {
    final db = await database;
    return await db.delete(
      'payment_schedule',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }

  // ==================== PAYMENTS CRUD ====================

  Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;
    payment['id'] = payment['id'] ?? _uuid.v4();
    payment['sync_status'] = payment['sync_status'] ?? 'pending';

    return await db.insert('payments', payment);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByPlanId(String planId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'payment_date DESC',
    );
  }

  // ==================== SYNC FUNCTIONS ====================

  Future<Map<String, List<Map<String, dynamic>>>> getUnsyncedData() async {
    final db = await database;

    final unsyncedCustomers = await db.query(
      'customers',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    final unsyncedProducts = await db.query(
      'products',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    final unsyncedInstallmentPlans = await db.query(
      'installment_plans',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    final unsyncedPaymentSchedule = await db.query(
      'payment_schedule',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    final unsyncedPayments = await db.query(
      'payments',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    return {
      'customers': unsyncedCustomers,
      'products': unsyncedProducts,
      'installment_plans': unsyncedInstallmentPlans,
      'payment_schedule': unsyncedPaymentSchedule,
      'payments': unsyncedPayments,
    };
  }

  Future<int> updateSyncStatus(String table, String id, String status) async {
    final db = await database;
    return await db.update(
      table,
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;

    final customersCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;

    final productsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;

    final installmentPlansCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM installment_plans'),
        ) ??
        0;

    final paymentsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM payments'),
        ) ??
        0;

    return {
      'customers_count': customersCount,
      'products_count': productsCount,
      'installment_plans_count': installmentPlansCount,
      'payments_count': paymentsCount,
      'database_path': db.path,
    };
  }

  // ==================== UTILITY FUNCTIONS ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('payments');
    await db.delete('payment_schedule');
    await db.delete('installment_plans');
    await db.delete('products');
    await db.delete('customers');
  }

  // Update product quantity
  Future<int> updateProductQuantity(String id, int quantity) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
