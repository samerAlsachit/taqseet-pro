class PlanModel {
  final String id;
  final String name;
  final int durationDays;
  final double priceIqd;
  final int maxCustomers;
  final int maxEmployees;

  PlanModel({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.priceIqd,
    required this.maxCustomers,
    required this.maxEmployees,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
    id: json['id']?.toString() ?? '',
    name: json['name'] ?? '',
    durationDays: json['duration_days'] ?? 0,
    priceIqd: (json['price_iqd'] as num?)?.toDouble() ?? 0,
    maxCustomers: json['max_customers'] ?? 0,
    maxEmployees: json['max_employees'] ?? 0,
  );
}
