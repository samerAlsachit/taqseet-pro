import 'package:flutter/material.dart';
import '../models/installment_model.dart';
import '../models/installment_plan_model.dart';
import '../core/utils/formatter.dart';
import '../services/thabit_local_db_service.dart';
import '../services/installment_service.dart';

class InstallmentProvider with ChangeNotifier {
  List<InstallmentModel> _installments = [];
  bool _isLoading = false;
  String? _error;
  final ThabitLocalDBService _localDB = ThabitLocalDBService();
  final InstallmentService _installmentService = InstallmentService();

  List<InstallmentModel> get installments => _installments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  InstallmentProvider() {
    loadInstallments();
  }

  /// Load installments from API with customer data, fallback to local DB
  Future<void> loadInstallments() async {
    await _fetchFromAPIWithCustomer();
  }

  /// Fetch installments from API with customer data included
  Future<void> _fetchFromAPIWithCustomer() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // ✅ جلب الأقساط من السيرفر مع بيانات العملاء
      final result = await _installmentService.fetchInstallmentsWithCustomer();

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final List<dynamic> plansData = data['plans'] ?? [];

        _installments = plansData
            .map(
              (planJson) =>
                  InstallmentModel.fromJSON(planJson as Map<String, dynamic>),
            )
            .toList();

        // حفظ في قاعدة البيانات المحلية
        await _saveToLocalDB();

        _isLoading = false;
        notifyListeners();
      } else {
        // fallback إلى قاعدة البيانات المحلية
        await _loadFromLocalDB();
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching from API: $e');
      print('📋 Stack trace: $stackTrace');
      _error = 'فشل في جلب البيانات: ${e.toString()}';
      await _loadFromLocalDB();
    } finally {
      // Ensure loading state is reset and listeners notified
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load installments from local Hive database
  Future<void> _loadFromLocalDB() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Initialize local DB if needed
      await _localDB.init();

      // Load from local Hive storage
      final plans = _localDB.getAllInstallmentPlans();

      // ✅ Convert InstallmentPlanModel to InstallmentModel with proper calculations
      _installments = plans.map((plan) {
        // استخراج القيم المالية من الـ summary إذا وجد
        final summary = plan.summary;
        double paidAmount = plan.downPayment.toDouble();
        double remainingAmount = plan.financedAmount.toDouble();

        if (summary != null) {
          paidAmount =
              summary['total_paid']?.toDouble() ?? plan.downPayment.toDouble();
          remainingAmount =
              summary['remaining_balance']?.toDouble() ??
              plan.financedAmount.toDouble();
        }

        return InstallmentModel(
          id: plan.id,
          customerId: plan.customerId,
          customerName: plan.customerName?.isNotEmpty == true
              ? plan.customerName!
              : 'عميل غير معروف',
          totalAmount: plan.totalPrice.toDouble(),
          paidAmount: paidAmount,
          remainingAmount: remainingAmount,
          dueDate: plan.endDate,
          status: plan.status == 'active' ? 'pending' : plan.status,
          isSynced: true,
          createdAt: plan.createdAt,
          updatedAt: plan.updatedAt,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'فشل في تحميل البيانات: $e';
      notifyListeners();
    }
  }

  /// Save installments to local database
  Future<void> _saveToLocalDB() async {
    try {
      for (final installment in _installments) {
        final plan = InstallmentPlanModel(
          id: installment.id,
          customerId: installment.customerId,
          customerName: installment.customerName,
          totalPrice: installment.totalAmount.toInt(),
          downPayment: installment.paidAmount.toInt(),
          financedAmount: (installment.remainingAmount + installment.paidAmount)
              .toInt(),
          installmentsCount: 0, // Will be calculated
          installmentAmount: 0, // Will be calculated
          frequency: 'monthly',
          startDate: DateTime.now(),
          endDate: installment.dueDate,
          status: installment.status,
          remainingAmount: installment.remainingAmount.toInt(),
          currency: 'IQD',
          createdAt: installment.createdAt ?? DateTime.now(),
          updatedAt: installment.updatedAt ?? DateTime.now(),
        );
        await _localDB.saveInstallmentPlan(plan);
      }
    } catch (e) {
      print('⚠️ Error saving to local DB: $e');
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
