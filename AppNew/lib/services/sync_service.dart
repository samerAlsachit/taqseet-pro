import 'dart:async';
import '../core/logger/app_logger.dart';
import '../data/datasources/local/sqlite_service.dart';
import '../data/datasources/remote/api_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  final _sqlite = SQLiteService();
  final _api = ApiService();
  final _connectivity = ConnectivityService();
  StreamSubscription? _subscription;
  bool _isSyncing = false;

  Future<void> init() async {
    _subscription = _connectivity.onConnectivityChanged.listen((connected) {
      if (connected && !_isSyncing) sync();
    });
    if (_connectivity.isConnected) sync();
    AppLogger.info('SyncService initialized');
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    AppLogger.info('Sync started');
    try {
      await _push();
      await _pull();
      AppLogger.info('Sync completed');
    } catch (e) {
      AppLogger.error('Sync failed', e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _push() async {
    final items = await _sqlite.getPendingSyncItems();
    for (final item in items) {
      try {
        await _api.post('/sync/push', data: item);
        await _sqlite.markSynced(item['id'] as int);
        AppLogger.debug('Pushed: ${item['operation']} ${item['table_name']} ${item['record_id']}');
      } catch (e) {
        await _sqlite.markFailed(item['id'] as int);
        AppLogger.warn('Push failed: ${item['operation']} ${item['table_name']}');
      }
    }
  }

  Future<void> _pull() async {
    final result = await _api.get('/sync/pull');
    if (result['success'] == true && result['data'] != null) {
      AppLogger.info('Pulled data from server');
    }
  }

  Future<void> enqueue(String operation, String table, String recordId, Map<String, dynamic> data) async {
    await _sqlite.insertSyncQueue({
      'operation': operation,
      'table_name': table,
      'record_id': recordId,
      'data': data.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
    if (_connectivity.isConnected && !_isSyncing) sync();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
