import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../core/logger/app_logger.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._();
  factory SQLiteService() => _instance;
  SQLiteService._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'marsa_sync.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            data TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    AppLogger.info('SQLite initialized');
  }

  Database get db {
    if (_db == null) throw Exception('Database not initialized');
    return _db!;
  }

  Future<int> insertSyncQueue(Map<String, dynamic> item) async =>
      db.insert('sync_queue', item);

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async =>
      db.query('sync_queue', where: 'status = ?', whereArgs: ['pending'], orderBy: 'created_at ASC');

  Future<void> markSynced(int id) async =>
      db.update('sync_queue', {'status': 'synced'}, where: 'id = ?', whereArgs: [id]);

  Future<void> markFailed(int id) async =>
      db.update('sync_queue', {'status': 'failed'}, where: 'id = ?', whereArgs: [id]);

  Future<int> pendingCount() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE status = ?', ['pending'])) ?? 0;
}
