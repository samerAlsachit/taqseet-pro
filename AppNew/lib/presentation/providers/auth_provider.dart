import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_response.dart';

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  AuthResponse? _authRes;
  bool _loading = false;
  bool _isLoggedIn = false;

  AuthResponse? get authResponse => _authRes;
  bool get loading => _loading;
  bool get isLoggedIn => _isLoggedIn;
  String get storeName => _authRes?.store.name ?? '';

  Future<void> tryAutoLogin() async {
    _loading = true;
    notifyListeners();
    _isLoggedIn = await _repo.tryAutoLogin();
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      _authRes = await _repo.login(username, password);
      _isLoggedIn = true;
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> activate(String code) async {
    _loading = true;
    notifyListeners();
    try {
      _authRes = await _repo.activate(code);
      _isLoggedIn = true;
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> registerTrial(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      _authRes = await _repo.registerTrial(data);
      _isLoggedIn = true;
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _authRes = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
