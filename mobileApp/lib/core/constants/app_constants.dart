import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'مرساة';
  static const String appNameEn = 'Marsa';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'نظام إدارة الأقساط الذكي';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String storeKey = 'store_data';
  static const String settingsKey = 'app_settings';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String lastSyncKey = 'last_sync';
  static const String biometricEnabledKey = 'biometric_enabled';

  // Database
  static const String dbName = 'marsa_db.db';
  static const int dbVersion = 1;

  // Hive Boxes
  static const String customersBox = 'customers';
  static const String productsBox = 'products';
  static const String installmentsBox = 'installments';
  static const String paymentsBox = 'payments';
  static const String cashSalesBox = 'cash_sales';
  static const String syncQueueBox = 'sync_queue';
  static const String settingsBox = 'settings';

  // Sync Settings
  static const int syncIntervalMinutes = 5;
  static const int maxSyncRetries = 3;
  static const int batchSize = 100;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double cardElevation = 2.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Settings
  static const int maxImageSizeKB = 500;
  static const int imageQuality = 85;
  static const double maxImageWidth = 1200;
  static const double maxImageHeight = 1200;
}
