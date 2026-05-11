class InstallmentModel {
  final String id;
  final String storeId;
  final String customerId;
  final String? customerName;
  final String? productName;
  final double totalPrice;
  final double downPayment;
  final double financedAmount;
  final double remainingAmount;
  final double totalPaid;
  final String currency;
  final String frequency;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final double installmentAmount;
  final int installmentsCount;
  final DateTime createdAt;

  InstallmentModel({
    required this.id,
    required this.storeId,
    required this.customerId,
    this.customerName,
    this.productName,
    required this.totalPrice,
    required this.downPayment,
    required this.financedAmount,
    required this.remainingAmount,
    required this.totalPaid,
    required this.currency,
    required this.frequency,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.installmentAmount,
    required this.installmentsCount,
    required this.createdAt,
  });

  factory InstallmentModel.fromJson(Map<String, dynamic> json) => InstallmentModel(
    id: json['id']?.toString() ?? '',
    storeId: json['store_id']?.toString() ?? '',
    customerId: json['customer_id']?.toString() ?? '',
    customerName: json['customer_name'],
    productName: json['product_name'],
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    downPayment: (json['down_payment'] as num?)?.toDouble() ?? 0,
    financedAmount: (json['financed_amount'] as num?)?.toDouble() ?? 0,
    remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
    totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] ?? 'IQD',
    frequency: json['frequency'] ?? 'monthly',
    status: json['status'] ?? 'active',
    startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
    endDate: DateTime.tryParse(json['end_date'] ?? ''),
    installmentAmount: (json['installment_amount'] as num?)?.toDouble() ?? 0,
    installmentsCount: json['installments_count'] ?? 1,
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}
