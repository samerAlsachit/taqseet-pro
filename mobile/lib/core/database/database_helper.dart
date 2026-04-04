import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static final Logger _logger = Logger();
  static const String _dbName = 'taqseet_pro.db';
  static const int _dbVersion = 1;

  // Singleton pattern
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _dbName);
      
      _logger.i('Initializing database at: $path');
      
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      _logger.e('Error initializing database: $e');
      rethrow;
    }
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      _logger.i('Creating database tables...');
      
      // Create customers table
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

      // Create products table
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          store_id TEXT NOT NULL,
          name TEXT NOT NULL,
          category TEXT,
          quantity INTEGER DEFAULT 0,
          low_stock_alert INTEGER DEFAULT 5,
          sell_price_cash_iqd REAL NOT NULL,
          sell_price_install_iqd REAL NOT NULL,
          currency TEXT DEFAULT 'IQD',
          sync_status TEXT DEFAULT 'pending',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create installment_plans table
      await db.execute('''
        CREATE TABLE installment_plans (
          id TEXT PRIMARY KEY,
          store_id TEXT NOT NULL,
          customer_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          product_name TEXT NOT NULL,
          total_price REAL NOT NULL,
          down_payment REAL DEFAULT 0,
          remaining_amount REAL NOT NULL,
          currency TEXT DEFAULT 'IQD',
          frequency TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          status TEXT DEFAULT 'active',
          sync_status TEXT DEFAULT 'pending',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');

      // Create payment_schedule table
      await db.execute('''
        CREATE TABLE payment_schedule (
          id TEXT PRIMARY KEY,
          plan_id TEXT NOT NULL,
          store_id TEXT NOT NULL,
          installment_no INTEGER NOT NULL,
          due_date TEXT NOT NULL,
          amount REAL NOT NULL,
          status TEXT DEFAULT 'pending',
          sync_status TEXT DEFAULT 'pending',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (plan_id) REFERENCES installment_plans (id)
        )
      ''');

      // Create payments table
      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY,
          plan_id TEXT NOT NULL,
          schedule_id TEXT,
          store_id TEXT NOT NULL,
          amount_paid REAL NOT NULL,
          payment_date TEXT NOT NULL,
          receipt_number TEXT,
          notes TEXT,
          sync_status TEXT DEFAULT 'pending',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (plan_id) REFERENCES installment_plans (id),
          FOREIGN KEY (schedule_id) REFERENCES payment_schedule (id)
        )
      ''');

      // Create indexes for better performance
      await db.execute('CREATE INDEX idx_customers_store_id ON customers (store_id)');
      await db.execute('CREATE INDEX idx_products_store_id ON products (store_id)');
      await db.execute('CREATE INDEX idx_plans_store_id ON installment_plans (store_id)');
      await db.execute('CREATE INDEX idx_plans_customer_id ON installment_plans (customer_id)');
      await db.execute('CREATE INDEX idx_schedule_plan_id ON payment_schedule (plan_id)');
      await db.execute('CREATE INDEX idx_payments_plan_id ON payments (plan_id)');
      await db.execute('CREATE INDEX idx_sync_status_customers ON customers (sync_status)');
      await db.execute('CREATE INDEX idx_sync_status_products ON products (sync_status)');
      await db.execute('CREATE INDEX idx_sync_status_plans ON installment_plans (sync_status)');
      await db.execute('CREATE INDEX idx_sync_status_schedule ON payment_schedule (sync_status)');
      await db.execute('CREATE INDEX idx_sync_status_payments ON payments (sync_status)');

      _logger.i('Database tables created successfully');
    } catch (e) {
      _logger.e('Error creating tables: $e');
      rethrow;
    }
  }

  // Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      _logger.i('Upgrading database from version $oldVersion to $newVersion');
      // Handle database upgrades here
    } catch (e) {
      _logger.e('Error upgrading database: $e');
      rethrow;
    }
  }

  // Generate UUID
  String generateId() {
    return const Uuid().v4();
  }

  // Get current timestamp
  String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }

  // Format date for display
  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // ==================== CUSTOMERS CRUD ====================

  // Insert customer
  Future<String> insertCustomer(Map<String, dynamic> customer) async {
    try {
      final db = await database;
      customer['id'] = customer['id'] ?? generateId();
      customer['created_at'] = customer['created_at'] ?? getCurrentTimestamp();
      customer['updated_at'] = getCurrentTimestamp();
      customer['sync_status'] = customer['sync_status'] ?? 'pending';

      await db.insert('customers', customer);
      _logger.i('Customer inserted: ${customer['id']}');
      return customer['id'];
    } catch (e) {
      _logger.e('Error inserting customer: $e');
      rethrow;
    }
  }

  // Get all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final db = await database;
      final result = await db.query('customers', orderBy: 'created_at DESC');
      return result;
    } catch (e) {
      _logger.e('Error getting all customers: $e');
      rethrow;
    }
  }

  // Get customer by ID
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      _logger.e('Error getting customer by ID: $e');
      rethrow;
    }
  }

  // Update customer
  Future<int> updateCustomer(String id, Map<String, dynamic> customer) async {
    try {
      final db = await database;
      customer['updated_at'] = getCurrentTimestamp();
      customer['sync_status'] = 'pending';

      final result = await db.update(
        'customers',
        customer,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Customer updated: $id');
      return result;
    } catch (e) {
      _logger.e('Error updating customer: $e');
      rethrow;
    }
  }

  // Delete customer
  Future<int> deleteCustomer(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Customer deleted: $id');
      return result;
    } catch (e) {
      _logger.e('Error deleting customer: $e');
      rethrow;
    }
  }

  // Search customers
  Future<List<Map<String, dynamic>>> searchCustomers(String query, String storeId) async {
    try {
      final db = await database;
      final result = await db.query(
        'customers',
        where: 'store_id = ? AND (full_name LIKE ? OR phone LIKE ?)',
        whereArgs: [storeId, '%$query%', '%$query%'],
        orderBy: 'full_name ASC',
      );
      return result;
    } catch (e) {
      _logger.e('Error searching customers: $e');
      rethrow;
    }
  }

  // ==================== PRODUCTS CRUD ====================

  // Insert product
  Future<String> insertProduct(Map<String, dynamic> product) async {
    try {
      final db = await database;
      product['id'] = product['id'] ?? generateId();
      product['created_at'] = product['created_at'] ?? getCurrentTimestamp();
      product['updated_at'] = getCurrentTimestamp();
      product['sync_status'] = product['sync_status'] ?? 'pending';

      await db.insert('products', product);
      _logger.i('Product inserted: ${product['id']}');
      return product['id'];
    } catch (e) {
      _logger.e('Error inserting product: $e');
      rethrow;
    }
  }

  // Get all products
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final db = await database;
      final result = await db.query('products', orderBy: 'created_at DESC');
      return result;
    } catch (e) {
      _logger.e('Error getting all products: $e');
      rethrow;
    }
  }

  // Get product by ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      _logger.e('Error getting product by ID: $e');
      rethrow;
    }
  }

  // Update product
  Future<int> updateProduct(String id, Map<String, dynamic> product) async {
    try {
      final db = await database;
      product['updated_at'] = getCurrentTimestamp();
      product['sync_status'] = 'pending';

      final result = await db.update(
        'products',
        product,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Product updated: $id');
      return result;
    } catch (e) {
      _logger.e('Error updating product: $e');
      rethrow;
    }
  }

  // Delete product
  Future<int> deleteProduct(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Product deleted: $id');
      return result;
    } catch (e) {
      _logger.e('Error deleting product: $e');
      rethrow;
    }
  }

  // Update product quantity
  Future<int> updateProductQuantity(String id, int quantity) async {
    try {
      final db = await database;
      final result = await db.update(
        'products',
        {
          'quantity': quantity,
          'updated_at': getCurrentTimestamp(),
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Product quantity updated: $id');
      return result;
    } catch (e) {
      _logger.e('Error updating product quantity: $e');
      rethrow;
    }
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts(String storeId) async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'store_id = ? AND quantity <= low_stock_alert',
        whereArgs: [storeId],
        orderBy: 'quantity ASC',
      );
      return result;
    } catch (e) {
      _logger.e('Error getting low stock products: $e');
      rethrow;
    }
  }

  // ==================== INSTALLMENT PLANS CRUD ====================

  // Insert installment plan
  Future<String> insertInstallmentPlan(Map<String, dynamic> plan) async {
    try {
      final db = await database;
      plan['id'] = plan['id'] ?? generateId();
      plan['created_at'] = plan['created_at'] ?? getCurrentTimestamp();
      plan['updated_at'] = getCurrentTimestamp();
      plan['sync_status'] = plan['sync_status'] ?? 'pending';

      await db.insert('installment_plans', plan);
      _logger.i('Installment plan inserted: ${plan['id']}');
      return plan['id'];
    } catch (e) {
      _logger.e('Error inserting installment plan: $e');
      rethrow;
    }
  }

  // Get all installment plans
  Future<List<Map<String, dynamic>>> getAllInstallmentPlans() async {
    try {
      final db = await database;
      final result = await db.query('installment_plans', orderBy: 'created_at DESC');
      return result;
    } catch (e) {
      _logger.e('Error getting all installment plans: $e');
      rethrow;
    }
  }

  // Get installment plans by customer
  Future<List<Map<String, dynamic>>> getInstallmentPlansByCustomer(String customerId) async {
    try {
      final db = await database;
      final result = await db.query(
        'installment_plans',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );
      return result;
    } catch (e) {
      _logger.e('Error getting installment plans by customer: $e');
      rethrow;
    }
  }

  // Update installment plan
  Future<int> updateInstallmentPlan(String id, Map<String, dynamic> plan) async {
    try {
      final db = await database;
      plan['updated_at'] = getCurrentTimestamp();
      plan['sync_status'] = 'pending';

      final result = await db.update(
        'installment_plans',
        plan,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Installment plan updated: $id');
      return result;
    } catch (e) {
      _logger.e('Error updating installment plan: $e');
      rethrow;
    }
  }

  // ==================== PAYMENT SCHEDULE CRUD ====================

  // Insert payment schedule
  Future<String> insertPaymentSchedule(Map<String, dynamic> schedule) async {
    try {
      final db = await database;
      schedule['id'] = schedule['id'] ?? generateId();
      schedule['created_at'] = schedule['created_at'] ?? getCurrentTimestamp();
      schedule['updated_at'] = getCurrentTimestamp();
      schedule['sync_status'] = schedule['sync_status'] ?? 'pending';

      await db.insert('payment_schedule', schedule);
      _logger.i('Payment schedule inserted: ${schedule['id']}');
      return schedule['id'];
    } catch (e) {
      _logger.e('Error inserting payment schedule: $e');
      rethrow;
    }
  }

  // Get payment schedule by plan
  Future<List<Map<String, dynamic>>> getPaymentScheduleByPlan(String planId) async {
    try {
      final db = await database;
      final result = await db.query(
        'payment_schedule',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'installment_no ASC',
      );
      return result;
    } catch (e) {
      _logger.e('Error getting payment schedule by plan: $e');
      rethrow;
    }
  }

  // Update payment schedule
  Future<int> updatePaymentSchedule(String id, Map<String, dynamic> schedule) async {
    try {
      final db = await database;
      schedule['updated_at'] = getCurrentTimestamp();
      schedule['sync_status'] = 'pending';

      final result = await db.update(
        'payment_schedule',
        schedule,
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Payment schedule updated: $id');
      return result;
    } catch (e) {
      _logger.e('Error updating payment schedule: $e');
      rethrow;
    }
  }

  // ==================== PAYMENTS CRUD ====================

  // Insert payment
  Future<String> insertPayment(Map<String, dynamic> payment) async {
    try {
      final db = await database;
      payment['id'] = payment['id'] ?? generateId();
      payment['created_at'] = payment['created_at'] ?? getCurrentTimestamp();
      payment['updated_at'] = getCurrentTimestamp();
      payment['sync_status'] = payment['sync_status'] ?? 'pending';

      await db.insert('payments', payment);
      _logger.i('Payment inserted: ${payment['id']}');
      return payment['id'];
    } catch (e) {
      _logger.e('Error inserting payment: $e');
      rethrow;
    }
  }

  // Get payments by plan
  Future<List<Map<String, dynamic>>> getPaymentsByPlan(String planId) async {
    try {
      final db = await database;
      final result = await db.query(
        'payments',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'payment_date DESC',
      );
      return result;
    } catch (e) {
      _logger.e('Error getting payments by plan: $e');
      rethrow;
    }
  }

  // Get today's payments
  Future<List<Map<String, dynamic>>> getTodayPayments(String storeId) async {
    try {
      final db = await database;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await db.rawQuery('''
        SELECT p.*, c.full_name as customer_name, pl.product_name
        FROM payments p
        JOIN installment_plans pl ON p.plan_id = pl.id
        JOIN customers c ON pl.customer_id = c.id
        WHERE p.store_id = ? AND DATE(p.payment_date) = ?
        ORDER BY p.payment_date DESC
      ''', [storeId, today]);
      return result;
    } catch (e) {
      _logger.e('Error getting today payments: $e');
      rethrow;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  // Get unsynced data
  Future<Map<String, List<Map<String, dynamic>>>> getUnsyncedData() async {
    try {
      final db = await database;
      
      final customers = await db.query(
        'customers',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );
      
      final products = await db.query(
        'products',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );
      
      final plans = await db.query(
        'installment_plans',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );
      
      final schedules = await db.query(
        'payment_schedule',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );
      
      final payments = await db.query(
        'payments',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );

      return {
        'customers': customers,
        'products': products,
        'installment_plans': plans,
        'payment_schedule': schedules,
        'payments': payments,
      };
    } catch (e) {
      _logger.e('Error getting unsynced data: $e');
      rethrow;
    }
  }

  // Update sync status
  Future<void> updateSyncStatus(String table, String id, String status) async {
    try {
      final db = await database;
      await db.update(
        table,
        {'sync_status': status, 'updated_at': getCurrentTimestamp()},
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i('Sync status updated for $table: $id -> $status');
    } catch (e) {
      _logger.e('Error updating sync status: $e');
      rethrow;
    }
  }

  // Mark all as synced
  Future<void> markAllAsSynced() async {
    try {
      final db = await database;
      final tables = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments'];
      
      for (final table in tables) {
        await db.update(
          table,
          {'sync_status': 'synced', 'updated_at': getCurrentTimestamp()},
          where: 'sync_status = ?',
          whereArgs: ['pending'],
        );
      }
      
      _logger.i('All data marked as synced');
    } catch (e) {
      _logger.e('Error marking all as synced: $e');
      rethrow;
    }
  }

  // Get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;
      
      final customersCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM customers')
      ) ?? 0;
      
      final productsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products')
      ) ?? 0;
      
      final plansCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM installment_plans')
      ) ?? 0;
      
      final paymentsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM payments')
      ) ?? 0;

      return {
        'customers': customersCount,
        'products': productsCount,
        'installment_plans': plansCount,
        'payments': paymentsCount,
      };
    } catch (e) {
      _logger.e('Error getting database stats: $e');
      rethrow;
    }
  }

  // Close database
  Future<void> close() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
      _logger.i('Database closed');
    } catch (e) {
      _logger.e('Error closing database: $e');
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('payments');
      await db.delete('payment_schedule');
      await db.delete('installment_plans');
      await db.delete('products');
      await db.delete('customers');
      _logger.i('All data cleared');
    } catch (e) {
      _logger.e('Error clearing all data: $e');
      rethrow;
    }
  }
}
