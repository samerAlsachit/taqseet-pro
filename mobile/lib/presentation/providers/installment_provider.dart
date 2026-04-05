import 'package:flutter/material.dart';
import '../../data/models/installment.dart';
import '../../data/models/payment_schedule.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/installment_repository.dart';
import '../../core/database/database_helper.dart';

class InstallmentProvider extends ChangeNotifier {
  final InstallmentRepository _installmentRepository;
  List<Installment> _installments = [];
  List<PaymentSchedule> _schedule = [];
  Installment? _selectedInstallment;
  bool _isLoading = false;
  String? _error;
  String _storeId = 'default_store';
  String _statusFilter = 'all'; // 'all', 'active', 'completed', 'overdue'

  InstallmentProvider(this._installmentRepository);

  List<Installment> get installments {
    if (_statusFilter == 'all') {
      return _installments;
    }
    return _installments
        .where((installment) => installment.status == _statusFilter)
        .toList();
  }

  List<PaymentSchedule> get schedule => _schedule;
  Installment? get selectedInstallment => _selectedInstallment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;

  // Set store ID for filtering
  void setStoreId({required String storeId}) {
    _storeId = storeId;
    notifyListeners();
  }

  // Set status filter
  void setStatusFilter({required String status}) {
    _statusFilter = status;
    notifyListeners();
  }

  // Fetch all installments with customer names
  Future<void> fetchInstallments() async {
    _setLoading(loading: true);
    try {
      final installmentsData = await _installmentRepository
          .getInstallmentsByStore(_storeId);
      final installmentsWithNames = <Installment>[];

      for (final installmentData in installmentsData) {
        // Get customer name for each installment
        final db = DatabaseHelper();
        final customerData = await db.getCustomerById(
          installmentData.customerId,
        );
        final customerName = customerData != null
            ? Customer.fromMap(customerData).fullName
            : '';

        // Create installment with customer name
        final installment = Installment(
          id: installmentData.id,
          storeId: installmentData.storeId,
          customerId: installmentData.customerId,
          productId: installmentData.productId,
          productName: installmentData.productName,
          totalPrice: installmentData.totalPrice,
          downPayment: installmentData.downPayment,
          financedAmount: installmentData.financedAmount,
          remainingAmount: installmentData.remainingAmount,
          currency: installmentData.currency,
          frequency: installmentData.frequency,
          installmentAmount: installmentData.installmentAmount,
          installmentsCount: installmentData.installmentsCount,
          startDate: installmentData.startDate,
          endDate: installmentData.endDate,
          status: installmentData.status,
          syncStatus: installmentData.syncStatus,
          createdAt: installmentData.createdAt,
          updatedAt: installmentData.updatedAt,
          customerName: customerName,
        );

        installmentsWithNames.add(installment);
      }

      _installments = installmentsWithNames;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(loading: false);
    }
  }

