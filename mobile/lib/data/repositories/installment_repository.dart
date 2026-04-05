import '../models/installment.dart';
import '../models/payment_schedule.dart';
import '../../core/database/database_helper.dart';

class InstallmentRepository {
  final DatabaseHelper _databaseHelper;

  InstallmentRepository(this._databaseHelper);

  // Get all installments
  Future<List<Installment>> getAll() async {
    try {
      final installments = await _databaseHelper.getAllInstallmentPlans();
      return installments
          .map((installment) => Installment.fromMap(installment))
          .toList();
    } catch (e) {
      throw Exception('Failed to get installments: $e');
    }
  }

  // Get installment by ID
  Future<Installment?> getById(String id) async {
    try {
      final installment = await _databaseHelper.getInstallmentPlanById(id);
      return installment != null ? Installment.fromMap(installment) : null;
    } catch (e) {
      throw Exception('Failed to get installment by ID: $e');
    }
  }

  // Get installments by customer
  Future<List<Installment>> getByCustomer(String customerId) async {
    try {
      final installments = await _databaseHelper.getAllInstallmentPlans();
      final customerInstallments = installments
          .where((installment) => installment['customer_id'] == customerId)
          .toList();
      return customerInstallments
          .map((installment) => Installment.fromMap(installment))
          .toList();
    } catch (e) {
      throw Exception('Failed to get installments by customer: $e');
    }
  }

  // Insert new installment
  Future<String> insert(Installment installment) async {
    try {
      // First insert the installment plan
      final planId = await _databaseHelper.insertInstallmentPlan(
        installment.toMap(),
      );

      // Then create payment schedule
      await _createPaymentSchedule(planId, installment);

      return planId;
    } catch (e) {
      throw Exception('Failed to insert installment: $e');
    }
  }

