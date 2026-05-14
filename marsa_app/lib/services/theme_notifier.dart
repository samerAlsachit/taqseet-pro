import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier instance = ThemeNotifier._();
  ThemeNotifier._();

  static const _key = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> init() async {
    final stored = await _storage.read(key: _key);
    _mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: _key, value: _mode.name);
    notifyListeners();
  }
}
