import 'package:flutter/material.dart';
import '../models/installment_model.dart';
import '../core/utils/formatter.dart';
import '../services/thabit_local_db_service.dart';

class InstallmentProvider with ChangeNotifier {
  List<InstallmentModel> _installments = [];
  bool _isLoading = false;
  String? _error;
  final ThabitLocalDBService _localDB = ThabitLocalDBService();

  List<InstallmentModel> get installments => _installments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  InstallmentProvider() {
    loadInstallments();
  }

  /// Load installments from local Hive database
  Future<void> loadInstallments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Initialize local DB if needed
      await _localDB.init();

      // Load from local Hive storage
      final plans = _localDB.getAllInstallmentPlans();
      
      // Convert InstallmentPlanModel to InstallmentModel
      _installments = plans.map((plan) => InstallmentModel(
        id: plan.id,
        customerName: plan.customerName ?? 'عميل غير معروف',
        totalAmount: plan.totalPrice.toDouble(),
        paidAmount: plan.downPayment.toDouble(),
        remainingAmount: plan.remainingAmount.toDouble(),
        dueDate: plan.endDate,
        status: plan.status == 'active' ? 'pending' : plan.status,
      )).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'فشل في تحميل البيانات: $e';
      notifyListeners();
    }
  }

  /// Check if local data is empty
  bool get isEmpty => _installments.isEmpty;

  Future<void> addInstallment(InstallmentModel installment) async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      _installments.insert(0, installment);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'فشل في إضافة القسط: $e';
      notifyListeners();
    }
  }

  Future<void> updateInstallment(InstallmentModel updatedInstallment) async {
    try {
      final index = _installments.indexWhere(
        (item) => item.id == updatedInstallment.id,
      );
      if (index != -1) {
        _installments[index] = updatedInstallment;
        notifyListeners();
      }
    } catch (e) {
      _error = 'فشل في تحديث القسط: $e';
      notifyListeners();
    }
  }

  Future<void> deleteInstallment(String id) async {
    try {
      _installments.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'فشل في حذف القسط: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Statistics
  double get totalAmount =>
      _installments.fold(0.0, (sum, item) => sum + item.totalAmount);
  double get totalPaid =>
      _installments.fold(0.0, (sum, item) => sum + item.paidAmount);
  double get totalRemaining =>
      _installments.fold(0.0, (sum, item) => sum + item.remainingAmount);
  int get completedCount =>
      _installments.where((item) => item.isCompleted).length;
  int get pendingCount => _installments.where((item) => item.isPending).length;
  int get overdueCount => _installments.where((item) => item.isOverdue).length;

  // Dashboard specific methods
  double get todayCollected {
    final today = DateTime.now();
    return _installments
        .where(
          (i) =>
              i.status == 'completed' &&
              i.dueDate.day == today.day &&
              i.dueDate.month == today.month &&
              i.dueDate.year == today.year,
        )
        .fold(0.0, (sum, item) => sum + item.paidAmount);
  }

  List<InstallmentModel> get recentTransactions {
    return _installments.take(5).toList();
  }

  // Currency formatter for Iraqi d. a
  String formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }
}
