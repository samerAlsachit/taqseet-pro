import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';
import '../models/installment_model.dart';

/// Pull Sync Service - خدمة السحب والمزامنة التراكمية
///
/// تدير جلب البيانات الجديدة من Supabase بشكل تراكمي
/// بناءً على timestamp آخر مزامنة
class PullSyncService {
  static final PullSyncService _instance = PullSyncService._internal();
  factory PullSyncService() => _instance;
  PullSyncService._internal();

  final LocalDBService _localDB = LocalDBService();
  SupabaseClient? _supabase;

  // Callbacks for UI notifications
  void Function(String message)? onPullSuccess;
  void Function(String message)? onPullError;

  /// Supported tables for incremental sync
  static const List<String> _syncTables = [
    'installment_plans',
    'customers',
    'products',
    'payments',
  ];

  /// Initialize the service
  Future<void> init() async {
    await _localDB.init();
    _supabase = Supabase.instance.client;
  }

  /// ============================================
  /// Incremental Pull - الجلب التراكمي
  /// ============================================

  /// Fetch latest data from all tables since last sync
  /// الجلب التراكمي من جميع الجداول
  Future<PullSyncResult> fetchLatestData() async {
    if (!await _isOnline()) {
      return PullSyncResult.offline();
    }

    int totalNewRecords = 0;
    Map<String, int> tableResults = {};

    try {
      // Sync each table
      for (final tableName in _syncTables) {
        final result = await _fetchTableData(tableName);
        tableResults[tableName] = result;
        totalNewRecords += result;
      }

      // Show notification if there are new records
      if (totalNewRecords > 0) {
        onPullSuccess?.call('تم تحديث $totalNewRecords سجلات جديدة');
      }

      return PullSyncResult.success(
        totalRecords: totalNewRecords,
        tableResults: tableResults,
      );
    } catch (e) {
      onPullError?.call('فشل تحديث البيانات: ${e.toString()}');
      return PullSyncResult.error(e.toString());
    }
  }

  /// Fetch data for a specific table since last sync
  Future<int> _fetchTableData(String tableName) async {
    // 1. Get last sync timestamp for this table
    final lastSync = _localDB.getLastIncrementalSyncTime(tableName);

    // 2. Execute query with appropriate filter
    final List<dynamic> records;
    if (lastSync != null) {
      // Filter for records updated after last sync
      final response = await _supabase!
          .from(tableName)
          .select()
          .gt('updated_at', lastSync.toIso8601String());
      records = response as List<dynamic>;
    } else {
      // First sync - get recent records with limit
      final response = await _supabase!.from(tableName).select().limit(1000);
      records = response as List<dynamic>;
    }

    if (records.isEmpty) {
      // Update timestamp even if no new records
      await _localDB.updateLastIncrementalSyncTime(tableName);
      return 0;
    }

    // 4. Process and upsert records based on table type
    int count = 0;

    switch (tableName) {
      case 'installment_plans':
        count = await _processInstallments(records);
        break;
      case 'customers':
        count = await _processCustomers(records);
        break;
      case 'products':
        count = await _processProducts(records);
        break;
      case 'payments':
        count = await _processPayments(records);
        break;
    }

    // 5. Update last sync timestamp
    await _localDB.updateLastIncrementalSyncTime(tableName);

    return count;
  }

  /// Process installments records
  Future<int> _processInstallments(List<dynamic> records) async {
    final installments = records.map((data) {
      return InstallmentModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();

    return await _localDB.batchUpsertFromServer(installments);
  }

  /// Process customers records (placeholder for future)
  Future<int> _processCustomers(List<dynamic> records) async {
    // TODO: Implement when CustomerModel is available
    // For now, just count the records
    return records.length;
  }

  /// Process products records (placeholder for future)
  Future<int> _processProducts(List<dynamic> records) async {
    // TODO: Implement when ProductModel is available
    return records.length;
  }

  /// Process payments records (placeholder for future)
  Future<int> _processPayments(List<dynamic> records) async {
    // TODO: Implement when PaymentModel is available
    return records.length;
  }

  /// ============================================
  /// Background Sync - المزامنة في الخلفية
  /// ============================================

  /// Setup app lifecycle monitoring for background sync
  void setupAppLifecycleMonitoring(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - trigger sync
        _triggerBackgroundSync();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background - nothing to do
        break;
    }
  }

  /// Trigger background sync when app resumes
  Future<void> _triggerBackgroundSync() async {
    // Small delay to let UI settle
    await Future.delayed(const Duration(seconds: 1));

    if (await _isOnline()) {
      await fetchLatestData();
    }
  }

  /// Start periodic background sync (optional)
  Timer? _periodicTimer;

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) async {
      if (await _isOnline()) {
        await fetchLatestData();
      }
    });
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// ============================================
  /// Helpers - دوال مساعدة
  /// ============================================

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// Get last sync info for all tables
  Map<String, DateTime?> getLastSyncInfo() {
    final Map<String, DateTime?> info = {};
    for (final table in _syncTables) {
      info[table] = _localDB.getLastIncrementalSyncTime(table);
    }
    return info;
  }

  /// Dispose
  void dispose() {
    stopPeriodicSync();
  }
}

/// ============================================
/// Pull Sync Result - نتيجة المزامنة
/// ============================================

class PullSyncResult {
  final bool success;
  final int totalRecords;
  final Map<String, int> tableResults;
  final String? error;
  final DateTime timestamp;
  final bool isOffline;

  PullSyncResult({
    required this.success,
    required this.totalRecords,
    this.tableResults = const {},
    this.error,
    this.isOffline = false,
  }) : timestamp = DateTime.now();

  PullSyncResult.success({
    required int totalRecords,
    Map<String, int> tableResults = const {},
  }) : success = true,
       totalRecords = totalRecords,
       tableResults = tableResults,
       error = null,
       isOffline = false,
       timestamp = DateTime.now();

  PullSyncResult.offline()
    : success = false,
      totalRecords = 0,
      tableResults = const {},
      error = 'Offline',
      isOffline = true,
      timestamp = DateTime.now();

  PullSyncResult.error(String message)
    : success = false,
      totalRecords = 0,
      tableResults = const {},
      error = message,
      isOffline = false,
      timestamp = DateTime.now();

  bool get hasNewRecords => totalRecords > 0;
}
