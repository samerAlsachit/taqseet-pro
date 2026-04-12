import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'thabit_local_db_service.dart';
import '../models/installment_plan_model.dart';
import '../models/payment_schedule_model.dart';
import '../models/payment_model.dart';

/// Thabit Pull Sync Service - خدمة سحب البيانات لنظام ثبات
/// تجلب البيانات من ثلاثة جداول منفصلة:
/// - installment_plans (بدون due_date)
/// - payment_schedule (يحتوي على due_date)
/// - payments (المدفوعات الفعلية)
class ThabitPullSyncService {
  static final ThabitPullSyncService _instance = ThabitPullSyncService._internal();
  factory ThabitPullSyncService() => _instance;
  ThabitPullSyncService._internal();

  final ThabitLocalDBService _localDB = ThabitLocalDBService();
  SupabaseClient? _supabase;

  // Callbacks for UI notifications
  void Function(String message)? onPullSuccess;
  void Function(String message)? onPullError;

  /// Supported tables for incremental sync
  static const List<String> _syncTables = [
    'installment_plans',
    'payment_schedule',
    'payments',
    'customers',
  ];

  /// Initialize the service
  Future<void> init() async {
    await _localDB.init();
    _supabase = Supabase.instance.client;
  }

  /// ============================================
  /// Main Fetch Method - جلب البيانات الرئيسي
  /// ============================================

  /// Fetch latest data from all tables with cache clearing
  /// الجلب الكامل مع مسح الذاكرة المؤقتة أولاً
  Future<ThabitPullSyncResult> fetchLatestData({bool clearCache = false}) async {
    if (!await _isOnline()) {
      return ThabitPullSyncResult.offline();
    }

    try {
      // 1. Clear cache if requested (لتجنب تضارب البيانات)
      if (clearCache) {
        print('🗑️ ThabitPullSync: Clearing cache before fetch...');
        await _localDB.clearAllCache();
      }

      int totalNewRecords = 0;
      Map<String, int> tableResults = {};

      // 2. Fetch each table separately
      for (final tableName in _syncTables) {
        final result = await _fetchTableData(tableName);
        tableResults[tableName] = result;
        totalNewRecords += result;
      }

      // 3. Show notification if there are new records
      if (totalNewRecords > 0) {
        onPullSuccess?.call('تم تحديث $totalNewRecords سجلات جديدة');
      }

      return ThabitPullSyncResult.success(
        totalRecords: totalNewRecords,
        tableResults: tableResults,
      );
    } catch (e, stackTrace) {
      print('❌ ThabitPullSync Error: $e');
      print('Stack trace: $stackTrace');
      onPullError?.call('فشل تحديث البيانات: ${e.toString()}');
      return ThabitPullSyncResult.error(e.toString());
    }
  }

  /// ============================================
  /// Table-Specific Fetch - جلب حسب الجدول
  /// ============================================

  /// Fetch data for a specific table since last sync
  Future<int> _fetchTableData(String tableName) async {
    // 1. Get last sync timestamp for this table
    final lastSync = _localDB.getLastIncrementalSyncTime(tableName);

    print('🔄 ThabitPullSync: Fetching $tableName (since: $lastSync)');

    // 2. Execute query with appropriate filter
    final List<dynamic> records;
    try {
      if (lastSync != null) {
        // Incremental sync - get records updated after last sync
        final response = await _supabase!
            .from(tableName)
            .select()
            .gt('updated_at', lastSync.toIso8601String());
        records = response as List<dynamic>;
      } else {
        // First sync - get all records with limit
        final response = await _supabase!
            .from(tableName)
            .select()
            .limit(1000);
        records = response as List<dynamic>;
      }
    } catch (e) {
      print('❌ ThabitPullSync Error fetching $tableName: $e');
      // If column error, return 0
      if (e.toString().contains('column') || e.toString().contains('field')) {
        print('⚠️ ThabitPullSync: Column error in $tableName - check schema');
      }
      return 0;
    }

    print('📥 ThabitPullSync: Fetched ${records.length} records from $tableName');

    if (records.isEmpty) {
      // Update timestamp even if no new records
      await _localDB.updateLastIncrementalSyncTime(tableName);
      return 0;
    }

    // 3. Process records based on table type
    int count = 0;
    switch (tableName) {
      case 'installment_plans':
        count = await _processInstallmentPlans(records);
        break;
      case 'payment_schedule':
        count = await _processPaymentSchedule(records);
        break;
      case 'payments':
        count = await _processPayments(records);
        break;
      case 'customers':
        count = records.length; // TODO: Implement when CustomerModel is ready
        break;
    }

    // 4. Update last sync timestamp
    await _localDB.updateLastIncrementalSyncTime(tableName);

    print('✅ ThabitPullSync: Saved $count records to local DB');
    return count;
  }

