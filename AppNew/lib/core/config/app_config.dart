// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // ============================================
  // 🔧 قم بتغيير الـ IP هنا فقط
  // ============================================

  /// IP Address الخاص بك
  /// غيّر هذا حسب جهازك:
  ///
  /// للابتوب (الأساسي): '192.168.1.100'
  /// للابتوب 2: '192.168.1.101'
  /// للمحاكي: '10.0.2.2'
  /// للإنتاج: 'your-domain.com'
  ///
  static const String API_IP = '192.168.0.127';

  /// Port الخادم
  static const String API_PORT = '3000';

  /// الرابط الكامل للـ API
  static const String API_BASE_URL = 'http://$API_IP:$API_PORT';

  /// بادئة الـ API
  static const String API_VERSION = '/api';

  /// الرابط الكامل مع البادئة
  static const String API_URL = '$API_BASE_URL$API_VERSION';

  /// توافق عكسي مع الكود القديم
  static String get apiBaseUrl => API_URL;

  // ============================================
  // Supabase Settings
  // ============================================

  /// Supabase URL
  static const String SUPABASE_URL = 'https://sdygpgchcyxkgqmswgyb.supabase.co';

  /// Supabase Anon Key
  static const String SUPABASE_ANON_KEY =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkeWdwZ2NoY3l4a2dxbXN3Z3liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyODM4MTUsImV4cCI6MjA4OTg1OTgxNX0.3gsWQTejmO2YtrhB6VnSkdAp0Du3TJQAsoJiI9beVaY';

  /// Supabase Storage Bucket Name
  static const String SUPABASE_STORAGE_BUCKET = 'customers';

  /// Supabase Storage Public URL Base
  static const String SUPABASE_STORAGE_URL =
      '$SUPABASE_URL/storage/v1/object/public/$SUPABASE_STORAGE_BUCKET';

  /// توافق عكسي
  static String get supabaseUrl => SUPABASE_URL;
  static String get supabaseAnonKey => SUPABASE_ANON_KEY;

  // ============================================
  // App Settings
  // ============================================

  /// App Name
  static const String APP_NAME = 'مرساة';

  /// App Version
  static const String APP_VERSION = '1.0.0';

  /// Debug Mode
  static const bool DEBUG_MODE = kDebugMode;

  static bool get isProduction => !DEBUG_MODE;

  // ============================================
  // Helper Methods
  // ============================================

  /// بناء رابط كامل من مسار
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

  /// بناء رابط Supabase Storage كامل
  static String buildStorageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$SUPABASE_STORAGE_URL/$cleanPath';
  }

  /// بناء رابط Supabase Storage مع مجلد
  static String buildStorageUrlWithFolder(String folder, String fileName) {
    if (fileName.startsWith('http')) {
      return fileName;
    }
    final cleanFolder = folder.startsWith('/') ? folder.substring(1) : folder;
    final cleanFileName =
        fileName.startsWith('/') ? fileName.substring(1) : fileName;
    return '$SUPABASE_STORAGE_URL/$cleanFolder/$cleanFileName';
  }

  /// التحقق من إعدادات الـ API
  static bool get isSupabaseMode => SUPABASE_URL.isNotEmpty;

  /// طباعة معلومات الـ API (للتصحيح)
  static void printConfig() {
    if (DEBUG_MODE) {
      debugPrint('🔧 AppConfig:');
      debugPrint('   API_IP: $API_IP');
      debugPrint('   API_PORT: $API_PORT');
      debugPrint('   API_BASE_URL: $API_BASE_URL');
      debugPrint('   API_URL: $API_URL');
      debugPrint('   Supabase Mode: $isSupabaseMode');
    }
  }
}
