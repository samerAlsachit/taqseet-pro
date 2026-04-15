import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import 'thabit_local_db_service.dart';
import 'api_client.dart';
import 'product_service.dart';
import '../models/installment_plan_model.dart';
import '../models/payment_schedule_model.dart';
import '../models/payment_model.dart';

/// Marsa Sync Service - خدمة مزامنة مرساة
/// تجلب البيانات من Node.js API عبر HTTP بدلاً من Supabase
/// - installment_plans (بدون due_date)
/// - payment_schedule (يحتوي على due_date)
/// - payments (المدفوعات الفعلية)
class MarsaSyncService {
  static final MarsaSyncService _instance = MarsaSyncService._internal();
  factory MarsaSyncService() => _instance;
  MarsaSyncService._internal();

  final ThabitLocalDBService _localDB = ThabitLocalDBService();
  final ApiClient _apiClient = ApiClient();
  final ProductService _productService = ProductService();
  Dio? _dio;

  // Callbacks for UI notifications
  void Function(String message)? onPullSuccess;
  void Function(String message)? onPullError;

  /// Endpoint mapping: Mobile app names → Server API names
  static const Map<String, String> _tableEndpoints = {
    'installment_plans': '/installments',
    'payment_schedule': '/payment-schedule',
    'payments': '/payments',
    'customers': '/customers',
    'products': '/products',
  };

  /// Initialize the service
  /// Wipes data on first login to ensure fresh start
  Future<void> init() async {
    await _localDB.init();
    _apiClient.init();
    _dio = _apiClient.dio;

    // Check if this is first login and wipe old data
    if (_localDB.isFirstLogin()) {
      print('🗑️ MarsaSyncService: First login detected - wiping old data...');
      await _localDB.wipeAllDataAndMarkFirstLogin();
    }

    print('✅ MarsaSyncService: Initialized with ApiClient (auto-token)');
  }

  /// ============================================
  /// Main Fetch Method - جلب البيانات الرئيسي
  /// ============================================

  /// Fetch latest data from all tables with cache clearing
  /// الجلب الكامل مع مسح الذاكرة المؤقتة أولاً (افتراضياً true للحصول على بيانات جديدة)
  Future<MarsaSyncResult> fetchLatestData({bool clearCache = true}) async {
    if (!await _isOnline()) {
      return MarsaSyncResult.offline();
    }

    if (_dio == null) {
      return MarsaSyncResult.error(
        'Service not initialized. Call init() first.',
      );
    }

    try {
      // 1. Clear cache if requested (لتجنب تضارب البيانات)
      if (clearCache) {
        print('🗑️ MarsaSyncService: Clearing cache before fetch...');
        await _localDB.clearAllCache();
      }

      int totalNewRecords = 0;
      Map<String, int> tableResults = {};

      // 2. Fetch via new sync endpoint (single call to /api/sync)
      final syncResult = await fetchSync(clearCache: clearCache);
      if (syncResult.success) {
        totalNewRecords = syncResult.totalRecords;
        tableResults = syncResult.tableResults;
      }

      // 3. Sync products separately via ProductService
      final productResult = await _productService.syncProducts();
      if (productResult.success) {
        tableResults['products'] = productResult.count;
        totalNewRecords += productResult.count;
      }

      // 4. Show notification if there are new records
      if (totalNewRecords > 0) {
        onPullSuccess?.call('تم تحديث $totalNewRecords سجلات جديدة');
      }

      return MarsaSyncResult.success(
        totalRecords: totalNewRecords,
        tableResults: tableResults,
      );
    } catch (e, stackTrace) {
      print('❌ MarsaSyncService Error: $e');
      print('Stack trace: $stackTrace');
      onPullError?.call('فشل تحديث البيانات: ${e.toString()}');
      return MarsaSyncResult.error(e.toString());
    }
  }

  /// ============================================
  /// Table-Specific Fetch - جلب حسب الجدول
  /// ============================================

