import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/logger/app_logger.dart';

class HiveService {
  static final HiveService _instance = HiveService._();
  factory HiveService() => _instance;
  HiveService._();

  static const String _boxName = 'marsa_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    AppLogger.info('Hive initialized');
  }

  Box get _box => Hive.box(_boxName);

  Future<void> put(String key, dynamic value) async => _box.put(key, value);
  dynamic get(String key) => _box.get(key);
  Future<void> delete(String key) async => _box.delete(key);
  Future<void> clear() async => _box.clear();

  Future<void> putList(String key, List<Map<String, dynamic>> items) async => _box.put(key, items);
  List<Map<String, dynamic>>? getList(String key) => (_box.get(key) as List?)?.cast<Map<String, dynamic>>();

  Future<void> putJson(String key, Map<String, dynamic> json) async => _box.put(key, json);
  Map<String, dynamic>? getJson(String key) => _box.get(key) as Map<String, dynamic>?;
}
