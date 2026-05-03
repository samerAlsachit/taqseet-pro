import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/api_constants.dart';
import 'database/hive_service.dart';
import 'database/sqlite_service.dart';
import 'api/api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _hive = HiveService();
  final _sqlite = SQLiteService();
  final _api = ApiService();

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  Timer? _syncTimer;
  bool _isSyncing = false;

  Future<void> init() async {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Auto-sync when connection restored
        Future.delayed(const Duration(seconds: 2), () => syncAll());
      }
    });

    // Start periodic sync
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncAll(),
    );
  }

  Future<void> dispose() {
    _syncTimer?.cancel();
    return _syncStatusController.close();
  }

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'المزامنة قيد التقدم بالفعل');
    }

    if (!await isOnline) {
      return SyncResult(success: false, message: 'لا يوجد اتصال بالإنترنت');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // 1. Push pending local changes first
      await _pushPendingChanges();

      // 2. Pull server data
      await _pullServerData();

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.lastSyncKey, DateTime.now().toIso8601String());

      _isSyncing = false;
      _syncStatusController.add(SyncStatus.completed);

      return SyncResult(success: true, message: 'تمت المزامنة بنجاح');
    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(SyncStatus.error);
      return SyncResult(success: false, message: 'فشل في المزامنة: $e');
    }
  }

  Future<void> _pushPendingChanges() async {
    final pendingItems = await _sqlite.query(
      'sync_queue',
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
    );

    for (final item in pendingItems) {
      try {
        final result = await _syncItem(item);
        if (result) {
          await _sqlite.update(
            'sync_queue',
            {'synced_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      } catch (e) {
        // Increment retry count
        final retryCount = (item['retry_count'] ?? 0) + 1;
        await _sqlite.update(
          'sync_queue',
          {'retry_count': retryCount},
          where: 'id = ?',
          whereArgs: [item['id']],
        );

        // Remove if max retries exceeded
        if (retryCount >= AppConstants.maxSyncRetries) {
          await _sqlite.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
    }
  }

  Future<bool> _syncItem(Map<String, dynamic> item) async {
    final operation = item['operation'];
    final entityType = item['entity_type'];
    final data = jsonDecode(item['data']);

    ApiResult result;
    switch (operation) {
      case 'create':
        result = await _api.post('/$entityType', data: data);
        break;
      case 'update':
        result =
            await _api.put('/$entityType/${item['entity_id']}', data: data);
        break;
      case 'delete':
        result = await _api.delete('/$entityType/${item['entity_id']}');
        break;
      default:
        return false;
    }

    return result.success;
  }

  Future<void> _pullServerData() async {
    // Get last sync timestamp
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(AppConstants.lastSyncKey);

    final params = lastSync != null ? {'since': lastSync} : null;

    // Fetch customers
    final customersResult =
        await _api.get(ApiConstants.customers, params: params);
    if (customersResult.success && customersResult.data != null) {
      final customers = customersResult.data['data'] as List? ?? [];
      for (final customer in customers) {
        await _sqlite.insert('customers', {
          ...customer,
          'is_synced': 1,
        });
      }
    }

    // Fetch products
    final productsResult =
        await _api.get(ApiConstants.products, params: params);
    if (productsResult.success && productsResult.data != null) {
      final products = productsResult.data['data'] as List? ?? [];
      for (final product in products) {
        await _sqlite.insert('products', {
          ...product,
          'is_synced': 1,
        });
      }
    }

    // Fetch installments
    final installmentsResult =
        await _api.get(ApiConstants.installments, params: params);
    if (installmentsResult.success && installmentsResult.data != null) {
      final installments = installmentsResult.data['data'] as List? ?? [];
      for (final installment in installments) {
        await _sqlite.insert('installment_plans', {
          ...installment,
          'is_synced': 1,
        });
      }
    }
  }

  Future<void> queueForSync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    await _sqlite.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
    });

    // Try immediate sync if online
    if (await isOnline) {
      syncAll();
    }
  }
}

enum SyncStatus { idle, syncing, completed, error }

class SyncResult {
  final bool success;
  final String message;
  final int? syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount,
  });
}
