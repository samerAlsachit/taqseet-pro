import 'package:hive_flutter/hive_flutter.dart';
import '../models/installment_plan_model.dart';
import '../models/payment_schedule_model.dart';
import '../models/payment_model.dart';

/// Thabit Local Database Service - خدمة قاعدة البيانات المحلية لنظام ثبات
/// تدير ثلاثة صناديق منفصلة للجداول الأساسية:
/// - installment_plans: خطط التقسيط
/// - payment_schedule: جدول الدفعات (يحتوي على due_date)
/// - payments: المدفوعات الفعلية
class ThabitLocalDBService {
  static const String _installmentPlansBoxName = 'installment_plans';
  static const String _paymentScheduleBoxName = 'payment_schedule';
  static const String _paymentsBoxName = 'payments';
  static const String _customersBoxName = 'customers';
  static const String _productsBoxName = 'products';
  static const String _appSettingsBoxName = 'app_settings';
  static const String _incrementalSyncKey = 'last_incremental_sync';
  static const String _firstLoginKey = 'first_login_completed';

  Box<Map>? _installmentPlansBox;
  Box<Map>? _paymentScheduleBox;
  Box<Map>? _paymentsBox;
  Box<Map>? _customersBox;
  Box<Map>? _productsBox;
  Box? _appSettingsBox;

