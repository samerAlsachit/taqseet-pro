import '../config/app_config.dart';

/// API Endpoints - نقاط نهاية الـ API
/// 
/// جميع روابط الـ API محددة هنا
/// لتغيير الـ IP، عدل ملف [core/config/app_config.dart]
class ApiEndpoints {
  ApiEndpoints._();

  // ============================================
  // Auth Endpoints - المصادقة
  // ============================================
  
  static String get login => '${AppConfig.API_URL}/auth/login';
  static String get register => '${AppConfig.API_URL}/auth/register';
  static String get logout => '${AppConfig.API_URL}/auth/logout';
  static String get refreshToken => '${AppConfig.API_URL}/auth/refresh';

  // ============================================
  // Customer Endpoints - العملاء
  // ============================================
  
  static String get customers => '${AppConfig.API_URL}/customers';
  static String customerById(String id) => '${AppConfig.API_URL}/customers/$id';

  // ============================================
  // Installment Plan Endpoints - خطط التقسيط
  // ============================================
  
  static String get installmentPlans => '${AppConfig.API_URL}/installment-plans';
  static String installmentPlanById(String id) => '${AppConfig.API_URL}/installment-plans/$id';
  static String installmentPlansByCustomer(String customerId) => 
      '${AppConfig.API_URL}/installment-plans?customer_id=$customerId';

  // ============================================
  // Payment Schedule Endpoints - جدول الدفعات
  // ============================================
  
  static String get paymentSchedule => '${AppConfig.API_URL}/payment-schedule';
  static String paymentScheduleByPlan(String planId) => 
      '${AppConfig.API_URL}/payment-schedule/plan/$planId';
  static String paymentScheduleByCustomer(String customerId) => 
      '${AppConfig.API_URL}/payment-schedule?customer_id=$customerId';

  // ============================================
  // Payment Endpoints - المدفوعات
  // ============================================
  
  static String get payments => '${AppConfig.API_URL}/payments';
  static String paymentById(String id) => '${AppConfig.API_URL}/payments/$id';
  static String paymentsByPlan(String planId) => 
      '${AppConfig.API_URL}/payments?plan_id=$planId';
  static String paymentsBySchedule(String scheduleId) => 
      '${AppConfig.API_URL}/payments?schedule_id=$scheduleId';

  // ============================================
  // Sync Endpoints - المزامنة
  // ============================================
  
  static String get sync => '${AppConfig.API_URL}/sync';
  static String get syncPull => '${AppConfig.API_URL}/sync/pull';
  static String get syncPush => '${AppConfig.API_URL}/sync/push';
  
  /// مزامنة جدول معين
  static String syncTable(String tableName) => 
      '${AppConfig.API_URL}/sync/$tableName';

  // ============================================
  // Helper Methods
  // ============================================
  
  /// بناء رابط مخصص
  static String build(String path) => AppConfig.buildUrl(path);
  
  /// بناء رابط مع query parameters
  static String buildWithQuery(String path, Map<String, String> params) {
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '${AppConfig.buildUrl(path)}?$queryString';
  }
}
