import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import 'api_client.dart';

/// DashboardService - خدمة لوحة التحكم
/// تجلب الإحصائيات والبيانات من الـ API
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiClient _apiClient = ApiClient();
  Dio? _dio;

  /// Initialize the service
  Future<void> init() async {
    _apiClient.init();
    _dio = _apiClient.dio;
    print('✅ DashboardService: Initialized with ApiClient (auto-token)');
  }

  /// جلب إحصائيات لوحة التحكم
  Future<DashboardStats?> fetchDashboardStats() async {
    if (_dio == null) {
      print('❌ DashboardService: Not initialized. Call init() first.');
      return null;
    }

    try {
      print(
        '🔍 DashboardService: Fetching stats from ${AppConfig.API_URL}/dashboard/stats',
      );

      final response = await _dio!.get('/dashboard/stats');

      print('✅ DashboardService: Response received');
      print('   Status: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData['data'];

        if (data != null) {
          return DashboardStats.fromJson(data);
        }
      }

      return null;
    } on DioException catch (e) {
      print('❌ DashboardService DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('   Response: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('❌ DashboardService Error: $e');
      return null;
    }
  }

  /// جلب إجمالي الديون
  Future<double?> fetchTotalDebt() async {
    if (_dio == null) return null;

    try {
      final response = await _dio!.get('/dashboard/total-debt');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (data['total'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      print('❌ DashboardService fetchTotalDebt Error: $e');
      return null;
    }
  }

  /// جلب التحصيل اليومي
  Future<double?> fetchDailyCollection() async {
    if (_dio == null) return null;

    try {
      final response = await _dio!.get('/dashboard/daily-collection');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (data['amount'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      print('❌ DashboardService fetchDailyCollection Error: $e');
      return null;
    }
  }

  /// جلب عدد العملاء المتأخرين
  Future<int?> fetchOverdueCustomersCount() async {
    if (_dio == null) return null;

    try {
      final response = await _dio!.get('/dashboard/overdue-customers');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return (data['count'] as num?)?.toInt();
      }
      return null;
    } catch (e) {
      print('❌ DashboardService fetchOverdueCustomersCount Error: $e');
      return null;
    }
  }
}

/// إحصائيات لوحة التحكم - تتوافق مع استجابة Node.js API
class DashboardStats {
  // بيانات بالدينار العراقي (IQD) - العملة الأساسية
  final double totalDebtIQD; // إجمالي الديون (المستحقة اليوم)
  final double dailyCollectionIQD; // التحصيل اليومي
  final double overdueIQD; // المتأخرات

  // بيانات بالدولار (USD) - إذا كانت متوفرة
  final double? totalDebtUSD;
  final double? dailyCollectionUSD;
  final double? overdueUSD;

  // إحصائيات عامة
  final int totalCustomers; // إجمالي العملاء
  final int activeInstallments; // الأقساط النشطة

  DashboardStats({
    required this.totalDebtIQD,
    required this.dailyCollectionIQD,
    required this.overdueIQD,
    this.totalDebtUSD,
    this.dailyCollectionUSD,
    this.overdueUSD,
    required this.totalCustomers,
    required this.activeInstallments,
  });

  /// إجمالي الديون الكلي (IQD فقط للعرض)
  double get totalDebt =>
      totalDebtIQD + (totalDebtUSD ?? 0) * 1450; // تحويل تقريبي

  /// التحصيل اليومي الكلي
  double get dailyCollection =>
      dailyCollectionIQD + (dailyCollectionUSD ?? 0) * 1450;

  /// عدد العملاء المتأخرين (نستخدم قيمة المتأخرات)
  double get overdueCustomers => overdueIQD + (overdueUSD ?? 0) * 1450;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // API returns data with currency breakdown: { due_today: { IQD, USD }, today_collection: { IQD, USD }, overdue: { IQD, USD } }
    final dueToday = json['due_today'] as Map<String, dynamic>?;
    final todayCollection = json['today_collection'] as Map<String, dynamic>?;
    final overdue = json['overdue'] as Map<String, dynamic>?;

    return DashboardStats(
      totalDebtIQD: _parseDouble(dueToday?['IQD'] ?? 0),
      dailyCollectionIQD: _parseDouble(todayCollection?['IQD'] ?? 0),
      overdueIQD: _parseDouble(overdue?['IQD'] ?? 0),
      totalDebtUSD: _parseDouble(dueToday?['USD']),
      dailyCollectionUSD: _parseDouble(todayCollection?['USD']),
      overdueUSD: _parseDouble(overdue?['USD']),
      totalCustomers: _parseInt(json['total_customers'] ?? 0),
      activeInstallments: _parseInt(json['active_installments'] ?? 0),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  String toString() {
    return 'DashboardStats(totalDebtIQD: $totalDebtIQD, dailyCollectionIQD: $dailyCollectionIQD, totalCustomers: $totalCustomers)';
  }
}
