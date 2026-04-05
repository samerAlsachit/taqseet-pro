class Installment {
  final String? id;
  final String storeId;
  final String customerId;
  final String productId;
  final String productName;
  final int totalPrice;
  final int downPayment;
  final int financedAmount;
  final int remainingAmount;
  final String currency;
  final String frequency;
  final int installmentAmount;
  final int installmentsCount;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? customerName; // Add customer name field

  Installment({
    this.id,
    required this.storeId,
    required this.customerId,
    required this.productId,
    required this.productName,
    required this.totalPrice,
    required this.downPayment,
    required this.financedAmount,
    required this.remainingAmount,
    this.currency = 'IQD',
    required this.frequency,
    required this.installmentAmount,
    required this.installmentsCount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
    this.customerName, // Add customer name parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'customer_id': customerId,
      'customer_name': customerName,
      'product_id': productId,
      'product_name': productName,
      'total_price': totalPrice,
      'down_payment': downPayment,
      'financed_amount': financedAmount,
      'remaining_amount': remainingAmount,
      'currency': currency,
      'frequency': frequency,
      'installment_amount': installmentAmount,
      'installments_count': installmentsCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'sync_status': syncStatus ?? 'pending',
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      customerId: map['customer_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      totalPrice:
          (map['total_price'] is int
              ? map['total_price']
              : (map['total_price'] as num).toInt()) ??
          0,
      downPayment:
          (map['down_payment'] is int
              ? map['down_payment']
              : (map['down_payment'] as num).toInt()) ??
          0,
      financedAmount:
          (map['financed_amount'] is int
              ? map['financed_amount']
              : (map['financed_amount'] as num).toInt()) ??
          0,
      remainingAmount:
          (map['remaining_amount'] is int
              ? map['remaining_amount']
              : (map['remaining_amount'] as num).toInt()) ??
          0,
      currency: map['currency'] as String? ?? 'IQD',
      frequency: map['frequency'] as String? ?? 'monthly',
      installmentAmount:
          (map['installment_amount'] is int
              ? map['installment_amount']
              : (map['installment_amount'] as num).toInt()) ??
          0,
      installmentsCount:
          (map['installments_count'] is int
              ? map['installments_count']
              : (map['installments_count'] as num).toInt()) ??
          0,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      status: map['status'] as String? ?? 'active',
      syncStatus: map['sync_status'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      customerName: map['customer_name'] as String? ?? '',
    );
  }

  // JSON methods for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'customer_id': customerId,
      'product_id': productId,
      'product_name': productName,
      'total_price': totalPrice,
      'down_payment': downPayment,
      'financed_amount': financedAmount,
      'remaining_amount': remainingAmount,
      'currency': currency,
      'frequency': frequency,
      'installment_amount': installmentAmount,
      'installments_count': installmentsCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      customerId: json['customer_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      totalPrice:
          (json['total_price'] is int
              ? json['total_price']
              : (json['total_price'] as num).toInt()) ??
          0,
      downPayment:
          (json['down_payment'] is int
              ? json['down_payment']
              : (json['down_payment'] as num).toInt()) ??
          0,
      financedAmount:
          (json['financed_amount'] is int
              ? json['financed_amount']
              : (json['financed_amount'] as num).toInt()) ??
          0,
      remainingAmount:
          (json['remaining_amount'] is int
              ? json['remaining_amount']
              : (json['remaining_amount'] as num).toInt()) ??
          0,
      currency: json['currency'] as String? ?? 'IQD',
      frequency: json['frequency'] as String? ?? 'monthly',
      installmentAmount:
          (json['installment_amount'] is int
              ? json['installment_amount']
              : (json['installment_amount'] as num).toInt()) ??
          0,
      installmentsCount:
          (json['installments_count'] is int
              ? json['installments_count']
              : (json['installments_count'] as num).toInt()) ??
          0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String? ?? 'active',
      syncStatus: json['sync_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Installment copyWith({
    String? id,
    String? storeId,
    String? customerId,
    String? productId,
    String? productName,
    int? totalPrice,
    int? downPayment,
    int? financedAmount,
    int? remainingAmount,
    String? currency,
    String? frequency,
    int? installmentAmount,
    int? installmentsCount,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Installment(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      totalPrice: totalPrice ?? this.totalPrice,
      downPayment: downPayment ?? this.downPayment,
      financedAmount: financedAmount ?? this.financedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted amounts
  String get formattedTotalPrice => '$totalPrice $currency';
  String get formattedDownPayment => '$downPayment $currency';
  String get formattedFinancedAmount => '$financedAmount $currency';
  String get formattedRemainingAmount => '$remainingAmount $currency';
  String get formattedInstallmentAmount => '$installmentAmount $currency';

  // Get status display
  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'completed':
        return 'مكتمل';
      case 'overdue':
        return 'متأخر';
      default:
        return status;
    }
  }

  // Get frequency display
  String get frequencyDisplay {
    switch (frequency) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      default:
        return frequency;
    }
  }

  // Check if installment is overdue
  bool get isOverdue => status == 'overdue';

  // Check if installment is completed
  bool get isCompleted => status == 'completed';

  // Check if installment is active
  bool get isActive => status == 'active';

  // Get progress percentage
  double get progress {
    if (totalPrice == 0) return 0.0;
    return ((totalPrice - remainingAmount) / totalPrice) * 100;
  }

  @override
  String toString() {
    return 'Installment(id: $id, customerId: $customerId, productName: $productName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Installment &&
        other.id == id &&
        other.customerId == customerId &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ customerId.hashCode ^ productId.hashCode;
  }
}
