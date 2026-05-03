import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  factory SQLiteService() => _instance;
  SQLiteService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        id_number TEXT,
        avatar_url TEXT,
        id_card_front_url TEXT,
        id_card_back_url TEXT,
        residence_front_url TEXT,
        residence_back_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        quantity INTEGER DEFAULT 0,
        cash_price REAL DEFAULT 0,
        installment_price REAL DEFAULT 0,
        cost_price REAL DEFAULT 0,
        image_url TEXT,
        barcode TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Installment Plans table
    await db.execute('''
      CREATE TABLE installment_plans (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        total_amount REAL DEFAULT 0,
        down_payment REAL DEFAULT 0,
        financed_amount REAL DEFAULT 0,
        installments_count INTEGER DEFAULT 0,
        installment_amount REAL DEFAULT 0,
        start_date TEXT,
        end_date TEXT,
        status TEXT DEFAULT 'active',
        notes TEXT,
        products TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // Payment Schedule table
    await db.execute('''
      CREATE TABLE payment_schedule (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        installment_no INTEGER,
        due_date TEXT,
        amount REAL DEFAULT 0,
        status TEXT DEFAULT 'pending',
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (plan_id) REFERENCES installment_plans (id)
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        schedule_id TEXT,
        amount_paid REAL DEFAULT 0,
        payment_date TEXT,
        payment_method TEXT DEFAULT 'cash',
        receipt_number TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (plan_id) REFERENCES installment_plans (id)
      )
    ''');

    // Cash Sales table
    await db.execute('''
      CREATE TABLE cash_sales (
        id TEXT PRIMARY KEY,
        customer_name TEXT,
        customer_phone TEXT,
        products TEXT NOT NULL,
        total_amount REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        final_amount REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'cash',
        receipt_number TEXT,
        notes TEXT,
        sale_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT,
        synced_at TEXT
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
  }

  Future<void> init() async {
    await database;
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