  /// Fetch all data in one request to /api/sync endpoint
  Future<MarsaSyncResult> fetchSync({bool clearCache = true}) async {
    if (!await _isOnline()) {
      return MarsaSyncResult.offline();
    }

    if (_dio == null) {
      return MarsaSyncResult.error(
        'Service not initialized. Call init() first.',
      );
    }

    try {
      // Clear cache if requested
      if (clearCache) {
        print('🗑️ MarsaSyncService: Clearing cache before fetch...');
        await _localDB.clearAllCache();
      }

      final fullUrl = '${AppConfig.API_URL}/sync/pull';
      print('🔄 MarsaSyncService: Calling GET $fullUrl');

      final response = await _dio!.get('/sync/pull');

      if (response.statusCode != 200) {
        print('⚠️ MarsaSyncService: HTTP ${response.statusCode}');
        return MarsaSyncResult.error('HTTP ${response.statusCode}');
      }

      // Parse response
      final responseData = response.data;
      Map<String, dynamic> syncData;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        syncData = responseData['data'] as Map<String, dynamic>;
      } else {
        print('⚠️ MarsaSyncService: Unexpected response format');
        return MarsaSyncResult.error('Invalid response format');
      }

      int totalCount = 0;
      Map<String, int> tableResults = {};

      // Process each table
      // Try multiple field name formats for compatibility
      final customersData = syncData['customers'] ?? syncData['customers'];
      final installmentsData =
          syncData['installments'] ?? syncData['installment_plans'];
      final paymentsData = syncData['payments'] ?? syncData['payments'];
      final schedulesData =
          syncData['payment_schedule'] ??
          syncData['schedules'] ??
          syncData['payment_schedules'];
      final productsData = syncData['products'] ?? syncData['products'];

      // Process customers
      if (customersData != null && customersData is List) {
        final count = await _processCustomers(customersData);
        tableResults['customers'] = count;
        totalCount += count;
        await _localDB.updateLastIncrementalSyncTime('customers');
      }

      // Process installments (maps to installment_plans in local DB)
      if (installmentsData != null && installmentsData is List) {
        final count = await _processInstallmentPlans(installmentsData);
        tableResults['installment_plans'] = count;
        totalCount += count;
        await _localDB.updateLastIncrementalSyncTime('installment_plans');
      }

      // Process payment schedules
      if (schedulesData != null && schedulesData is List) {
        final count = await _processPaymentSchedule(schedulesData);
        tableResults['payment_schedule'] = count;
        totalCount += count;
        await _localDB.updateLastIncrementalSyncTime('payment_schedule');
      }

      // Process payments
      if (paymentsData != null && paymentsData is List) {
        final count = await _processPayments(paymentsData);
        tableResults['payments'] = count;
        totalCount += count;
        await _localDB.updateLastIncrementalSyncTime('payments');
      }

      // Process products
      if (productsData != null && productsData is List) {
        final count = await _processProducts(productsData);
        tableResults['products'] = count;
        totalCount += count;
        await _localDB.updateLastIncrementalSyncTime('products');
      }

      print('📥 MarsaSyncService: Sync completed. Total: $totalCount records');

      if (totalCount > 0) {
        onPullSuccess?.call('تم تحديث $totalCount سجلات جديدة');
      }

      return MarsaSyncResult.success(
        totalRecords: totalCount,
        tableResults: tableResults,
      );
    } on DioException catch (e) {
      print('❌ MarsaSyncService DioException: ${e.message}');
      if (e.response != null) {
        print('   Status: ${e.response?.statusCode}');
        print('   Data: ${e.response?.data}');
      }
      return MarsaSyncResult.error('Network error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ MarsaSyncService Error: $e');
      print('Stack trace: $stackTrace');
      return MarsaSyncResult.error(e.toString());
    }
  }

  /// ============================================
  /// Process Records - معالجة السجلات
  /// ============================================

  Future<int> _processInstallmentPlans(List<dynamic> records) async {
    final plans = records.map((data) {
      return InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();
    return await _localDB.batchSaveInstallmentPlans(plans);
  }

  Future<int> _processPaymentSchedule(List<dynamic> records) async {
    final schedules = records.map((data) {
      return PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();
    return await _localDB.batchSavePaymentSchedules(schedules);
  }

  Future<int> _processPayments(List<dynamic> records) async {
    final payments = records.map((data) {
      return PaymentModel.fromJSON(Map<String, dynamic>.from(data));
    }).toList();
    return await _localDB.batchSavePayments(payments);
  }

  Future<int> _processCustomers(List<dynamic> records) async {
    final customers = records.map((data) {
      return Map<String, dynamic>.from(data);
    }).toList();
    return await _localDB.batchSaveCustomers(customers);
  }

  /// ============================================
  /// Customer Data Fetch - جلب بيانات العميل
  /// ============================================

  /// Fetch all data for a specific customer (for statement)
  Future<bool> fetchCustomerData(String customerId) async {
    if (!await _isOnline()) return false;
    if (_dio == null) return false;

    try {
      print('🔍 MarsaSyncService: Fetching data for customer: $customerId');

      // 1. Fetch installment plans for this customer
      final plansResponse = await _dio!.get(
        '/installment-plans',
        queryParameters: {'customer_id': customerId},
      );

      List<dynamic> plansData;
      if (plansResponse.data is Map && plansResponse.data['data'] != null) {
        plansData = plansResponse.data['data'];
      } else if (plansResponse.data is List) {
        plansData = plansResponse.data;
      } else {
        plansData = [];
      }

      final plans = plansData.map((data) {
        return InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data));
      }).toList();

      await _localDB.batchSaveInstallmentPlans(plans);
      print('✅ Saved ${plans.length} installment plans');

      if (plans.isEmpty) {
        print('⚠️ MarsaSyncService: No plans found for customer');
        return false;
      }

      // 2. Fetch payment schedules for all plans
      final planIds = plans.map((p) => p.id).toList();

      // Try to fetch by plan IDs
      final schedulesResponse = await _dio!.get(
        '/payment-schedule',
        queryParameters: {'plan_ids': planIds.join(',')},
      );

      List<dynamic> schedulesData;
      if (schedulesResponse.data is Map &&
          schedulesResponse.data['data'] != null) {
        schedulesData = schedulesResponse.data['data'];
      } else if (schedulesResponse.data is List) {
        schedulesData = schedulesResponse.data;
      } else {
        schedulesData = [];
      }

      final schedules = schedulesData.map((data) {
        return PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data));
      }).toList();

      await _localDB.batchSavePaymentSchedules(schedules);
      print('✅ Saved ${schedules.length} payment schedules');

      // 3. Fetch payments for all plans
      final paymentsResponse = await _dio!.get(
        '/payments',
        queryParameters: {'plan_ids': planIds.join(',')},
      );

      List<dynamic> paymentsData;
      if (paymentsResponse.data is Map &&
          paymentsResponse.data['data'] != null) {
        paymentsData = paymentsResponse.data['data'];
      } else if (paymentsResponse.data is List) {
        paymentsData = paymentsResponse.data;
      } else {
        paymentsData = [];
      }

      final payments = paymentsData.map((data) {
        return PaymentModel.fromJSON(Map<String, dynamic>.from(data));
      }).toList();

      await _localDB.batchSavePayments(payments);
      print('✅ Saved ${payments.length} payments');

      return true;
    } on DioException catch (e) {
      print('❌ MarsaSyncService DioException: ${e.message}');
      return false;
    } catch (e) {
      print('❌ MarsaSyncService Error: $e');
      return false;
    }
  }

  /// Process products from API response
  Future<int> _processProducts(List<dynamic> productsData) async {
    try {
      final products = productsData
          .map((json) => json as Map<String, dynamic>)
          .toList();

      final count = await _localDB.batchSaveProducts(products);
      print('✅ Saved $count products');

      return count;
    } catch (e) {
      print('❌ MarsaSyncService Error processing products: $e');
      return 0;
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
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  Map<String, DateTime?> getLastSyncInfo() {
    final Map<String, DateTime?> info = {};
    for (final table in _tableEndpoints.keys) {
      info[table] = _localDB.getLastIncrementalSyncTime(table);
    }
    return info;
  }

  void dispose() {
    stopPeriodicSync();
  }
}

/// Marsa Sync Result - نتيجة المزامنة
class MarsaSyncResult {
  final bool success;
  final int totalRecords;
  final Map<String, int> tableResults;
  final String? error;
  final DateTime timestamp;
  final bool isOffline;

  MarsaSyncResult({
    required this.success,
    required this.totalRecords,
    this.tableResults = const {},
    this.error,
    this.isOffline = false,
  }) : timestamp = DateTime.now();

  MarsaSyncResult.success({
    required int totalRecords,
    Map<String, int> tableResults = const {},
  }) : success = true,
       totalRecords = totalRecords,
       tableResults = tableResults,
       error = null,
       isOffline = false,
       timestamp = DateTime.now();

  MarsaSyncResult.offline()
    : success = false,
      totalRecords = 0,
      tableResults = const {},
      error = 'Offline',
      isOffline = true,
      timestamp = DateTime.now();

  MarsaSyncResult.error(String message)
    : success = false,
      totalRecords = 0,
      tableResults = const {},
      error = message,
      isOffline = false,
      timestamp = DateTime.now();

  bool get hasNewRecords => totalRecords > 0;
}
