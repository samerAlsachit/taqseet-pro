import '../config/app_config.dart';

/// API Configuration matching the Web App
class ApiConstants {
  // Base URL - Using AppConfig for dynamic configuration
  static String get baseUrl => AppConfig.API_BASE_URL;
  static String get apiVersion => 'v1';
  static String get apiBaseUrl => AppConfig.API_URL;

  // Supabase Configuration - Using AppConfig
  static String get supabaseUrl => AppConfig.SUPABASE_URL;
  static String get supabaseAnonKey => AppConfig.SUPABASE_ANON_KEY;

  // Storage Buckets
  static const String customersBucket = 'customers';
  static const String avatarsFolder = 'avatars';
  static const String documentsFolder = 'documents';

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';

  // Customer Endpoints
  static const String customers = '/customers';
  static const String customerById = '/customers/{id}';

  // Product Endpoints
  static const String products = '/products';
  static const String productById = '/products/{id}';

  // Installment Endpoints
  static const String installments = '/installments';
  static const String installmentById = '/installments/{id}';
  static const String payments = '/payments';

  // Cash Sales Endpoints
  static const String cashSales = '/cash-sales';

  // Dashboard & Stats
  static const String dashboard = '/dashboard';
  static const String stats = '/dashboard/stats';

  // Sync Endpoints
  static const String sync = '/sync';
  static const String syncPull = '/sync/pull';
  static const String syncPush = '/sync/push';

  // Timeout durations
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
