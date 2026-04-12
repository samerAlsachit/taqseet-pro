import '../core/utils/formatter.dart';

/// PaymentModel - نموذج المدفوعات
/// يتوافق مع جدول payments في Supabase
class PaymentModel {
  final String id;
  final String? installmentPlanId; // ارتباط بخطة التقسيط
  final String? paymentScheduleId; // ارتباط بجدول الدفعات
  final String? customerId; // ارتباط بالعميل
  final int amountPaid; // المبلغ المدفوع
  final DateTime paymentDate; // تاريخ الدفع
  final String? paymentMethod; // طريقة الدفع (cash, bank, etc.)
  final String? notes; // ملاحظات

  // Offline-first sync fields
  final bool isSynced;
  final String? localId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    this.installmentPlanId,
    this.paymentScheduleId,
    this.customerId,
    required this.amountPaid,
    required this.paymentDate,
    this.paymentMethod,
    this.notes,
    this.isSynced = false,
    this.localId,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJSON(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      installmentPlanId: json['installment_plan_id']?.toString(),
      paymentScheduleId: json['payment_schedule_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      amountPaid: (json['amount_paid'] as num?)?.toInt() ?? 0,
      paymentDate: DateTime.tryParse(json['payment_date']?.toString() ?? '') ?? DateTime.now(),
      paymentMethod: json['payment_method']?.toString(),
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
      'installment_plan_id': installmentPlanId,
      'payment_schedule_id': paymentScheduleId,
      'customer_id': customerId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
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
      'payment_schedule_id': paymentScheduleId,
      'customer_id': customerId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Getters for formatted display
  String get formattedAmountPaid => CurrencyFormatter.formatCurrency(amountPaid.toDouble());
  String get formattedPaymentDate => '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';

  PaymentModel copyWith({
    String? id,
    String? installmentPlanId,
    String? paymentScheduleId,
    String? customerId,
    int? amountPaid,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
    bool? isSynced,
    String? localId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      paymentScheduleId: paymentScheduleId ?? this.paymentScheduleId,
      customerId: customerId ?? this.customerId,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