  static final ThabitLocalDBService _instance =
      ThabitLocalDBService._internal();
  factory ThabitLocalDBService() => _instance;
  ThabitLocalDBService._internal();

  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _installmentPlansBox = await Hive.openBox<Map>(_installmentPlansBoxName);
    _paymentScheduleBox = await Hive.openBox<Map>(_paymentScheduleBoxName);
    _paymentsBox = await Hive.openBox<Map>(_paymentsBoxName);
    _customersBox = await Hive.openBox<Map>(_customersBoxName);
    _productsBox = await Hive.openBox<Map>(_productsBoxName);
    _appSettingsBox = await Hive.openBox(_appSettingsBoxName);
  }

  // ============================================
  // Cache Management - إدارة الذاكرة المؤقتة
  // ============================================

  /// Clear all boxes (for complete reset)
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    print('🗑️ ThabitLocalDB: Wiping ALL local data...');
    await _installmentPlansBox!.clear();
    await _paymentScheduleBox!.clear();
    await _paymentsBox!.clear();
    await _customersBox!.clear();
    await _productsBox!.clear();

    // Clear sync timestamps
    for (final table in [
      'installment_plans',
      'payment_schedule',
      'payments',
      'customers',
      'products',
    ]) {
      await _appSettingsBox!.delete('${_incrementalSyncKey}_$table');
    }
    print('✅ ThabitLocalDB: All local data wiped clean');
  }

  /// Wipe all data and mark as first login (for fresh start)
  Future<void> wipeAllDataAndMarkFirstLogin() async {
    await clearAllCache();
    await _appSettingsBox!.delete(_firstLoginKey);
    print('🗑️ ThabitLocalDB: Data wiped and marked as first login');
  }

  /// Check if this is first login
  bool isFirstLogin() {
    _ensureInitializedSync();
    return !(_appSettingsBox!.get(_firstLoginKey) ?? false);
  }

  /// Mark first login as complete
  Future<void> markFirstLoginComplete() async {
    await _ensureInitialized();
    await _appSettingsBox!.put(_firstLoginKey, true);
    print('✅ ThabitLocalDB: First login marked complete');
  }

  /// Clear specific table cache
  Future<void> clearTableCache(String tableName) async {
    await _ensureInitialized();
    print('🗑️ ThabitLocalDB: Clearing $tableName cache...');

    switch (tableName) {
      case 'installment_plans':
        await _installmentPlansBox!.clear();
        break;
      case 'payment_schedule':
        await _paymentScheduleBox!.clear();
        break;
      case 'payments':
        await _paymentsBox!.clear();
        break;
      case 'customers':
        await _customersBox!.clear();
        break;
      case 'products':
        await _productsBox!.clear();
        break;
    }
    await _appSettingsBox!.delete('${_incrementalSyncKey}_$tableName');
    print('✅ ThabitLocalDB: $tableName cache cleared');
  }

  // ============================================
  // Installment Plans - خطط التقسيط
  // ============================================

  /// Save installment plan to local storage
  Future<void> saveInstallmentPlan(InstallmentPlanModel plan) async {
    await _ensureInitialized();
    final data = plan.toJSON();
    await _installmentPlansBox!.put(plan.id, data);
  }

  /// Batch save installment plans (for sync)
  Future<int> batchSaveInstallmentPlans(
    List<InstallmentPlanModel> plans,
  ) async {
    await _ensureInitialized();
    int count = 0;
    for (final plan in plans) {
      await _installmentPlansBox!.put(plan.id, plan.toJSON());
      count++;
    }
    return count;
  }

  /// Get all installment plans
  List<InstallmentPlanModel> getAllInstallmentPlans() {
    _ensureInitializedSync();
    if (_installmentPlansBox == null) return [];

    return _installmentPlansBox!.values
        .map(
          (data) =>
              InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data)),
        )
        .toList();
  }

  /// Get installment plans by customer ID
  List<InstallmentPlanModel> getInstallmentPlansByCustomer(String customerId) {
    _ensureInitializedSync();
    if (_installmentPlansBox == null) return [];

    print('🔍 ThabitLocalDB: Searching plans for customer: $customerId');

    final allPlans = _installmentPlansBox!.values.toList();
    print('📦 ThabitLocalDB: Total plans in box: ${allPlans.length}');

    final matching = allPlans.where((data) {
      final planCustomerId = (data['customer_id'] ?? data['customerId'] ?? '')
          .toString();
      return planCustomerId == customerId;
    }).toList();

    print('✅ ThabitLocalDB: Found ${matching.length} matching plans');

    return matching
        .map(
          (data) =>
              InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data)),
        )
        .toList();
  }

  /// Get single installment plan by ID
  InstallmentPlanModel? getInstallmentPlanById(String planId) {
    _ensureInitializedSync();
    if (_installmentPlansBox == null) return null;

    final data = _installmentPlansBox!.get(planId);
    if (data == null) return null;

    return InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data));
  }

  // ============================================
  // Payment Schedule - جدول الدفعات
  // ============================================

  /// Save payment schedule to local storage
  Future<void> savePaymentSchedule(PaymentScheduleModel schedule) async {
    await _ensureInitialized();
    final data = schedule.toJSON();
    await _paymentScheduleBox!.put(schedule.id, data);
  }

  /// Batch save payment schedules (for sync)
  Future<int> batchSavePaymentSchedules(
    List<PaymentScheduleModel> schedules,
  ) async {
    await _ensureInitialized();
    int count = 0;
    for (final schedule in schedules) {
      await _paymentScheduleBox!.put(schedule.id, schedule.toJSON());
      count++;
    }
    return count;
  }

  /// Get payment schedule by installment plan ID
  /// هذا هو العمود due_date الصحيح
  List<PaymentScheduleModel> getPaymentScheduleByPlan(String planId) {
    _ensureInitializedSync();
    if (_paymentScheduleBox == null) return [];

    print('🔍 ThabitLocalDB: Searching payment schedule for plan: $planId');

    final allSchedules = _paymentScheduleBox!.values.toList();
    print('📦 ThabitLocalDB: Total schedules in box: ${allSchedules.length}');

    final matching = allSchedules.where((data) {
      final schedulePlanId =
          (data['installment_plan_id'] ?? data['installmentPlanId'] ?? '')
              .toString();
      return schedulePlanId == planId;
    }).toList();

    // Sort by installment number
    matching.sort((a, b) {
      final aNo = (a['installment_no'] ?? a['installmentNo'] ?? 0) as int;
      final bNo = (b['installment_no'] ?? b['installmentNo'] ?? 0) as int;
      return aNo.compareTo(bNo);
    });

    print('✅ ThabitLocalDB: Found ${matching.length} matching schedules');

    return matching
        .map(
          (data) =>
              PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data)),
        )
        .toList();
  }

  /// Get all payment schedules for a customer (across all plans)
  List<PaymentScheduleModel> getPaymentScheduleByCustomer(String customerId) {
    _ensureInitializedSync();
    if (_paymentScheduleBox == null || _installmentPlansBox == null) return [];

    print('🔍 ThabitLocalDB: Searching schedules for customer: $customerId');

    // First get all plans for this customer
    final planIds = getInstallmentPlansByCustomer(
      customerId,
    ).map((p) => p.id).toSet();

    if (planIds.isEmpty) {
      print('⚠️ ThabitLocalDB: No plans found for customer');
      return [];
    }

    // Get schedules for all these plans
    final allSchedules = _paymentScheduleBox!.values.toList();
    final matching = allSchedules.where((data) {
      final schedulePlanId =
          (data['installment_plan_id'] ?? data['installmentPlanId'] ?? '')
              .toString();
      return planIds.contains(schedulePlanId);
    }).toList();

    print('✅ ThabitLocalDB: Found ${matching.length} schedules for customer');

    return matching
        .map(
          (data) =>
              PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data)),
        )
        .toList();
  }

  // ============================================
  // Payments - المدفوعات
  // ============================================

  /// Save payment to local storage
  Future<void> savePayment(PaymentModel payment) async {
    await _ensureInitialized();
    final data = payment.toJSON();
    await _paymentsBox!.put(payment.id, data);
  }

  /// Batch save payments (for sync)
  Future<int> batchSavePayments(List<PaymentModel> payments) async {
    await _ensureInitialized();
    int count = 0;
    for (final payment in payments) {
      await _paymentsBox!.put(payment.id, payment.toJSON());
      count++;
    }
    return count;
  }

  /// Get payments by installment plan ID
  List<PaymentModel> getPaymentsByPlan(String planId) {
    _ensureInitializedSync();
    if (_paymentsBox == null) return [];

    final allPayments = _paymentsBox!.values.toList();
    final matching = allPayments.where((data) {
      final paymentPlanId =
          (data['installment_plan_id'] ?? data['installmentPlanId'] ?? '')
              .toString();
      return paymentPlanId == planId;
    }).toList();

    return matching
        .map((data) => PaymentModel.fromJSON(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Get payments by payment schedule ID
  List<PaymentModel> getPaymentsBySchedule(String scheduleId) {
    _ensureInitializedSync();
    if (_paymentsBox == null) return [];

    final allPayments = _paymentsBox!.values.toList();
    final matching = allPayments.where((data) {
      final paymentScheduleId =
          (data['payment_schedule_id'] ?? data['paymentScheduleId'] ?? '')
              .toString();
      return paymentScheduleId == scheduleId;
    }).toList();

    return matching
        .map((data) => PaymentModel.fromJSON(Map<String, dynamic>.from(data)))
        .toList();
  }

  // ============================================
  // Customer Statement - كشف حساب العميل
  // ============================================

  /// Get complete customer statement data from local DB
  Future<Map<String, dynamic>?> getCustomerStatementData(
    String customerId,
  ) async {
    await _ensureInitialized();

    print('📊 ThabitLocalDB: Getting statement data for customer: $customerId');

    // 1. Get all installment plans for customer
    final plans = getInstallmentPlansByCustomer(customerId);
    if (plans.isEmpty) {
      print('⚠️ ThabitLocalDB: No plans found for customer');
      return null;
    }

    // 2. Get payment schedules for all plans
    List<PaymentScheduleModel> allSchedules = [];
    for (final plan in plans) {
      final schedules = getPaymentScheduleByPlan(plan.id);
      allSchedules.addAll(schedules);
    }

    // 3. Get payments for all plans
    List<PaymentModel> allPayments = [];
    for (final plan in plans) {
      final payments = getPaymentsByPlan(plan.id);
      allPayments.addAll(payments);
    }

    // 4. Calculate totals
    final totalFinanced = plans.fold<int>(
      0,
      (sum, p) => sum + p.financedAmount,
    );
    final totalPaid = allPayments.fold<int>(0, (sum, p) => sum + p.amountPaid);
    final totalRemaining = totalFinanced - totalPaid;

    print('✅ ThabitLocalDB: Statement data ready');
    print('   Plans: ${plans.length}');
    print('   Schedules: ${allSchedules.length}');
    print('   Payments: ${allPayments.length}');
    print('   Total Financed: $totalFinanced');
    print('   Total Paid: $totalPaid');
    print('   Remaining: $totalRemaining');

    return {
      'plans': plans,
      'schedules': allSchedules,
      'payments': allPayments,
      'totalFinanced': totalFinanced,
      'totalPaid': totalPaid,
      'totalRemaining': totalRemaining,
    };
  }

  // ============================================
  // Incremental Sync - المزامنة التراكمية
  // ============================================

  /// Get last incremental sync timestamp for a specific table
  DateTime? getLastIncrementalSyncTime(String tableName) {
    _ensureInitializedSync();
    final key = '${_incrementalSyncKey}_$tableName';
    final timestamp = _appSettingsBox?.get(key);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  /// Update last incremental sync timestamp for a specific table
  Future<void> updateLastIncrementalSyncTime(String tableName) async {
    await _ensureInitialized();
    final key = '${_incrementalSyncKey}_$tableName';
    await _appSettingsBox!.put(key, DateTime.now().toIso8601String());
  }

  // ============================================
  // Private Helpers
  // ============================================

  Future<void> _ensureInitialized() async {
    if (_installmentPlansBox == null || !_installmentPlansBox!.isOpen) {
      await init();
    }
  }

  void _ensureInitializedSync() {
    if (_installmentPlansBox == null || !_installmentPlansBox!.isOpen) {
      return;
    }
  }

  // ============================================
  // Customers - العملاء
  // ============================================

  /// Save customer to local storage
  Future<void> saveCustomer(Map<String, dynamic> customer) async {
    await _ensureInitialized();
    final id = customer['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      await _customersBox!.put(id, customer);
    }
  }

  /// Batch save customers (for sync)
  Future<int> batchSaveCustomers(List<Map<String, dynamic>> customers) async {
    await _ensureInitialized();
    int count = 0;
    for (final customer in customers) {
      final id = customer['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await _customersBox!.put(id, customer);
        count++;
      }
    }
    return count;
  }

  /// ✅ Full Sync Customers - مزامنة كاملة للعملاء
  /// تحفظ العملاء القادمين من السيرفر وتزيل العملاء المحليين غير الموجودين في السيرفر
  Future<Map<String, int>> syncCustomersFull(
    List<Map<String, dynamic>> remoteCustomers,
  ) async {
    await _ensureInitialized();

    // 1. استخراج IDs القادمة من السيرفر
    final remoteIds = remoteCustomers
        .map((c) => c['id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    // 2. الحصول على جميع المفاتيح المحلية
    final localKeys = _customersBox!.keys.toList();
    final localIds = localKeys.map((k) => k.toString()).toSet();

    // 3. تحديد العملاء المحذوفين (موجودون محلياً وغير موجودين في السيرفر)
    final deletedIds = localIds.where((id) => !remoteIds.contains(id)).toList();

    // 4. حذف العملاء المحذوفين
    int deletedCount = 0;
    for (final id in deletedIds) {
      await _customersBox!.delete(id);
      deletedCount++;
    }

    // 5. حفظ العملاء القادمين من السيرفر
    int savedCount = 0;
    for (final customer in remoteCustomers) {
      final id = customer['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await _customersBox!.put(id, customer);
        savedCount++;
      }
    }

    print(
      '🗑️ [FULL SYNC] Deleted $deletedCount local customers not in server',
    );
    print('✅ [FULL SYNC] Saved $savedCount remote customers');

    return {'saved': savedCount, 'deleted': deletedCount};
  }

  /// Get all customers
  List<Map<String, dynamic>> getAllCustomers() {
    _ensureInitializedSync();
    if (_customersBox == null) return [];

    return _customersBox!.values
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  /// Get customer by ID
  Map<String, dynamic>? getCustomerById(String id) {
    _ensureInitializedSync();
    if (_customersBox == null) return null;

    final data = _customersBox!.get(id);
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  /// Delete customer by ID
  Future<void> deleteCustomer(String id) async {
    await _ensureInitialized();
    await _customersBox!.delete(id);
  }

  // ============================================
  // Products - المنتجات
  // ============================================

  /// Save product to local storage
  Future<void> saveProduct(Map<String, dynamic> product) async {
    await _ensureInitialized();
    final id = product['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      await _productsBox!.put(id, product);
    }
  }

  /// Batch save products (for sync)
  Future<int> batchSaveProducts(List<Map<String, dynamic>> products) async {
    await _ensureInitialized();
    int count = 0;
    for (final product in products) {
      final id = product['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await _productsBox!.put(id, product);
        count++;
      }
    }
    return count;
  }

  /// Clear all products and save new ones (atomic operation)
  Future<int> clearAndSaveProducts(List<Map<String, dynamic>> products) async {
    await _ensureInitialized();
    // Clear existing products
    await _productsBox!.clear();
    // Add all new products
    int count = 0;
    for (final product in products) {
      final id = product['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await _productsBox!.put(id, product);
        count++;
      }
    }
    print('✅ ThabitLocalDB: Cleared and saved $count products');
    return count;
  }

  /// Get all products
  List<Map<String, dynamic>> getAllProducts() {
    _ensureInitializedSync();
    if (_productsBox == null) return [];

    return _productsBox!.values
        .map((data) => Map<String, dynamic>.from(data))
        .toList();
  }

  /// Get product by ID
  Map<String, dynamic>? getProductById(String id) {
    _ensureInitializedSync();
    if (_productsBox == null) return null;

    final data = _productsBox!.get(id);
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  /// Get products box for ValueListenableBuilder
  Box<Map>? get productsBox => _productsBox;

  /// Get low stock products
  List<Map<String, dynamic>> getLowStockProducts() {
    _ensureInitializedSync();
    if (_productsBox == null) return [];

    return _productsBox!.values
        .map((data) => Map<String, dynamic>.from(data))
        .where(
          (p) =>
              (p['quantity'] as int? ?? 0) <=
              (p['low_stock_alert'] as int? ?? 5),
        )
        .toList();
  }

  /// Delete product by ID
  Future<void> deleteProduct(String id) async {
    await _ensureInitialized();
    await _productsBox!.delete(id);
  }

  /// Close all boxes
  Future<void> close() async {
    await _installmentPlansBox?.close();
    await _paymentScheduleBox?.close();
    await _paymentsBox?.close();
    await _customersBox?.close();
    await _productsBox?.close();
    await _appSettingsBox?.close();
  }
}
