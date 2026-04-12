import 'package:flutter/material.dart';
import '../core/utils/formatter.dart';

class InstallmentModel {
  final String id;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final String status;

  // Offline-first sync fields
  final bool isSynced;
  final String? localId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InstallmentModel({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.status,
    this.isSynced = false,
    this.localId,
    this.createdAt,
    this.updatedAt,
  });

  factory InstallmentModel.fromJSON(Map<String, dynamic> json) {
    return InstallmentModel(
      id: json['id']?.toString() ?? '',
      customerId:
          json['customer_id']?.toString() ??
          json['customerId']?.toString() ??
          '',
      customerName:
          json['customer_name']?.toString() ??
          json['customerName']?.toString() ??
          '',
      totalAmount:
          (json['total_amount'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      paidAmount:
          (json['paid_amount'] as num?)?.toDouble() ??
          (json['paidAmount'] as num?)?.toDouble() ??
          0.0,
      remainingAmount:
          (json['remaining_amount'] as num?)?.toDouble() ??
          (json['remainingAmount'] as num?)?.toDouble() ??
          0.0,
      dueDate:
          DateTime.tryParse(
            json['due_date']?.toString() ?? json['dueDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      isSynced: json['is_synced'] as bool? ?? json['isSynced'] as bool? ?? true,
      localId: json['local_id']?.toString() ?? json['localId']?.toString(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? json['updatedAt']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
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
      'customer_name': customerName,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String get formattedTotalAmount =>
      CurrencyFormatter.formatCurrency(totalAmount);
  String get formattedPaidAmount =>
      CurrencyFormatter.formatCurrency(paidAmount);
  String get formattedRemainingAmount =>
      CurrencyFormatter.formatCurrency(remainingAmount);
  String get formattedDueDate =>
      '${dueDate.day}/${dueDate.month}/${dueDate.year}';

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue' && DateTime.now().isAfter(dueDate);

  String get statusDisplay {
    switch (status) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'overdue':
        return 'متأخر';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'overdue':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  InstallmentModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    DateTime? dueDate,
    String? status,
    bool? isSynced,
    String? localId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
