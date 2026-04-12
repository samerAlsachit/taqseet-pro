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
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, completed, cancelled
  final String? notes;

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
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.notes,
    this.isSynced = false,
    this.localId,
    this.createdAt,
    this.updatedAt,
  });

  factory InstallmentPlanModel.fromJSON(Map<String, dynamic> json) {
    return InstallmentPlanModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customers']?['full_name']?.toString() ?? 
                    json['customer_name']?.toString() ?? '',
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      downPayment: (json['down_payment'] as num?)?.toInt() ?? 0,
      financedAmount: (json['financed_amount'] as num?)?.toInt() ?? 0,
      installmentsCount: (json['installments_count'] as num?)?.toInt() ?? 0,
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      isSynced: json['is_synced'] as bool? ?? true,
      localId: json['local_id']?.toString(),
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

  // Getters for formatted display
  String get formattedTotalPrice => CurrencyFormatter.formatCurrency(totalPrice.toDouble());
  String get formattedDownPayment => CurrencyFormatter.formatCurrency(downPayment.toDouble());
  String get formattedFinancedAmount => CurrencyFormatter.formatCurrency(financedAmount.toDouble());
  String get formattedStartDate => '${startDate.day}/${startDate.month}/${startDate.year}';
  String get formattedEndDate => '${endDate.day}/${endDate.month}/${endDate.year}';

  // Calculated remaining amount
  int get remainingAmount => financedAmount; // سيتم حسابها من جدول payments

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
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? notes,
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
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
