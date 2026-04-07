import 'package:flutter/material.dart';
import '../models/installment_model.dart';
import '../core/utils/formatter.dart';

class InstallmentProvider with ChangeNotifier {
  List<InstallmentModel> _installments = [];
  bool _isLoading = false;
  String? _error;

  List<InstallmentModel> get installments => _installments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  InstallmentProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Simulate API delay
    Future.delayed(const Duration(seconds: 1), () {
      _installments = [
        InstallmentModel(
          id: '1',
          customerName: '  Mohamed Ahmed Hassan',
          totalAmount: 250000.0,
          paidAmount: 150000.0,
          remainingAmount: 100000.0,
          dueDate: DateTime.now().add(const Duration(days: 15)),
          status: 'pending',
        ),
        InstallmentModel(
          id: '2',
          customerName: '  Fatima Ali Karim',
          totalAmount: 180000.0,
          paidAmount: 180000.0,
          remainingAmount: 0.0,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          status: 'completed',
        ),
        InstallmentModel(
          id: '3',
          customerName: '  Hassan Mahmoud Ali',
          totalAmount: 320000.0,
          paidAmount: 80000.0,
          remainingAmount: 240000.0,
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'overdue',
        ),
        InstallmentModel(
          id: '4',
          customerName: '  Sara Youssef Omar',
          totalAmount: 150000.0,
          paidAmount: 75000.0,
          remainingAmount: 75000.0,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          status: 'pending',
        ),
        InstallmentModel(
          id: '5',
          customerName: '  Omar Khalid Ahmed',
          totalAmount: 450000.0,
          paidAmount: 450000.0,
          remainingAmount: 0.0,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          status: 'completed',
        ),
        InstallmentModel(
          id: '6',
          customerName: '  Layla Hassan Mahmoud',
          totalAmount: 280000.0,
          paidAmount: 140000.0,
          remainingAmount: 140000.0,
          dueDate: DateTime.now().add(const Duration(days: 10)),
          status: 'pending',
        ),
        InstallmentModel(
          id: '7',
          customerName: '  Khalid Saad Ali',
          totalAmount: 120000.0,
          paidAmount: 0.0,
          remainingAmount: 120000.0,
          dueDate: DateTime.now().add(const Duration(days: 20)),
          status: 'pending',
        ),
        InstallmentModel(
          id: '8',
          customerName: '  Noura Mohamed Karim',
          totalAmount: 380000.0,
          paidAmount: 190000.0,
          remainingAmount: 190000.0,
          dueDate: DateTime.now().subtract(const Duration(days: 3)),
          status: 'overdue',
        ),
        InstallmentModel(
          id: '9',
          customerName: '  Ahmed Ali Hassan',
          totalAmount: 220000.0,
          paidAmount: 220000.0,
          remainingAmount: 0.0,
          dueDate: DateTime.now().subtract(const Duration(days: 7)),
          status: 'completed',
        ),
        InstallmentModel(
          id: '10',
          customerName: '  Rania Mahmoud Omar',
          totalAmount: 350000.0,
          paidAmount: 175000.0,
          remainingAmount: 175000.0,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          status: 'pending',
        ),
      ];

      _isLoading = false;
      _error = null;
      notifyListeners();
    });
  }

  Future<void> loadInstallments() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      _loadMockData();
    } catch (e) {
      _isLoading = false;
      _error = 'فشل في تحميل البيانات: $e';
      notifyListeners();
    }
  }

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
