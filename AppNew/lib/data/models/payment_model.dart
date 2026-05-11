class PaymentModel {
  final String id;
  final String planId;
  final String? scheduleId;
  final String storeId;
  final double amountPaid;
  final DateTime paymentDate;
  final bool isEarly;
  final String? receiptNumber;
  final String? notes;
  final String currency;

  PaymentModel({
    required this.id,
    required this.planId,
    this.scheduleId,
    required this.storeId,
    required this.amountPaid,
    required this.paymentDate,
    required this.isEarly,
    this.receiptNumber,
    this.notes,
    required this.currency,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id']?.toString() ?? '',
    planId: json['plan_id']?.toString() ?? '',
    scheduleId: json['schedule_id']?.toString(),
    storeId: json['store_id']?.toString() ?? '',
    amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
    paymentDate: DateTime.tryParse(json['payment_date'] ?? '') ?? DateTime.now(),
    isEarly: json['is_early'] ?? false,
    receiptNumber: json['receipt_number'],
    notes: json['notes'],
    currency: json['currency'] ?? 'IQD',
  );
}

class ScheduleModel {
  final String id;
  final String planId;
  final int installmentNo;
  final DateTime dueDate;
  final double amount;
  final String status;

  ScheduleModel({
    required this.id,
    required this.planId,
    required this.installmentNo,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    id: json['id']?.toString() ?? '',
    planId: json['plan_id']?.toString() ?? '',
    installmentNo: json['installment_no'] ?? 0,
    dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: json['status'] ?? 'pending',
  );
}
