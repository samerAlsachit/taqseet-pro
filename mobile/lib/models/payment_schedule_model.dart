import 'package:flutter/material.dart';
import '../core/utils/formatter.dart';

/// PaymentScheduleModel - نموذج جدول دفعات الأقساط
/// يتوافق مع جدول payment_schedule في Supabase
class PaymentScheduleModel {
  final String id;
  final String installmentPlanId;
  final int installmentNo; // رقم القسط (1, 2, 3, ...)
  final DateTime dueDate; // تاريخ الاستحقاق
  final int amount; // مبلغ القسط
  final String status; // pending, paid, overdue, partially_paid
  final int? paidAmount; // المبلغ المدفوع (من جدول payments)
  final DateTime? paidDate; // تاريخ الدفع (من جدول payments)

  // Offline-first sync fields
  final bool isSynced;
  final String? localId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentScheduleModel({
    required this.id,
    required this.installmentPlanId,
    required this.installmentNo,
    required this.dueDate,
    required this.amount,
    this.status = 'pending',
    this.paidAmount,
    this.paidDate,
    this.isSynced = false,
    this.localId,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentScheduleModel.fromJSON(Map<String, dynamic> json) {
    return PaymentScheduleModel(
      id: json['id']?.toString() ?? '',
      installmentPlanId: json['installment_plan_id']?.toString() ?? 
                         json['installmentPlanId']?.toString() ?? '',
      installmentNo: (json['installment_no'] as num?)?.toInt() ?? 0,
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      paidAmount: (json['paid_amount'] as num?)?.toInt() ??
                  (json['payments'] as List<dynamic>?)?.fold<int>(
                    0, 
                    (sum, p) => sum + ((p['amount_paid'] as num?)?.toInt() ?? 0)
                  ) ?? 0,
      paidDate: json['paid_date'] != null 
          ? DateTime.tryParse(json['paid_date']?.toString() ?? '')
          : null,
      isSynced: json['is_synced'] as bool? ?? true,
      localId: json['local_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'installment_plan_id': installmentPlanId,
      'installment_no': installmentNo,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'paid_amount': paidAmount,
      'paid_date': paidDate?.toIso8601String(),
      'is_synced': isSynced,
      'local_id': localId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'installment_plan_id': installmentPlanId,
      'installment_no': installmentNo,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Getters for formatted display
  String get formattedAmount => CurrencyFormatter.formatCurrency(amount.toDouble());
  String get formattedPaidAmount => CurrencyFormatter.formatCurrency((paidAmount ?? 0).toDouble());
  String get formattedDueDate => '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  String get formattedPaidDate => paidDate != null 
      ? '${paidDate!.day}/${paidDate!.month}/${paidDate!.year}' 
      : '-';

  // Calculated remaining for this installment
  int get remainingAmount => amount - (paidAmount ?? 0);
  String get formattedRemaining => CurrencyFormatter.formatCurrency(remainingAmount.toDouble());

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid' || (paidAmount ?? 0) >= amount;
  bool get isPartiallyPaid => status == 'partially_paid' || 
                              ((paidAmount ?? 0) > 0 && (paidAmount ?? 0) < amount);
  bool get isOverdue => status == 'overdue' || 
                        (isPending && DateTime.now().isAfter(dueDate));

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'معلق';
      case 'paid':
        return 'مدفوع';
      case 'partially_paid':
        return 'مدفوع جزئياً';
      case 'overdue':
        return 'متأخر';
      default:
        return status;
    }
  }

  Color get statusColor {
    if (isPaid) {
      return const Color(0xFF10B981);
    } else if (isPartiallyPaid) {
      return const Color(0xFFF59E0B);
    } else if (isOverdue) {
      return const Color(0xFFEF4444);
    } else {
      return const Color(0xFF64748B);
    }
  }

  PaymentScheduleModel copyWith({
    String? id,
    String? installmentPlanId,
    int? installmentNo,
    DateTime? dueDate,
    int? amount,
    String? status,
    int? paidAmount,
    DateTime? paidDate,
    bool? isSynced,
    String? localId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentScheduleModel(
      id: id ?? this.id,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      installmentNo: installmentNo ?? this.installmentNo,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      paidDate: paidDate ?? this.paidDate,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
