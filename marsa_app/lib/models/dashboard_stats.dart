class DashboardStats {
  final int totalCustomers;
  final int activeInstallments;
  final Amount todayCollection;
  final Amount dueToday;
  final Amount overdue;

  DashboardStats({
    required this.totalCustomers,
    required this.activeInstallments,
    required this.todayCollection,
    required this.dueToday,
    required this.overdue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalCustomers: json['total_customers'] ?? 0,
    activeInstallments: json['active_installments'] ?? 0,
    todayCollection: Amount.fromJson(json['today_collection']),
    dueToday: Amount.fromJson(json['due_today']),
    overdue: Amount.fromJson(json['overdue']),
  );

  static DashboardStats empty() => DashboardStats(
    totalCustomers: 0, activeInstallments: 0,
    todayCollection: Amount.empty(), dueToday: Amount.empty(), overdue: Amount.empty(),
  );
}

class Amount {
  final double iqd;
  final double usd;

  Amount({required this.iqd, required this.usd});

  factory Amount.fromJson(Map<String, dynamic>? json) => Amount(
    iqd: (json?['IQD'] as num?)?.toDouble() ?? 0,
    usd: (json?['USD'] as num?)?.toDouble() ?? 0,
  );

  factory Amount.empty() => Amount(iqd: 0, usd: 0);
}