  // Fetch installment details with schedule
  Future<void> fetchInstallmentDetails({required String id}) async {
    _setLoading(loading: true);
    try {
      _selectedInstallment = await _installmentRepository.getById(id);
      if (_selectedInstallment != null) {
        _schedule = await _installmentRepository.getSchedule(id);

        // Get customer name using customer_id
        if (_selectedInstallment!.customerId.isNotEmpty) {
          final db = DatabaseHelper();
          final customerData = await db.getCustomerById(
            _selectedInstallment!.customerId,
          );
          if (customerData != null) {
            final customer = Customer.fromMap(customerData);
            // Update the installment with customer name
            _selectedInstallment = Installment(
              id: _selectedInstallment!.id,
              storeId: _selectedInstallment!.storeId,
              customerId: _selectedInstallment!.customerId,
              productId: _selectedInstallment!.productId,
              productName: _selectedInstallment!.productName,
              totalPrice: _selectedInstallment!.totalPrice,
              downPayment: _selectedInstallment!.downPayment,
              financedAmount: _selectedInstallment!.financedAmount,
              remainingAmount: _selectedInstallment!.remainingAmount,
              currency: _selectedInstallment!.currency,
              frequency: _selectedInstallment!.frequency,
              installmentAmount: _selectedInstallment!.installmentAmount,
              installmentsCount: _selectedInstallment!.installmentsCount,
              startDate: _selectedInstallment!.startDate,
              endDate: _selectedInstallment!.endDate,
              status: _selectedInstallment!.status,
              syncStatus: _selectedInstallment!.syncStatus,
              createdAt: _selectedInstallment!.createdAt,
              updatedAt: _selectedInstallment!.updatedAt,
              customerName: customer.fullName,
            );
          }
        }

        _error = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(loading: false);
    }
  }

  // Add new installment
  Future<void> addInstallment({required Installment installment}) async {
    _setLoading(loading: true);
    try {
      await _installmentRepository.insert(installment);
      await fetchInstallments(); // Refresh list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(loading: false);
    }
  }

  // Update existing installment
  Future<void> updateInstallment({required Installment installment}) async {
    _setLoading(loading: true);
    try {
      await _installmentRepository.update(installment);
      await fetchInstallments(); // Refresh list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(loading: false);
    }
  }

  // Delete installment
  Future<void> deleteInstallment({required String id}) async {
    _setLoading(loading: true);
    try {
      await _installmentRepository.delete(id);
      await fetchInstallments(); // Refresh list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(loading: false);
    }
  }

  // Make payment for a schedule
  Future<void> makePayment({
    required String scheduleId,
    required int amount,
  }) async {
    _setLoading(loading: true);
    try {
      await _installmentRepository.makePayment(scheduleId, amount);

      // Refresh selected installment details if available
      if (_selectedInstallment != null) {
        await fetchInstallmentDetails(id: _selectedInstallment!.id!);
      }

      // Refresh installments list
      await fetchInstallments();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(loading: false);
    }
  }

  // Get installments by customer
  Future<List<Installment>> getInstallmentsByCustomer({
    required String customerId,
  }) async {
    try {
      return await _installmentRepository.getByCustomer(customerId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get installments by status
  Future<List<Installment>> getInstallmentsByStatus({
    required String status,
  }) async {
    try {
      return await _installmentRepository.getByStatus(status, _storeId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get overdue installments
  Future<List<Installment>> getOverdueInstallments() async {
    try {
      return await _installmentRepository.getOverdueInstallments(_storeId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get installment statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _installmentRepository.getStatistics(_storeId);
    } catch (e) {
      _error = e.toString();
      return {};
    }
  }

  // Get installment by ID
  Installment? getInstallmentById({required String id}) {
    try {
      return _installments.firstWhere((installment) => installment.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update payment schedule status
  Future<void> updateScheduleStatus({
    required String scheduleId,
    required String status,
  }) async {
    try {
      await _installmentRepository.updateScheduleStatus(scheduleId, status);

      // Refresh schedule if available
      if (_selectedInstallment != null) {
        await fetchInstallmentDetails(id: _selectedInstallment!.id!);
      }

      // Refresh installments list
      await fetchInstallments();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Clear selected installment
  void clearSelectedInstallment() {
    _selectedInstallment = null;
    _schedule = [];
    notifyListeners();
  }

  void _setLoading({required bool loading}) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh installments list
  Future<void> refresh() async {
    await fetchInstallments();
  }

  // Get filtered installments count
  int get filteredInstallmentsCount => installments.length;

  // Get active installments count
  int get activeInstallmentsCount =>
      _installments.where((i) => i.isActive).length;

  // Get overdue installments count
  int get overdueInstallmentsCount =>
      _installments.where((i) => i.isOverdue).length;

  // Get completed installments count
  int get completedInstallmentsCount =>
      _installments.where((i) => i.isCompleted).length;
}
