import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Open all required boxes
    await Hive.openBox(AppConstants.customersBox);
    await Hive.openBox(AppConstants.productsBox);
    await Hive.openBox(AppConstants.installmentsBox);
    await Hive.openBox(AppConstants.paymentsBox);
    await Hive.openBox(AppConstants.cashSalesBox);
    await Hive.openBox(AppConstants.syncQueueBox);
    await Hive.openBox(AppConstants.settingsBox);

    _isInitialized = true;
  }

  // Generic CRUD operations
  Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  dynamic get(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key);
  }

  Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  List<dynamic> getAll(String boxName) {
    final box = Hive.box(boxName);
    return box.values.toList();
  }

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  // Sync Queue Operations
  Future<void> addToSyncQueue(Map<String, dynamic> data) async {
    final box = Hive.box(AppConstants.syncQueueBox);
    final key = '${data['type']}_${data['id']}_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, {
      ...data,
      'synced': false,
      'retryCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> getPendingSync() {
    final box = Hive.box(AppConstants.syncQueueBox);
    return box.values
        .where((item) => item['synced'] == false)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> markAsSynced(String key) async {
    final box = Hive.box(AppConstants.syncQueueBox);
    final item = box.get(key);
    if (item != null) {
      await box.put(key, {...item, 'synced': true, 'syncedAt': DateTime.now().toIso8601String()});
    }
  }

  Future<void> incrementRetry(String key) async {
    final box = Hive.box(AppConstants.syncQueueBox);
    final item = box.get(key);
    if (item != null) {
      await box.put(key, {...item, 'retryCount': (item['retryCount'] ?? 0) + 1});
    }
  }
}