  // Update existing installment
  Future<int> update(Installment installment) async {
    try {
      if (installment.id == null) {
        throw Exception('Installment ID is required for update');
      }
      return await _databaseHelper.updateInstallmentPlan(
        installment.id!,
        installment.toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update installment: $e');
    }
  }

  // Delete installment
  Future<int> delete(String id) async {
    try {
      // First delete payment schedule
      await _databaseHelper.deletePaymentScheduleByPlanId(id);
      // Then delete the installment plan
      return await _databaseHelper.deleteInstallmentPlan(id);
    } catch (e) {
      throw Exception('Failed to delete installment: $e');
    }
  }

  // Get payment schedule for a plan
  Future<List<PaymentSchedule>> getSchedule(String planId) async {
    try {
      final schedules = await _databaseHelper.getPaymentScheduleByPlanId(
        planId,
      );
      return schedules
          .map((schedule) => PaymentSchedule.fromMap(schedule))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payment schedule: $e');
    }
  }

  // Update payment schedule status
  Future<int> updateScheduleStatus(String scheduleId, String status) async {
    try {
      return await _databaseHelper.updatePaymentScheduleStatus(
        scheduleId,
        status,
      );
    } catch (e) {
      throw Exception('Failed to update payment schedule status: $e');
    }
  }

  // Make payment for a schedule
  Future<int> makePayment(String scheduleId, int amount) async {
    try {
      // Update schedule status to paid
      await updateScheduleStatus(scheduleId, 'paid');

      // Create payment record
      await _databaseHelper.insertPayment({
        'plan_id': scheduleId, // This should be the plan_id from the schedule
        'schedule_id': scheduleId,
        'store_id': 'default_store',
        'amount_paid': amount,
        'payment_date': DateTime.now().toIso8601String(),
        'receipt_number': 'REC_${DateTime.now().millisecondsSinceEpoch}',
        'notes': 'دفعة قسط',
        'sync_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update installment remaining amount
      await _updateInstallmentRemainingAmount(scheduleId, amount);

      return 1;
    } catch (e) {
      throw Exception('Failed to make payment: $e');
    }
  }

  // Get installments by store
  Future<List<Installment>> getInstallmentsByStore(String storeId) async {
    try {
      final installments = await _databaseHelper.getAllInstallmentPlans();
      return installments
          .where((installment) => installment['store_id'] == storeId)
          .map((installment) => Installment.fromMap(installment))
          .toList();
    } catch (e) {
      throw Exception('Failed to get installments by store: $e');
    }
  }

  // Get installments by status
  Future<List<Installment>> getByStatus(String status, String storeId) async {
    try {
      final installments = await _databaseHelper.getAllInstallmentPlans();
      return installments
          .where(
            (installment) =>
                installment['store_id'] == storeId &&
                installment['status'] == status,
          )
          .map((installment) => Installment.fromMap(installment))
          .toList();
    } catch (e) {
      throw Exception('Failed to get installments by status: $e');
    }
  }

  // Get overdue installments
  Future<List<Installment>> getOverdueInstallments(String storeId) async {
    try {
      final installments = await getInstallmentsByStore(storeId);
      return installments
          .where((installment) => installment.isOverdue)
          .toList();
    } catch (e) {
      throw Exception('Failed to get overdue installments: $e');
    }
  }

  // Get installment statistics
  Future<Map<String, dynamic>> getStatistics(String storeId) async {
    try {
      final installments = await getInstallmentsByStore(storeId);
      final totalInstallments = installments.length;
      final activeInstallments = installments.where((i) => i.isActive).length;
      final completedInstallments = installments
          .where((i) => i.isCompleted)
          .length;
      final overdueInstallments = installments.where((i) => i.isOverdue).length;

      final totalValue = installments.fold<int>(
        0,
        (sum, installment) => sum + installment.totalPrice,
      );

      final totalRemaining = installments.fold<int>(
        0,
        (sum, installment) => sum + installment.remainingAmount,
      );

      return {
        'total_installments': totalInstallments,
        'active_installments': activeInstallments,
        'completed_installments': completedInstallments,
        'overdue_installments': overdueInstallments,
        'total_value': totalValue,
        'total_remaining': totalRemaining,
      };
    } catch (e) {
      throw Exception('Failed to get installment statistics: $e');
    }
  }

  // Private method to create payment schedule
  Future<void> _createPaymentSchedule(
    String planId,
    Installment installment,
  ) async {
    try {
      DateTime currentDate = installment.startDate;

      for (int i = 0; i < installment.installmentsCount; i++) {
        final schedule = PaymentSchedule(
          planId: planId,
          storeId: installment.storeId,
          installmentNo: i + 1,
          dueDate: currentDate,
          amount: installment.installmentAmount,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        await _databaseHelper.insertPaymentSchedule(schedule.toMap());

        // Calculate next due date based on frequency
        switch (installment.frequency) {
          case 'daily':
            currentDate = currentDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            currentDate = currentDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            currentDate = DateTime(
              currentDate.year,
              currentDate.month + 1,
              currentDate.day,
            );
            break;
        }
      }
    } catch (e) {
      throw Exception('Failed to create payment schedule: $e');
    }
  }

  // Private method to update installment remaining amount
  Future<void> _updateInstallmentRemainingAmount(
    String scheduleId,
    int amount,
  ) async {
    try {
      // Get the schedule to find the plan
      final schedules = await _databaseHelper.getPaymentScheduleByPlanId(
        scheduleId,
      );
      if (schedules.isEmpty) return;

      final planId = schedules.first['plan_id'] as String;
      final installment = await getById(planId);
      if (installment == null) return;

      // Update remaining amount
      final newRemainingAmount = installment.remainingAmount - amount;
      if (newRemainingAmount <= 0) {
        // Mark installment as completed
        await update(
          installment.copyWith(remainingAmount: 0, status: 'completed'),
        );
      } else {
        await update(installment.copyWith(remainingAmount: newRemainingAmount));
      }
    } catch (e) {
      throw Exception('Failed to update installment remaining amount: $e');
    }
  }
}
