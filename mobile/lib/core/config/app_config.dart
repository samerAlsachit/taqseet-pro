import 'package:flutter/foundation.dart';

/// App Configuration - إعدادات التطبيق
///
/// هذا هو الملف المركزي لجميع إعدادات الـ API.
/// قم بتغيير قيمة [API_BASE_URL] هنا فقط عند الانتقال لجهاز آخر.
///
/// طريقة الاستخدام:
/// ```dart
/// import 'core/config/app_config.dart';
///
/// final url = AppConfig.API_BASE_URL;
/// ```
class AppConfig {
  AppConfig._();

  // ============================================
  // 🔧 قم بتغيير الـ IP هنا فقط
  // ============================================

  /// IP Address الخاص بك
  /// غيّر هذا حسب جهازك:
  ///
  /// للابتوب 1 (الأساسي): '192.168.1.100'
  /// للابتوب 2: '192.168.1.101'
  /// للمحاكي: '10.0.2.2'
  /// للإنتاج: 'your-domain.com'
  ///
  static const String API_IP = '192.168.0.196';

  /// Port الخادم
  static const String API_PORT = '3000';

  /// الرابط الكامل للـ API
  static const String API_BASE_URL = 'http://$API_IP:$API_PORT';

  /// بادئة الـ API
  static const String API_VERSION = '/api';

  /// الرابط الكامل مع البادئة
  static const String API_URL = '$API_BASE_URL$API_VERSION';

  // ============================================
  // Supabase Settings (إذا كنت تستخدم Supabase)
  // ============================================

  /// Supabase URL - اتركه فارغاً إذا كنت تستخدم خادمك المحلي
  static const String SUPABASE_URL = '';

  /// Supabase Anon Key
  static const String SUPABASE_ANON_KEY = '';

  // ============================================
  // App Settings
  // ============================================

  /// App Name
  static const String APP_NAME = 'مرساة';

  /// App Version
  static const String APP_VERSION = '1.0.0';

  /// Debug Mode
  static const bool DEBUG_MODE = kDebugMode;

  // ============================================
  // Helper Methods
  // ============================================

  /// بناء رابط كامل من مسار
  ///
  /// مثال:
  /// ```dart
  /// final url = AppConfig.buildUrl('/customers/123');
  /// // النتيجة: http://192.168.1.100:3000/api/v1/customers/123
  /// ```
  static String buildUrl(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$API_URL$cleanPath';
  }

  /// بناء رابط صورة كامل
  static String buildImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$API_BASE_URL$cleanPath';
  }

  /// التحقق من إعدادات الـ API
  static bool get isSupabaseMode => SUPABASE_URL.isNotEmpty;

  /// طباعة معلومات الـ API (للتصحيح)
  static void printConfig() {
    if (DEBUG_MODE) {
      print('🔧 AppConfig:');
      print('   API_IP: $API_IP');
      print('   API_PORT: $API_PORT');
      print('   API_BASE_URL: $API_BASE_URL');
      print('   API_URL: $API_URL');
      print('   Supabase Mode: $isSupabaseMode');
    }
  }
}