  /// Process installment plans records
  /// مهم: installment_plans لا يحتوي على due_date
  Future<int> _processInstallmentPlans(List<dynamic> records) async {
    final plans = records.map((data) {
      return InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();

    return await _localDB.batchSaveInstallmentPlans(plans);
  }

  /// Process payment schedule records
  /// مهم: payment_schedule هو الذي يحتوي على due_date
  Future<int> _processPaymentSchedule(List<dynamic> records) async {
    final schedules = records.map((data) {
      return PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();

    return await _localDB.batchSavePaymentSchedules(schedules);
  }

  /// Process payments records
  Future<int> _processPayments(List<dynamic> records) async {
    final payments = records.map((data) {
      return PaymentModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();

    return await _localDB.batchSavePayments(payments);
  }

  /// ============================================
  /// Customer Data Fetch - جلب بيانات العميل
  /// ============================================

  /// Fetch all data for a specific customer (for statement)
  Future<bool> fetchCustomerData(String customerId) async {
    if (!await _isOnline()) return false;

    try {
      print('🔍 ThabitPullSync: Fetching data for customer: $customerId');

      // 1. Fetch installment plans for this customer
      final plansResponse = await _supabase!
          .from('installment_plans')
          .select('*, customers(full_name, phone, national_id, address)')
          .eq('customer_id', customerId);

      final plans = plansResponse.map((data) {
        final customerData = data['customers'] as Map<String, dynamic>?;
        if (customerData != null) {
          data['customer_name'] = customerData['full_name'];
        }
        return InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data));
      }).toList();

      await _localDB.batchSaveInstallmentPlans(plans);
      print('✅ Saved ${plans.length} installment plans');

      if (plans.isEmpty) {
        print('⚠️ ThabitPullSync: No plans found for customer');
        return false;
      }

      // 2. Fetch payment schedules for all plans
      final planIds = plans.map((p) => p.id).toList();
      final schedulesResponse = await _supabase!
          .from('payment_schedule')
          .select()
          .inFilter('installment_plan_id', planIds);

      final schedules = schedulesResponse.map((data) {
        return PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data));
      }).toList();

      await _localDB.batchSavePaymentSchedules(schedules);
      print('✅ Saved ${schedules.length} payment schedules');

      // 3. Fetch payments for all plans
      final paymentsResponse = await _supabase!
          .from('payments')
          .select()
          .inFilter('installment_plan_id', planIds);

      final payments = paymentsResponse.map((data) {
        return PaymentModel.fromJSON(Map<String, dynamic>.from(data));
      }).toList();

      await _localDB.batchSavePayments(payments);
      print('✅ Saved ${payments.length} payments');

      return true;
    } catch (e) {
      print('❌ ThabitPullSync Error fetching customer data: $e');
      return false;
    }
  }

  /// ============================================
  /// Background Sync - المزامنة في الخلفية
  /// ============================================

  void setupAppLifecycleMonitoring(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _triggerBackgroundSync();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _triggerBackgroundSync() async {
    await Future.delayed(const Duration(seconds: 1));
    if (await _isOnline()) {
      await fetchLatestData();
    }
  }

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
      (r) => r == ConnectivityResult.wifi ||
             r == ConnectivityResult.mobile ||
             r == ConnectivityResult.ethernet,
    );
  }

  Map<String, DateTime?> getLastSyncInfo() {
    final Map<String, DateTime?> info = {};
    for (final table in _syncTables) {
      info[table] = _localDB.getLastIncrementalSyncTime(table);
    }
    return info;
  }

  void dispose() {
    stopPeriodicSync();
  }
}

/// Pull Sync Result - نتيجة المزامنة
class ThabitPullSyncResult {
  final bool success;
  final int totalRecords;
  final Map<String, int> tableResults;
  final String? error;
  final DateTime timestamp;
  final bool isOffline;

  ThabitPullSyncResult({
    required this.success,
    required this.totalRecords,
    this.tableResults = const {},
    this.error,
    this.isOffline = false,
  }) : timestamp = DateTime.now();

  ThabitPullSyncResult.success({
    required int totalRecords,
    Map<String, int> tableResults = const {},
  }) : success = true,
       totalRecords = totalRecords,
       tableResults = tableResults,
       error = null,
       isOffline = false,
       timestamp = DateTime.now();

  ThabitPullSyncResult.offline()
    : success = false,
      totalRecords = 0,
      tableResults = const {},
      error = 'Offline',
      isOffline = true,
       timestamp = DateTime.now();

  ThabitPullSyncResult.error(String message)
    : success = false,
      totalRecords = 0,
       tableResults = const {},
      error = message,
      isOffline = false,
      timestamp = DateTime.now();

  bool get hasNewRecords => totalRecords > 0;
}
