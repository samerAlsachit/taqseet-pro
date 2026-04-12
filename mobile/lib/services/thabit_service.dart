import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installment_plan_model.dart';
import '../models/payment_schedule_model.dart';
import '../models/payment_model.dart';
import '../models/customer_model.dart';
import 'local_db_service.dart';

/// ThabitService - خدمة نظام ثبات الجديدة
/// تدير العمليات على الجداول الجديدة: installment_plans, payment_schedule, payments
class ThabitService {
  static final ThabitService _instance = ThabitService._internal();
  factory ThabitService() => _instance;
  ThabitService._internal();

  SupabaseClient? _supabase;
  final LocalDBService _localDB = LocalDBService();

  /// Initialize the service
  Future<void> init() async {
    _supabase = Supabase.instance.client;
    await _localDB.init();
  }

  // ============================================
  // Installment Plans - خطط التقسيط
  // ============================================

  /// Fetch installment plans for a customer (with customer details)
  Future<List<InstallmentPlanModel>> getInstallmentPlansByCustomer(
    String customerId, {
    bool includeCustomer = true,
  }) async {
    try {
      print('🔍 ThabitService: Fetching installment plans for customer: $customerId');

      var query = _supabase!.from('installment_plans').select('''
        *,
        customers!inner(full_name, phone, national_id, address)
      ''');

      final response = await query.eq('customer_id', customerId).order('created_at', ascending: false);

      print('✅ ThabitService: Found ${response.length} installment plans');

      return response.map((data) {
        // Extract customer data from nested response
        final customerData = data['customers'] as Map<String, dynamic>?;
        if (customerData != null) {
          data['customer_name'] = customerData['full_name'];
        }
        return InstallmentPlanModel.fromJSON(data);
      }).toList();
    } catch (e) {
      print('❌ ThabitService Error: $e');
      return [];
    }
  }

  /// Fetch single installment plan with full details
  Future<InstallmentPlanModel?> getInstallmentPlanDetails(String planId) async {
    try {
      final response = await _supabase!
          .from('installment_plans')
          .select('''
            *,
            customers!inner(full_name, phone, national_id, address)
          ''')
          .eq('id', planId)
          .single();

      final customerData = response['customers'] as Map<String, dynamic>?;
      if (customerData != null) {
        response['customer_name'] = customerData['full_name'];
      }

      return InstallmentPlanModel.fromJSON(response);
    } catch (e) {
      print('❌ ThabitService Error fetching plan details: $e');
      return null;
    }
  }

  // ============================================
  // Payment Schedule - جدول الدفعات
  // ============================================

  /// Fetch payment schedule for an installment plan
  Future<List<PaymentScheduleModel>> getPaymentSchedule(String installmentPlanId) async {
    try {
      print('🔍 ThabitService: Fetching payment schedule for plan: $installmentPlanId');

      final response = await _supabase!
          .from('payment_schedule')
          .select('''
            *,
            payments(amount_paid, payment_date)
          ''')
          .eq('installment_plan_id', installmentPlanId)
          .order('installment_no', ascending: true);

      print('✅ ThabitService: Found ${response.length} payment schedule items');

      return response.map((data) => PaymentScheduleModel.fromJSON(data)).toList();
    } catch (e) {
      print('❌ ThabitService Error fetching schedule: $e');
      return [];
    }
  }

  /// Fetch all payment schedules for a customer (across all plans)
  Future<List<PaymentScheduleModel>> getCustomerPaymentSchedule(String customerId) async {
    try {
      print('🔍 ThabitService: Fetching all payment schedules for customer: $customerId');

      // First get all installment plans for this customer
      final plansResponse = await _supabase!
          .from('installment_plans')
          .select('id')
          .eq('customer_id', customerId);

      final planIds = plansResponse.map((p) => p['id'].toString()).toList();

      if (planIds.isEmpty) {
        print('⚠️ ThabitService: No installment plans found for customer');
        return [];
      }

      // Get payment schedules for all plans
      final response = await _supabase!
          .from('payment_schedule')
          .select('''
            *,
            installment_plans!inner(customer_id),
            payments(amount_paid, payment_date)
          ''')
          .inFilter('installment_plan_id', planIds)
          .order('due_date', ascending: true);

      print('✅ ThabitService: Found ${response.length} payment schedules');

      return response.map((data) => PaymentScheduleModel.fromJSON(data)).toList();
    } catch (e) {
      print('❌ ThabitService Error: $e');
      return [];
    }
  }

  // ============================================
  // Payments - المدفوعات
  // ============================================

