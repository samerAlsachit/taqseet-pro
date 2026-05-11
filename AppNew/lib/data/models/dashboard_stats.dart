class DashboardStats {
  final int totalCustomers;
  final int activeInstallments;
  final Map<String, double> dueToday;
  final Map<String, double> overdue;
  final Map<String, double> todayCollection;

  DashboardStats({
    required this.totalCustomers,
    required this.activeInstallments,
    required this.dueToday,
    required this.overdue,
    required this.todayCollection,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalCustomers: json['total_customers'] ?? 0,
    activeInstallments: json['active_installments'] ?? 0,
    dueToday: _parseCurrencyMap(json['due_today']),
    overdue: _parseCurrencyMap(json['overdue']),
    todayCollection: _parseCurrencyMap(json['today_collection']),
  );

  static Map<String, double> _parseCurrencyMap(dynamic value) {
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    return {};
  }
}
