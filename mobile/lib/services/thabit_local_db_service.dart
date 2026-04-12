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
  static const String _appSettingsBoxName = 'app_settings';
  static const String _incrementalSyncKey = 'last_incremental_sync';

  Box<Map>? _installmentPlansBox;
  Box<Map>? _paymentScheduleBox;
  Box<Map>? _paymentsBox;
  Box? _appSettingsBox;

  static final ThabitLocalDBService _instance = ThabitLocalDBService._internal();
  factory ThabitLocalDBService() => _instance;
  ThabitLocalDBService._internal();

  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _installmentPlansBox = await Hive.openBox<Map>(_installmentPlansBoxName);
    _paymentScheduleBox = await Hive.openBox<Map>(_paymentScheduleBoxName);
    _paymentsBox = await Hive.openBox<Map>(_paymentsBoxName);
    _appSettingsBox = await Hive.openBox(_appSettingsBoxName);
  }

  // ============================================
  // Cache Management - إدارة الذاكرة المؤقتة
  // ============================================

  /// Clear all boxes (for complete reset)
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    print('🗑️ ThabitLocalDB: Clearing all cache...');
    await _installmentPlansBox!.clear();
    await _paymentScheduleBox!.clear();
    await _paymentsBox!.clear();
    
    // Clear sync timestamps
    for (final table in ['installment_plans', 'payment_schedule', 'payments']) {
      await _appSettingsBox!.delete('${_incrementalSyncKey}_$table');
    }
    print('✅ ThabitLocalDB: All cache cleared');
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
  Future<int> batchSaveInstallmentPlans(List<InstallmentPlanModel> plans) async {
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
        .map((data) => InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data)))
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
      final planCustomerId = (data['customer_id'] ?? data['customerId'] ?? '').toString();
      return planCustomerId == customerId;
    }).toList();
    
    print('✅ ThabitLocalDB: Found ${matching.length} matching plans');
    
    return matching
        .map((data) => InstallmentPlanModel.fromJSON(Map<String, dynamic>.from(data)))
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
  Future<int> batchSavePaymentSchedules(List<PaymentScheduleModel> schedules) async {
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
      final schedulePlanId = (data['installment_plan_id'] ?? 
                            data['installmentPlanId'] ?? '').toString();
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
        .map((data) => PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Get all payment schedules for a customer (across all plans)
  List<PaymentScheduleModel> getPaymentScheduleByCustomer(String customerId) {
    _ensureInitializedSync();
    if (_paymentScheduleBox == null || _installmentPlansBox == null) return [];
    
    print('🔍 ThabitLocalDB: Searching schedules for customer: $customerId');
    
    // First get all plans for this customer
    final planIds = getInstallmentPlansByCustomer(customerId)
        .map((p) => p.id)
        .toSet();
    
    if (planIds.isEmpty) {
      print('⚠️ ThabitLocalDB: No plans found for customer');
      return [];
    }
    
    // Get schedules for all these plans
    final allSchedules = _paymentScheduleBox!.values.toList();
    final matching = allSchedules.where((data) {
      final schedulePlanId = (data['installment_plan_id'] ?? 
                            data['installmentPlanId'] ?? '').toString();
      return planIds.contains(schedulePlanId);
    }).toList();
    
    print('✅ ThabitLocalDB: Found ${matching.length} schedules for customer');
    
    return matching
        .map((data) => PaymentScheduleModel.fromJSON(Map<String, dynamic>.from(data)))
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
      final paymentPlanId = (data['installment_plan_id'] ?? 
                           data['installmentPlanId'] ?? '').toString();
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
      final paymentScheduleId = (data['payment_schedule_id'] ?? 
                               data['paymentScheduleId'] ?? '').toString();
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
  Future<Map<String, dynamic>?> getCustomerStatementData(String customerId) async {
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
    final totalFinanced = plans.fold<int>(0, (sum, p) => sum + p.financedAmount);
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

  /// Close all boxes
  Future<void> close() async {
    await _installmentPlansBox?.close();
    await _paymentScheduleBox?.close();
    await _paymentsBox?.close();
    await _appSettingsBox?.close();
  }
}
