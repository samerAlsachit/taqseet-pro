import 'package:flutter/material.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _customerRepository;
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _storeId = 'default_store'; // Default store ID

  CustomerProvider(this._customerRepository);

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set store ID for filtering
  void setStoreId(String storeId) {
    _storeId = storeId;
    notifyListeners();
  }

  Future<void> loadCustomers() async {
    _setLoading(true);
    try {
      _customers = await _customerRepository.getCustomers();
      // Filter by store ID
      _customers = _customers.where((customer) => customer.storeId == _storeId).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCustomersByStore() async {
    _setLoading(true);
    try {
      _customers = await _customerRepository.getCustomersByStore(_storeId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    _setLoading(true);
    try {
      // Set store ID before adding
      customer = customer.copyWith(storeId: _storeId);
      await _customerRepository.addCustomer(customer);
      await loadCustomers(); // إعادة تحميل القائمة
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    _setLoading(true);
    try {
      await _customerRepository.updateCustomer(customer);
      await loadCustomers(); // إعادة تحميل القائمة
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCustomer(String id) async {
    _setLoading(true);
    try {
      await _customerRepository.deleteCustomer(id);
      await loadCustomers(); // إعادة تحميل القائمة
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchCustomers(String query) async {
    _setLoading(true);
    try {
      _customers = await _customerRepository.searchCustomers(query, _storeId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get customer by ID from repository
  Future<Customer?> getCustomerFromRepo(String id) async {
    try {
      return await _customerRepository.getCustomer(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh customers list
  Future<void> refresh() async {
    await loadCustomers();
  }
}
