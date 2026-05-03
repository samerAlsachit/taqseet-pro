import 'package:flutter/material.dart';
import '../core/utils/formatter.dart';

/// InstallmentPlanModel - نموذج خطة التقسيط
/// يتوافق مع جدول installment_plans في Supabase
class InstallmentPlanModel {
  final String id;
  final String customerId;
  final String? customerName; // من جدول customers
  final int totalPrice;
  final int downPayment;
  final int financedAmount;
  final int installmentsCount;
  final int? installmentAmount;
  final String? frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, completed, cancelled
  final String? notes;
  final int? remainingAmount;
  final String? currency;

  // Data from API with joined tables
  final Map<String, dynamic>? summary; // ملخص الأقساط من payments
  final List<Map<String, dynamic>>? payments; // قائمة الدفعات

  // Offline-first sync fields
  final bool isSynced;
  final String? localId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InstallmentPlanModel({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.totalPrice,
    required this.downPayment,
    required this.financedAmount,
    required this.installmentsCount,
    this.installmentAmount,
    this.frequency,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.notes,
    this.remainingAmount,
    this.currency = 'IQD',
    this.summary,
    this.payments,
    this.isSynced = false,
    this.localId,
    this.createdAt,
    this.updatedAt,
  });

  factory InstallmentPlanModel.fromJSON(Map<String, dynamic> json) {
    // ✅ استخراج اسم العميل من الـ customers object أو من customer_name مباشرة
    String customerName = '';
    if (json['customers'] != null && json['customers'] is Map) {
      customerName = json['customers']['full_name']?.toString() ?? '';
    }
    if (customerName.isEmpty) {
      customerName =
          json['customer_name']?.toString() ??
          json['customerName']?.toString() ??
          '';
    }

    return InstallmentPlanModel(
      id: json['id']?.toString() ?? '',
      customerId:
          json['customer_id']?.toString() ??
          json['customerId']?.toString() ??
          '',
      customerName: customerName.isNotEmpty ? customerName : null,
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      downPayment: (json['down_payment'] as num?)?.toInt() ?? 0,
      financedAmount: (json['financed_amount'] as num?)?.toInt() ?? 0,
      installmentsCount: (json['installments_count'] as num?)?.toInt() ?? 0,
      startDate:
          DateTime.tryParse(json['start_date']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      remainingAmount:
          (json['remaining_amount'] as num?)?.toInt() ??
          (json['remainingAmount'] as num?)?.toInt(),
      currency: json['currency']?.toString() ?? 'IQD',
      isSynced: json['is_synced'] as bool? ?? true,
      localId: json['local_id']?.toString(),
      summary: json['summary'] as Map<String, dynamic>?,
      payments: json['payment_schedule'] != null
          ? List<Map<String, dynamic>>.from(json['payment_schedule'] as List)
          : json['payments'] != null
          ? List<Map<String, dynamic>>.from(json['payments'] as List)
          : json['installments'] != null
          ? List<Map<String, dynamic>>.from(json['installments'] as List)
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'total_price': totalPrice,
      'down_payment': downPayment,
      'financed_amount': financedAmount,
      'installments_count': installmentsCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'is_synced': isSynced,
      'local_id': localId,
      'summary': summary,
      'payments': payments,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to Supabase format (snake_case keys for database)
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'customer_id': customerId,
      'total_price': totalPrice,
      'down_payment': downPayment,
      'financed_amount': financedAmount,
      'installments_count': installmentsCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get paid amount from summary or calculate from payments
  double get calculatedPaidAmount {
    if (summary != null) {
      return (summary!['total_paid'] as num?)?.toDouble() ??
          (summary!['totalPaid'] as num?)?.toDouble() ??
          0.0;
    }
    // Calculate from payments list
    if (payments != null && payments!.isNotEmpty) {
      return payments!.fold<double>(
        0.0,
        (sum, p) =>
            sum +
            ((p['paid_amount'] ?? p['amount_paid'] ?? 0) as num).toDouble(),
      );
    }
    return 0.0;
  }

  /// Get remaining amount from summary (double for precise calculations)
  double get calculatedRemainingAmount {
    if (summary != null) {
      return (summary!['remaining_balance'] as num?)?.toDouble() ??
          (summary!['remainingBalance'] as num?)?.toDouble() ??
          (remainingAmount?.toDouble() ?? financedAmount.toDouble());
    }
    // Calculate from payments
    return (remainingAmount?.toDouble() ?? financedAmount.toDouble()) -
        calculatedPaidAmount;
  }

  // Getters for formatted display
  String get formattedTotalPrice =>
      CurrencyFormatter.formatCurrency(totalPrice.toDouble());
  String get formattedDownPayment =>
      CurrencyFormatter.formatCurrency(downPayment.toDouble());
  String get formattedFinancedAmount =>
      CurrencyFormatter.formatCurrency(financedAmount.toDouble());
  String get formattedStartDate =>
      '${startDate.day}/${startDate.month}/${startDate.year}';
  String get formattedEndDate =>
      '${endDate.day}/${endDate.month}/${endDate.year}';

  // Calculated remaining amount - استخدم calculatedRemainingAmount getter للحساب الديناميكي
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return const Color(0xFF3B82F6);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  InstallmentPlanModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    int? totalPrice,
    int? downPayment,
    int? financedAmount,
    int? installmentsCount,
    int? installmentAmount,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? notes,
    int? remainingAmount,
    String? currency,
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? payments,
    bool? isSynced,
    String? localId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPlanModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalPrice: totalPrice ?? this.totalPrice,
      downPayment: downPayment ?? this.downPayment,
      financedAmount: financedAmount ?? this.financedAmount,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      currency: currency ?? this.currency,
      summary: summary ?? this.summary,
      payments: payments ?? this.payments,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
