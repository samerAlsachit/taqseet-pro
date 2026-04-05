class PaymentSchedule {
  final String? id;
  final String planId;
  final String storeId;
  final int installmentNo;
  final DateTime dueDate;
  final int amount;
  final String status;
  final String? syncStatus;
  final DateTime? createdAt;

  PaymentSchedule({
    this.id,
    required this.planId,
    required this.storeId,
    required this.installmentNo,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.syncStatus,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'store_id': storeId,
      'installment_no': installmentNo,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'sync_status': syncStatus ?? 'pending',
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory PaymentSchedule.fromMap(Map<String, dynamic> map) {
    return PaymentSchedule(
      id: map['id'] as String?,
      planId: map['plan_id'] as String,
      storeId: map['store_id'] as String,
      installmentNo: (map['installment_no'] as num).toInt(),
      dueDate: DateTime.parse(map['due_date'] as String),
      amount: (map['amount'] as num).toInt(),
      status: map['status'] as String? ?? 'pending',
      syncStatus: map['sync_status'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'store_id': storeId,
      'installment_no': installmentNo,
      'due_date': dueDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      id: json['id'] as String?,
      planId: json['plan_id'] as String,
      storeId: json['store_id'] as String,
      installmentNo: (json['installment_no'] as num).toInt(),
      dueDate: DateTime.parse(json['due_date'] as String),
      amount: (json['amount'] as num).toInt(),
      status: json['status'] as String? ?? 'pending',
      syncStatus: json['sync_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  PaymentSchedule copyWith({
    String? id,
    String? planId,
    String? storeId,
    int? installmentNo,
    DateTime? dueDate,
    int? amount,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
  }) {
    return PaymentSchedule(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      storeId: storeId ?? this.storeId,
      installmentNo: installmentNo ?? this.installmentNo,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  String get formattedAmount => '$amount IQD';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'في انتظار الدفع';
      case 'paid':
        return 'مدفوع';
      case 'overdue':
        return 'متأخر';
      default:
        return status;
    }
  }

  bool get isOverdue {
    if (status == 'paid') return false;
    return DateTime.now().isAfter(dueDate);
  }

  bool get isPaid => status == 'paid';

  bool get isPending => status == 'pending';

  int get daysUntilDue {
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return due.difference(todayOnly).inDays;
  }

  String get formattedDueDate =>
      '${dueDate.day}/${dueDate.month}/${dueDate.year}';

  // ─── Overrides ────────────────────────────────────────────────────────────

  @override
  String toString() =>
      'PaymentSchedule(id: $id, planId: $planId, installmentNo: $installmentNo, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentSchedule &&
        other.id == id &&
        other.planId == planId &&
        other.installmentNo == installmentNo;
  }

  @override
  int get hashCode => id.hashCode ^ planId.hashCode ^ installmentNo.hashCode;
}
