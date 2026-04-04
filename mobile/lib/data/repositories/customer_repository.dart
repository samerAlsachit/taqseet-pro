import '../models/customer.dart';
import '../../core/database/database_helper.dart';

class CustomerRepository {
  final DatabaseHelper _databaseHelper;

  CustomerRepository(this._databaseHelper);

  Future<List<Customer>> getCustomers() async {
    final customers = await _databaseHelper.getAllCustomers();
    return customers.map((customer) => Customer.fromMap(customer)).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final customer = await _databaseHelper.getCustomerById(id);
    return customer != null ? Customer.fromMap(customer) : null;
  }

  Future<String> addCustomer(Customer customer) async {
    return await _databaseHelper.insertCustomer(customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    return await _databaseHelper.updateCustomer(customer.id!, customer.toMap());
  }

  Future<int> deleteCustomer(String id) async {
    return await _databaseHelper.deleteCustomer(id);
  }

  Future<List<Customer>> searchCustomers(String query, String storeId) async {
    final customers = await _databaseHelper.searchCustomers(query, storeId);
    return customers.map((customer) => Customer.fromMap(customer)).toList();
  }

  Future<List<Customer>> getCustomersByStore(String storeId) async {
    final customers = await _databaseHelper.getAllCustomers();
    return customers
        .where((customer) => customer['store_id'] == storeId)
        .map((customer) => Customer.fromMap(customer))
        .toList();
  }
}