  /// Record a new payment
  Future<bool> recordPayment({
    required String installmentPlanId,
    required String? paymentScheduleId,
    required String customerId,
    required int amountPaid,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      print('💰 ThabitService: Recording payment of $amountPaid');

      final paymentData = {
        'installment_plan_id': installmentPlanId,
        'payment_schedule_id': paymentScheduleId,
        'customer_id': customerId,
        'amount_paid': amountPaid,
        'payment_date': DateTime.now().toIso8601String(),
        'payment_method': paymentMethod ?? 'cash',
        'notes': notes,
      };

      await _supabase!.from('payments').insert(paymentData);

      // Update payment schedule status if applicable
      if (paymentScheduleId != null) {
        await _updatePaymentScheduleStatus(paymentScheduleId);
      }

      print('✅ ThabitService: Payment recorded successfully');
      return true;
    } catch (e) {
      print('❌ ThabitService Error recording payment: $e');
      return false;
    }
  }

  /// Get payments for an installment plan
  Future<List<PaymentModel>> getPaymentsByPlan(String installmentPlanId) async {
    try {
      final response = await _supabase!
          .from('payments')
          .select()
          .eq('installment_plan_id', installmentPlanId)
          .order('payment_date', ascending: false);

      return response.map((data) => PaymentModel.fromJSON(data)).toList();
    } catch (e) {
      print('❌ ThabitService Error: $e');
      return [];
    }
  }

  /// Update payment schedule status based on payments
  Future<void> _updatePaymentScheduleStatus(String paymentScheduleId) async {
    try {
      // Get total paid for this schedule item
      final paymentsResponse = await _supabase!
          .from('payments')
          .select('amount_paid')
          .eq('payment_schedule_id', paymentScheduleId);

      final totalPaid = paymentsResponse.fold<int>(
        0,
        (sum, p) => sum + ((p['amount_paid'] as num?)?.toInt() ?? 0),
      );

      // Get the schedule item to check required amount
      final scheduleResponse = await _supabase!
          .from('payment_schedule')
          .select('amount')
          .eq('id', paymentScheduleId)
          .single();

      final requiredAmount = (scheduleResponse['amount'] as num?)?.toInt() ?? 0;

      // Determine status
      String status;
      if (totalPaid >= requiredAmount) {
        status = 'paid';
      } else if (totalPaid > 0) {
        status = 'partially_paid';
      } else {
        status = 'pending';
      }

      // Update status
      await _supabase!.from('payment_schedule').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentScheduleId);
    } catch (e) {
      print('❌ ThabitService Error updating schedule status: $e');
    }
  }

  // ============================================
  // Customer Statement - كشف حساب العميل
  // ============================================

  /// Get complete customer statement data
  Future<CustomerStatementData?> getCustomerStatement(String customerId) async {
    try {
      print('📊 ThabitService: Generating customer statement for: $customerId');

      // 1. Get customer details
      final customerResponse = await _supabase!
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();

      final customer = CustomerModel.fromJson(customerResponse);

      // 2. Get all installment plans
      final plans = await getInstallmentPlansByCustomer(customerId);

      // 3. Get payment schedules for all plans
      List<PaymentScheduleModel> allSchedules = [];
      for (final plan in plans) {
        final schedules = await getPaymentSchedule(plan.id);
        allSchedules.addAll(schedules);
      }

      // 4. Calculate totals
      final totalFinanced = plans.fold<int>(0, (sum, p) => sum + p.financedAmount);
      final totalPaid = allSchedules.fold<int>(0, (sum, s) => sum + (s.paidAmount ?? 0));
      final totalRemaining = totalFinanced - totalPaid;

      return CustomerStatementData(
        customer: customer,
        installmentPlans: plans,
        paymentSchedules: allSchedules,
        totalFinanced: totalFinanced,
        totalPaid: totalPaid,
        totalRemaining: totalRemaining,
      );
    } catch (e) {
      print('❌ ThabitService Error generating statement: $e');
      return null;
    }
  }
}

/// Customer Statement Data - بيانات كشف حساب العميل
class CustomerStatementData {
  final CustomerModel customer;
  final List<InstallmentPlanModel> installmentPlans;
  final List<PaymentScheduleModel> paymentSchedules;
  final int totalFinanced;
  final int totalPaid;
  final int totalRemaining;

  CustomerStatementData({
    required this.customer,
    required this.installmentPlans,
    required this.paymentSchedules,
    required this.totalFinanced,
    required this.totalPaid,
    required this.totalRemaining,
  });
}
