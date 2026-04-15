/// API Constants - ثوابت الـ API
///
/// هذا الملف المركزي لإعدادات الـ API
/// قم بتغيير الـ IP_ADDRESS هنا فقط عند الانتقال لجهاز آخر
class ApiConstants {
  ApiConstants._(); // Prevent instantiation

  // ============================================
  // Server Configuration - إعدادات الخادم
  // ============================================

  /// IP Address - قم بتغيير هذا فقط
  /// Laptop 1 (Default): '192.168.1.100'
  /// Laptop 2: '192.168.1.101'
  /// Emulator: '10.0.2.2'
  static const String IP_ADDRESS = '192.168.0.158';

  /// Server Port
  static const String PORT = '3000';

  /// Base API URL
  static const String BASE_URL = 'http://$IP_ADDRESS:$PORT';

  /// API Version Prefix
  static const String API_PREFIX = '/api/v1';

  /// Full API Base URL
  static const String API_BASE_URL = '$BASE_URL$API_PREFIX';

  // ============================================
  // API Endpoints - نقاط النهاية
  // ============================================

  /// Auth Endpoints
  static const String LOGIN = '$API_BASE_URL/auth/login';
  static const String REGISTER = '$API_BASE_URL/auth/register';
  static const String LOGOUT = '$API_BASE_URL/auth/logout';
  static const String REFRESH_TOKEN = '$API_BASE_URL/auth/refresh';

  /// Customer Endpoints
  static const String CUSTOMERS = '$API_BASE_URL/customers';
  static const String CUSTOMER_BY_ID = '$API_BASE_URL/customers/{id}';

  /// Installment Endpoints
  static const String INSTALLMENT_PLANS = '$API_BASE_URL/installment-plans';
  static const String INSTALLMENT_PLAN_BY_ID =
      '$API_BASE_URL/installment-plans/{id}';

  /// Payment Schedule Endpoints
  static const String PAYMENT_SCHEDULE = '$API_BASE_URL/payment-schedule';
  static const String PAYMENT_SCHEDULE_BY_PLAN =
      '$API_BASE_URL/payment-schedule/plan/{planId}';

  /// Payment Endpoints
  static const String PAYMENTS = '$API_BASE_URL/payments';
  static const String PAYMENT_BY_ID = '$API_BASE_URL/payments/{id}';

  /// Sync Endpoints
  static const String SYNC = '$API_BASE_URL/sync';
  static const String SYNC_PULL = '$API_BASE_URL/sync/pull';
  static const String SYNC_PUSH = '$API_BASE_URL/sync/push';

  // ============================================
  // Supabase Configuration (Alternative)
  // ============================================

  /// Supabase URL (if using Supabase instead of local server)
  static const String SUPABASE_URL = 'https://your-project.supabase.co';

  /// Supabase Anon Key
  static const String SUPABASE_ANON_KEY = 'your-anon-key-here';

  // ============================================
  // Helper Methods
  // ============================================

  /// Build URL with path parameters
  ///
  /// Example: ApiConstants.buildUrl(ApiConstants.CUSTOMER_BY_ID, {'id': '123'})
  /// Result: http://192.168.1.100:3000/api/v1/customers/123
  static String buildUrl(String urlTemplate, Map<String, String> params) {
    String result = urlTemplate;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Get full image URL
  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return '$BASE_URL$imagePath';
  }
}
