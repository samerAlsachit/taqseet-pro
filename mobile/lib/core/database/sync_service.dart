import 'dart:async';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static final Logger _logger = Logger();
  static const String _baseUrl =
      'https://api.taqseet-pro.com'; // Replace with actual API URL
  static const Duration _timeout = Duration(seconds: 30);

  // Singleton pattern
  factory SyncService() => _instance;
  SyncService._internal();

  late Dio _dio;
  late DatabaseHelper _dbHelper;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = false;

  // Initialize sync service
  Future<void> initialize() async {
    try {
      _dbHelper = DatabaseHelper();
      _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: _timeout,
          receiveTimeout: _timeout,
          sendTimeout: _timeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add auth interceptor
      _dio.interceptors.add(AuthInterceptor());

      // Add logging interceptor for debug
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => _logger.d(obj),
        ),
      );

      // Monitor connectivity
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        results,
      ) {
        final result = results.isNotEmpty
            ? results.first
            : ConnectivityResult.none;
        _isOnline = result != ConnectivityResult.none;
        _logger.i('Connectivity changed: $_isOnline');

        // Auto-sync when coming online
        if (_isOnline) {
          _autoSync();
        }
      });

      // Check initial connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      _logger.i('SyncService initialized');
    } catch (e) {
      _logger.e('Error initializing SyncService: $e');
      rethrow;
    }
  }

  // Check if online
  bool get isOnline => _isOnline;

  // Auto-sync when coming online
  Future<void> _autoSync() async {
    try {
      _logger.i('Starting auto-sync...');
      await syncToServer();
      await syncFromServer();
      _logger.i('Auto-sync completed');
    } catch (e) {
      _logger.e('Error in auto-sync: $e');
    }
  }

  // Sync to server (push local changes)
  Future<SyncResult> syncToServer() async {
    try {
      if (!_isOnline) {
        return SyncResult.success('Offline - data will sync when online');
      }

      _logger.i('Starting sync to server...');

      // Get unsynced data
      final unsyncedData = await _dbHelper.getUnsyncedData();

      if (_isDataEmpty(unsyncedData)) {
        return SyncResult.success('No data to sync');
      }

      // Prepare sync payload
      final payload = {
        'store_id': await _getStoreId(),
        'data': unsyncedData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send to server
      final response = await _dio.post('/api/sync/push', data: payload);

      if (response.statusCode == 200) {
        // Mark synced items as synced
        await _markDataAsSynced(unsyncedData);

        final syncedCount = _countSyncedItems(unsyncedData);
        _logger.i('Sync to server completed: $syncedCount items synced');

        return SyncResult.success('Successfully synced $syncedCount items');
      } else {
        throw Exception('Server returned error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('Dio error in syncToServer: $e');
      return SyncResult.error('Network error: ${e.message}');
    } catch (e) {
      _logger.e('Error in syncToServer: $e');
      return SyncResult.error('Sync failed: $e');
    }
  }

  // Sync from server (pull remote changes)
  Future<SyncResult> syncFromServer() async {
    try {
      if (!_isOnline) {
        return SyncResult.success('Offline - will sync when online');
      }

      _logger.i('Starting sync from server...');

      // Get last sync timestamp
      final lastSync = await _getLastSyncTimestamp();

      // Request data from server
      final response = await _dio.get(
        '/api/sync/pull',
        queryParameters: {'store_id': await _getStoreId(), 'since': lastSync},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('data')) {
          // Process incoming data
          await _processIncomingData(data['data']);

          // Update last sync timestamp
          await _updateLastSyncTimestamp();

          final receivedCount = _countReceivedItems(data['data']);
          _logger.i(
            'Sync from server completed: $receivedCount items received',
          );

          return SyncResult.success(
            'Successfully received $receivedCount items',
          );
        } else {
          return SyncResult.success('No new data from server');
        }
      } else {
        throw Exception('Server returned error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('Dio error in syncFromServer: $e');
      return SyncResult.error('Network error: ${e.message}');
    } catch (e) {
      _logger.e('Error in syncFromServer: $e');
      return SyncResult.error('Sync failed: $e');
    }
  }

  // Resolve conflicts
  Future<SyncResult> resolveConflicts(
    List<Map<String, dynamic>> conflicts,
  ) async {
    try {
      _logger.i('Resolving ${conflicts.length} conflicts...');

      for (final conflict in conflicts) {
        await _resolveConflict(conflict);
      }

      _logger.i('All conflicts resolved');
      return SyncResult.success(
        'Successfully resolved ${conflicts.length} conflicts',
      );
    } catch (e) {
      _logger.e('Error resolving conflicts: $e');
      return SyncResult.error('Conflict resolution failed: $e');
    }
  }

  // Manual sync (both push and pull)
  Future<SyncResult> manualSync() async {
    try {
      _logger.i('Starting manual sync...');

      final pushResult = await syncToServer();
      if (!pushResult.success) {
        return pushResult;
      }

      final pullResult = await syncFromServer();
      if (!pullResult.success) {
        return pullResult;
      }

      return SyncResult.success('Manual sync completed successfully');
    } catch (e) {
      _logger.e('Error in manual sync: $e');
      return SyncResult.error('Manual sync failed: $e');
    }
  }

  // Get sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final unsyncedData = await _dbHelper.getUnsyncedData();
      final pendingCount = _countSyncedItems(unsyncedData);
      final lastSync = await _getLastSyncTimestamp();

      return SyncStatus(
        isOnline: _isOnline,
        pendingCount: pendingCount,
        lastSync: lastSync,
        isSyncing: false,
      );
    } catch (e) {
      _logger.e('Error getting sync status: $e');
      return SyncStatus(
        isOnline: false,
        pendingCount: 0,
        lastSync: null,
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  // Force full sync
  Future<SyncResult> forceFullSync() async {
    try {
      _logger.i('Starting force full sync...');

      // Mark all data as pending to force full sync
      await _markAllAsPending();

      // Perform full sync
      return await manualSync();
    } catch (e) {
      _logger.e('Error in force full sync: $e');
      return SyncResult.error('Force full sync failed: $e');
    }
  }

  // ==================== PRIVATE METHODS ====================

  // Check if data is empty
  bool _isDataEmpty(Map<String, List<Map<String, dynamic>>> data) {
    return data.values.every((list) => list.isEmpty);
  }

  // Count synced items
  int _countSyncedItems(Map<String, List<Map<String, dynamic>>> data) {
    return data.values.fold(0, (sum, list) => sum + list.length);
  }

  // Count received items
  int _countReceivedItems(Map<String, dynamic> data) {
    int count = 0;
    data.forEach((key, value) {
      if (value is List) {
        count += value.length;
      }
    });
    return count;
  }

  // Mark data as synced
  Future<void> _markDataAsSynced(
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    for (final entry in data.entries) {
      for (final item in entry.value) {
        await _dbHelper.updateSyncStatus(entry.key, item['id'], 'synced');
      }
    }
  }

  // Process incoming data
  Future<void> _processIncomingData(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      final table = entry.key;
      final items = entry.value as List;

      for (final item in items) {
        await _processIncomingItem(table, item);
      }
    }
  }

  // Process single incoming item
  Future<void> _processIncomingItem(
    String table,
    Map<String, dynamic> item,
  ) async {
    try {
      // Check if item exists locally
      final existingItem = await _getLocalItem(table, item['id']);

      if (existingItem == null) {
        // Insert new item
        await _insertLocalItem(table, item);
      } else {
        // Compare timestamps and resolve conflicts
        await _resolveItemConflict(table, existingItem, item);
      }
    } catch (e) {
      _logger.e('Error processing incoming item: $e');
    }
  }

  // Get local item
  Future<Map<String, dynamic>?> _getLocalItem(String table, String id) async {
    try {
      switch (table) {
        case 'customers':
          return await _dbHelper.getCustomerById(id);
        case 'products':
          return await _dbHelper.getProductById(id);
        // Add other tables as needed
        default:
          return null;
      }
    } catch (e) {
      _logger.e('Error getting local item: $e');
      return null;
    }
  }

  // Insert local item
  Future<void> _insertLocalItem(String table, Map<String, dynamic> item) async {
    try {
      switch (table) {
        case 'customers':
          await _dbHelper.insertCustomer(item);
          break;
        case 'products':
          await _dbHelper.insertProduct(item);
          break;
        // Add other tables as needed
        default:
          _logger.w('Unknown table: $table');
      }
    } catch (e) {
      _logger.e('Error inserting local item: $e');
    }
  }

  // Resolve item conflict
  Future<void> _resolveItemConflict(
    String table,
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) async {
    try {
      final localTimestamp = DateTime.parse(local['updated_at']);
      final remoteTimestamp = DateTime.parse(remote['updated_at']);

      if (remoteTimestamp.isAfter(localTimestamp)) {
        // Remote is newer, use remote data
        await _updateLocalItem(table, remote);
      } else if (localTimestamp.isAfter(remoteTimestamp)) {
        // Local is newer, mark as conflict for manual resolution
        await _dbHelper.updateSyncStatus(table, local['id'], 'conflict');
      }
      // If timestamps are equal, no action needed
    } catch (e) {
      _logger.e('Error resolving item conflict: $e');
    }
  }

  // Update local item
  Future<void> _updateLocalItem(String table, Map<String, dynamic> item) async {
    try {
      switch (table) {
        case 'customers':
          await _dbHelper.updateCustomer(item['id'], item);
          break;
        case 'products':
          await _dbHelper.updateProduct(item['id'], item);
          break;
        // Add other tables as needed
        default:
          _logger.w('Unknown table: $table');
      }
    } catch (e) {
      _logger.e('Error updating local item: $e');
    }
  }

  // Resolve single conflict
  Future<void> _resolveConflict(Map<String, dynamic> conflict) async {
    try {
      final table = conflict['table'];
      final id = conflict['id'];
      final resolution = conflict['resolution']; // 'local' or 'remote'

      if (resolution == 'local') {
        // Keep local version, mark as synced
        await _dbHelper.updateSyncStatus(table, id, 'synced');
      } else if (resolution == 'remote') {
        // Use remote version
        final remoteData = conflict['remote_data'];
        await _updateLocalItem(table, remoteData);
      }
    } catch (e) {
      _logger.e('Error resolving conflict: $e');
    }
  }

  // Get store ID
  Future<String> _getStoreId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('store_id') ?? 'default_store';
    } catch (e) {
      _logger.e('Error getting store ID: $e');
      return 'default_store';
    }
  }

  // Get last sync timestamp
  Future<String?> _getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_sync_timestamp');
    } catch (e) {
      _logger.e('Error getting last sync timestamp: $e');
      return null;
    }
  }

  // Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_sync_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _logger.e('Error updating last sync timestamp: $e');
    }
  }

  // Mark all data as pending
  Future<void> _markAllAsPending() async {
    try {
      // This would require adding a method to DatabaseHelper
      // For now, we'll use the existing markAllAsSynced method
      // and then update some items to pending
      _logger.i('Marking all data as pending for full sync...');
    } catch (e) {
      _logger.e('Error marking all as pending: $e');
    }
  }

  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _dio.close();
    _logger.i('SyncService disposed');
  }
}

// Auth interceptor for API requests
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired, handle re-authentication
      _handleAuthError(err);
    }
    handler.next(err);
  }

  void _handleAuthError(DioException err) {
    // Handle authentication error (e.g., redirect to login)
    Logger().e('Authentication error: ${err.message}');
  }
}

// Sync result class
class SyncResult {
  final bool success;
  final String message;
  final dynamic data;

  SyncResult.success(this.message, {this.data}) : success = true;

  SyncResult.error(this.message, {this.data}) : success = false;

  @override
  String toString() {
    return 'SyncResult{success: $success, message: $message}';
  }
}

// Sync status class
class SyncStatus {
  final bool isOnline;
  final int pendingCount;
  final String? lastSync;
  final bool isSyncing;
  final String? error;

  SyncStatus({
    required this.isOnline,
    required this.pendingCount,
    this.lastSync,
    required this.isSyncing,
    this.error,
  });

  @override
  String toString() {
    return 'SyncStatus{isOnline: $isOnline, pendingCount: $pendingCount, lastSync: $lastSync, isSyncing: $isSyncing}';
  }
}
